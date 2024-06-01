function epochs = process_epochinds(trialtime, pth_fldr, ids, dtmni, daqdata_resamp, use_carls_epochs)


if any(strcmp(daqdata_resamp.Properties.VariableNames, 'epochs'))

    error("write function to process epochs from daq")

else

    sprintf("warning, epochs not saved to daq, using hard coded epochs aligned by minimizing error")

    if use_carls_epochs
        if ids.datenum<20231119
            testepochind_all = [2 3];
            minshiftsec = -8;
            maxshiftsec = 3;
        elseif ids.datenum>=20231119 && ids.datenum<20231231
            testepochind_all = [2 3 5];
            minshiftsec = -8;
            maxshiftsec = 3;
        else
            testepochind_all = [];
            minshiftsec = 0;
            maxshiftsec = 0;
        end
    end


    ft_misoffset_sec_all = minshiftsec : dtmni*0.45 : maxshiftsec;

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
            epochs = define_stim_epoch_indices(ft_misoffset_sec, trialtime, ids.datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

            fu = daqdata_resamp.g4panels{1}(epochs.epochinds_ts_i==testepochind);
            if testepochind==2 || testepochind==3
                fu = unwrap(fu); %makes it easier to see
            end

            if testepochind==2 || testepochind==3
                criter(fmsai) = numel(find(isoutlier(diff(diff(fu))))); %minimize num unique variables in diff, since open look should have only a couple (constant vel)
            elseif testepochind==5
                criter(fmsai) = var(cos(fu)); %minimize variance of x (or y) component of circular variable, this is offset with least error
            end

            plot(hax,fu)
            %ylim(hax, [min(daqdata_resamp.g4panels{1}(:)) - abs(min(daqdata_resamp.g4panels{1}(:)))*0.3, max(daqdata_resamp.g4panels{1}(:)) + abs(max(daqdata_resamp.g4panels{1}(:)))*0.3])

            title([criter(fmsai) ft_misoffset_sec ft_misoffset_sec])
            fig2gif(hfg, figframes, [pth_fldr 'misoffset_.gif'])

            if fmsai==numel(ft_misoffset_sec_all)
                critd = movingslope(criter, 20, 2, dtmni);
                if ~(min(critd)<0 && max(critd)>0)
                    error("error is monotonic, expand search range")
                end
                [~, bestshiftind_oneepoch] = min(criter);
                bestshiftind_allepochs = [bestshiftind_allepochs bestshiftind_oneepoch];
            end
        end
    end

    ft_misoffset_sec = mean(ft_misoffset_sec_all(bestshiftind_allepochs));
    epochs = define_stim_epoch_indices(ft_misoffset_sec, trialtime, ids.datenum); %%%%%% DEFINE STIM EPOCH INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%


    figframes = 0;
    hfg = figure;
    hax = axes('Parent', hfg);
    for tei = 1:numel(testepochind_all)
        figframes = figframes+1;
        plot(hax, daqdata_resamp.g4panels{1}(epochs.epochinds_ts_i==testepochind_all(tei)))
        title(['final offset'])
        fig2gif(hfg, figframes, [pth_fldr 'misoffset_final.gif'])
    end

end


if isfield(epochs, 'dark') || isfield(epochs, 'closedfinaldark')
    epochs.naninds_i = epochinds_ts_i==epochs.dark | epochinds_ts_i==epochs.closedfinaldark; %dark gets nans
else
    epochs.naninds_i = [];
end
