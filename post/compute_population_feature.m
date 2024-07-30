function ts = compute_population_feature(fid, ts, stack, croplim_all, roiinfo, opts, md, pth)

switch fid

    case 'bump'


        for si = 1:numel(opts.fitm)
            dochoose = 1;
            choosecount = 0;
            while dochoose
                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(opts.fitm(si).varnms, ts, md.ti, pth.tsuse_nms_prefix.(fid), pth.stack_analysis, choosecount, dochoose);  %select indv/depv for fit using input params
                stackcrop = crop_stacks(stack, croplim_all.(fitin.regionex), md.zstartpos); %crop stack based on regionex of the depv (stack for plots, not model)
                ts.(fid).(fitin.regionex).(fitin.parsex).(fitin.parsnorm) = compute_bump(stackcrop, fitin, roiinfo.(fitin.regionex).(fitin.parsex), opts, md, fitin.regionex, si); %fit bump
            end
        end


    otherwise

        error(sprintf("no function written for feature '" + fid + "'"))

end
