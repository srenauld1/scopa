function [epochs, epochinds, vis] = epochld(t, pth_epochinfo, vis, dirstack, ids, sampper, daqrs, use_carls_epochs)

% if it was created/saved during experiment, load 'epochs' (struct containing info about stimulus state during trial, including field epochinds, a vector representing stimulus state for each sample of trial)
% if it doesn't exist, create it here, using hacks to align daq info with known epoch structure (alignment includes finding samples at the start where fictrac ran before imaging)

try

    load(pth_epochinfo, 'epochs', 'epochinds', 'naninds')
    if ~exist('epochinds', 'var')
        error('pth_epochinfo is old, overwriting with new method')
    end

catch

    if size(t, 1)<size(t, 2)
        t = t';
    end

    if any(strcmp(daqrs.Properties.VariableNames, 'epochs'))

        error("write function to process epochs from daq")

    else

        sprintf("warning, epochs not saved to daq, using hard coded epochs aligned by minimizing error")

        if use_carls_epochs
            if ids.recdatenum<20231119
                testepochind_all = [2 3];
                minshiftsec = -8;
                maxshiftsec = 3;
            elseif ids.recdatenum>=20231119 && ids.recdatenum<20231231
                testepochind_all = [2 3 5];
                minshiftsec = -8;
                maxshiftsec = 3;
            elseif ids.recdatenum>=20241120%% && ids.recdatenum<20241130
                testepochind_all = [2 3 5];
                minshiftsec = -15;
                maxshiftsec = -5;
            else
                testepochind_all = [];
                minshiftsec = 0;
                maxshiftsec = 0;
            end
        else
            testepochind_all = [];
            minshiftsec = 0;
            maxshiftsec = 0;
        end

        ft_misoffset_sec_all = minshiftsec : sampper*0.45 : maxshiftsec;

        hfg = figure;
        hax = axes('Parent', hfg);

        bestshiftind_allepochs = [];
        cnt = 0;
        for tei = 1:numel(testepochind_all)
            testepochind = testepochind_all(tei);
            criter = nan(numel(ft_misoffset_sec_all), 1);
            for fmsai = 1:numel(ft_misoffset_sec_all)
                cnt = cnt+1;

                ft_misoffset_sec = ft_misoffset_sec_all(fmsai);
                [~, epochinds] = epochset(ft_misoffset_sec, t, ids.recdatenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

                tmp = daqrs.g4panels{1}(epochinds==testepochind);
                if testepochind==2 || testepochind==3
                    tmp = unwrap(tmp); %makes it easier to see
                end

                if testepochind==2 || testepochind==3
                    criter(fmsai) = numel(find(isoutlier(diff(diff(tmp))))); %minimize num unique variables in diff, since open look should have only a couple (constant vel)
                elseif testepochind==5
                    criter(fmsai) = var(cos(tmp)); %minimize variance of x (or y) component of circular variable, this is offset with least error
                end

                ttlstr = [criter(fmsai) ft_misoffset_sec ft_misoffset_sec];

                if fmsai==1
                    hpl = plot(hax,tmp);
                    ttl = title(ttlstr);
                else
                    hpl.YData = tmp;
                    ttl.String = ttlstr;
                end

                fig2gif(hfg, cnt, [dirstack 'misoffset_.gif'])

                if fmsai==numel(ft_misoffset_sec_all)
                    critd = movingslope(criter, 20, 2, sampper);
                    if ~(min(critd)<0 && max(critd)>0)
                        error("error is monotonic, expand search range")
                    end
                    [~, bestshiftind_oneepoch] = min(criter);
                    bestshiftind_allepochs = [bestshiftind_allepochs bestshiftind_oneepoch];
                end
            end
        end

        if ft_misoffset_sec_all==0
            ft_misoffset_sec = 0;
        else
            ft_misoffset_sec = mean(ft_misoffset_sec_all(bestshiftind_allepochs));
        end

        [epochs, epochinds] = epochset(ft_misoffset_sec, t, ids.recdatenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%


        uei = unique(epochinds(epochinds~=0), 'stable');
        cnt = 0;
        hfg = figure;
        hax = axes('Parent', hfg);
        for tei = 1:numel(uei)
            cnt = cnt+1;
            plot(hax, daqrs.g4panels{1}(epochinds==uei(tei)))
            title(['final offset, epoch ' num2str(uei(tei))])
            fig2gif(hfg, cnt, [dirstack 'offset_final.gif'])
        end

    end


    if any(epochinds==epochs.dark) || any(epochinds==epochs.closedfinaldark)
        naninds = epochinds==epochs.dark | epochinds==epochs.closedfinaldark; %dark gets nans
    else
        naninds = [];
    end


    save(pth_epochinfo, 'epochs', 'epochinds', 'naninds');

end


vis.yaw(naninds) = nan; %put nans where the cue doesn't exist (dark epoch)
vis.yawvel(naninds) = nan; %put nans where the cue doesn't exist (dark epoch)


