function outp = downsample_circular_variable(inp, dslen)

breakout = 0;

dsfac = dslen / numel(inp);
[dsnr, dsdr] = rat(dsfac);

stimx = cos(inp);
stimy = sin(inp);

stimx_try = resample(stimx, dsnr, dsdr);
if length(stimx_try)==dslen
    stimx = stimx_try;
else
    for upfac = 2:4
        for tryadd = -3 : 3
            stimx_try = resample(stimx, upfac*dsnr, upfac*dsdr+tryadd);
            if length(stimx_try)==dslen
                stimx = stimx_try;
                dsnr = upfac*dsnr;
                dsdr = upfac*dsdr+tryadd;
                breakout = 1;
                break
            end
        end
        if breakout
            break
        end
    end
end
stimy = resample(stimy, dsnr, dsdr);
outp = atan2(stimy, stimx);
if length(outp)~=dslen
    error
end
