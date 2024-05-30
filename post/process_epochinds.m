function process_epochinds(no_stim_epochs, trialtime, pth_fldr, ids, daqdata_resamp, testepochind_all)

if no_stim_epochs
    epochinds_ts_i = ones(numel(trialtime), 1);
    epochinds.closed = 4;
    testepochind_all = 4;
else
    if ~any(strcmp(daqdata_resamp.Properties.VariableNames, 'epochinds'))

        sprintf("warning, epochinds not saved to daq, using hard coded epochinds aligned by minimizing error")
        minshiftsec = -8;
        maxshiftsec = 3;
        ft_misoffset_sec_all = minshiftsec : md.dtmni*0.45 : maxshiftsec;
        hfg = figure;
        hax = axes('Parent', hfg);
        bestshiftind_allepochs = [];
        figframes = 0;
        for tei = 1:numel(testepochind_all)
            testepochind = testepochind_all(tei);
            criter = nan(numel(ft_misoffset_sec_all), 1);
            for fmsai = 1:numel(ft_misoffset_sec_all)
                figframes = figframes+1;

                ft_misoffset_sec = ft_misoffset_sec_all(fmsai);
                epochinds_ts_i = define_stim_epoch_indices(ft_misoffset_sec, trialtime, ids.datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

                fu = daqdata_resamp.g4panels{1}(epochinds_ts_i==testepochind);
                if testepochind==2 || testepochind==3
                    fu = unwrap(fu); %makes it easier to see
                end
                % fu = cos(fu);
                %fu = diff(diff(fu));
                plot(hax,fu)
                %ylim(hax, [min(daqdata_resamp.g4panels{1}(:)) - abs(min(daqdata_resamp.g4panels{1}(:)))*0.3, max(daqdata_resamp.g4panels{1}(:)) + abs(max(daqdata_resamp.g4panels{1}(:)))*0.3])
                % ylim([-20 20])
                if testepochind==2 || testepochind==3
                    fud2 = diff(diff(fu));
                    criter(fmsai) = numel(find(isoutlier(fud2))); %minimize num unique variables in diff, since open look should have only a couple (constant vel)
                elseif testepochind==5
                    criter(fmsai) = var(cos(fu)); %minimize variance of x (or y) component of circular variable, this is offset with least error
                end
                title([criter(fmsai) ft_misoffset_sec ft_misoffset_sec])
                fig2gif(hfg, figframes, [pth_fldr 'misoffset_.gif'])

                if fmsai==numel(ft_misoffset_sec_all)
                    critd = movingslope(criter, 20, 2, md.dtmni);
                    if ~(min(critd)<0 && max(critd)>0)
                        error("error is monotonic, expand search range")
                    end
                    [~, bestshiftind_oneepoch] = min(criter);
                    bestshiftind_allepochs = [bestshiftind_allepochs bestshiftind_oneepoch];
                end
            end
        end

        ft_misoffset_sec = mean(ft_misoffset_sec_all(bestshiftind_allepochs));
        [epochinds_ts_i, epochinds] = define_stim_epoch_indices(ft_misoffset_sec, trialtime, ids.datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

    end
end