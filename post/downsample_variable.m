function outp =downsample_variable(md, inp, iscircular)

breakout = 0;

dsfac = length(md.ti) / length(md.tb);
[dsnr, dsdr] = rat(dsfac);

if iscircular

    stimx = cos(inp);
    stimy = sin(inp);

    stimx_try = resample(stimx, dsnr, dsdr);
    if length(stimx_try)==length(md.ti)
        stimx = stimx_try;
    else
        for upfac = 2:4
            for tryadd = -3 : 3
                stimx_try = resample(stimx, upfac*dsnr, upfac*dsdr+tryadd);
                if length(stimx_try)==length(md.ti)
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
    if length(outp)~=length(md.ti)
        error
    end

else

    inp_try = resample(inp, dsnr, dsdr);
    if length(inp_try)==length(md.ti)
        outp = inp_try;
    else
        for upfac = 2:4
            for tryadd = -3 : 3
                inp_try = resample(inp, upfac*dsnr, upfac*dsdr+tryadd);
                if length(inp_try)==length(md.ti)
                    outp = inp_try;
                    breakout = 1;
                    break
                end
            end
            if breakout
                break
            end
        end
    end
    if length(outp)~=length(md.ti)
        error
    end

end


