function ts = compute_population_feature(fid, ts, stack, croplim_all, roiinfo, opts, md, pth)

switch fid

    case 'bump'


        for si = 1:numel(opts.fit)
            dofit = 1;
            fitcount = 0;
            while dofit && opts.fit(si).do
                fitcount = fitcount + 1;
                [fitin, dofit] = choose_timeseries(opts.fit(si), ts, md, pth.tsuse.(fid), pth.stack_analysis, fitcount, dofit);  %select indv/depv for fit using input params
                stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex)); %crop stack based on regionex of the depv (stack for plots, not model)
                ts.(fid).(fitin.regionex).(fitin.parsex).(fitin.parsnorm) = compute_bump(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), opts, md, fitin.regionex, si); %fit bump
            end
        end


    otherwise

        error(sprintf("no function written for feature '" + fid + "'"))

end
