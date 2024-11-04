function ts = popcmp(fid, ts, stack, roidat, opts, md, pth, recid)

switch fid

    case 'bump'


        for si = 1:numel(opts.mfit)
            dochoose = 1;
            cnt = 0;
            while dochoose
                cnt = cnt + 1;
                [fitin, dochoose] = tsget(opts.mfit(si).vnm, ts, ts.t, pth.tsuse_nms_prefix.(fid), pth.stack, cnt, dochoose);  %select indv/depv for fit using input params
                stacksub = stackcrop(stack, fitin.regionex, md.zstartpos, recid, pth.fldr); %crop stack based on regionex of the depv (stack for plots, not model)
                ts.(fid).(fitin.regionex).(fitin.parsex).(fitin.parsnorm) = bumpcmp(stacksub, fitin, roidat.(fitin.regionex).(fitin.parsex), opts, md, fitin.regionex, si); %fit bump
            end
        end


    otherwise

        error(sprintf("no function written for feature '" + fid + "'"))

end
