function outp = resample_timeseries(inp, dslen, method_resample, iscircular, inds)

arguments 
    inp double
    dslen double
    method_resample string = 'resample'
    iscircular logical = 0
    inds double = []
end

switch method_resample

    case 'resample'

        breakout = 0;

        dsfac = dslen / numel(inp);
        [dsnr, dsdr] = rat(dsfac);

        if iscircular

            inpx = cos(inp);
            inpy = sin(inp);

            inpx_try = resample(inpx, dsnr, dsdr);
            if length(inpx_try)==dslen
                inpx = inpx_try;
            else
                for upfac = 2:4
                    for tryadd = -3 : 3
                        inpx_try = resample(inpx, upfac*dsnr, upfac*dsdr+tryadd);
                        if length(inpx_try)==dslen
                            inpx = inpx_try;
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
            inpy = resample(inpy, dsnr, dsdr);
            outp = atan2(inpy, inpx);
            if length(outp)~=dslen
                error
            end

        else

            inp_try = resample(inp, dsnr, dsdr);
            if length(inp_try)==dslen
                outp = inp_try;
            else
                for upfac = 2:4
                    for tryadd = -3 : 3
                        inp_try = resample(inp, upfac*dsnr, upfac*dsdr+tryadd);
                        if length(inp_try)==dslen
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
            if length(outp)~=dslen
                error
            end

        end


    case 'timestamps' 

        if dslen > numel(inp)
            error("'timestamps' method for downsampling, not upsampling (to upsample use analogous approach but interp not mean")
        end
        if iscircular
            Au = unique(inds,'stable'); %index of each frame
            inpcos = cos(inp);
            inpx = arrayfun(@(i)mean(inpcos(inds==Au(i))),1:numel(Au)); %average of inp for each frame of B
            inpsin = sin(inp);
            inpy = arrayfun(@(i)mean(inpsin(inds==Au(i))),1:numel(Au)); %average of inp for each frame of B
            outp = atan2(inpy, inpx);
        else
            Au = unique(inds,'stable'); %index of each frame
            outp = arrayfun(@(i)mean(inp(inds==Au(i))),1:numel(Au)); %average of inp for each sample of B
        end


end

