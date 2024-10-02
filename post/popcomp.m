function ts = popcomp(fid, ts, stack, roidat, opts, md, pth, recid)

switch fid

    case 'bump'


        for si = 1:numel(opts.mfit)
            dochoose = 1;
            choosecount = 0;
            while dochoose
                choosecount = choosecount + 1;
                [fitin, dochoose] = choose_timeseries(opts.mfit(si).varnms, ts, md.ti, pth.tsuse_nms_prefix.(fid), pth.stack, choosecount, dochoose);  %select indv/depv for fit using input params
                stackcrop = cropstacks(stack, fitin.regionex, md.zstartpos, recid, pth.fldr); %crop stack based on regionex of the depv (stack for plots, not model)
                ts.(fid).(fitin.regionex).(fitin.parsex).(fitin.parsnorm) = bumpcomp(stackcrop, fitin, roidat.(fitin.regionex).(fitin.parsex), opts, md, fitin.regionex, si); %fit bump
            end
        end


    otherwise

        error(sprintf("no function written for feature '" + fid + "'"))

end
