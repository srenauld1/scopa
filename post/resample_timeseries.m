function outp = resample_timeseries(iscircular, inp, rslen, method_resample, inds, padlensec)

arguments
    iscircular logical
    inp double
    rslen double
    method_resample char = 'resample'
    inds double = []
    padlensec double = 5 %arbitrary
end

if size(inp,1) < size(inp, 2)
    inp = inp';
end

switch method_resample

    case 'uniform'

        breakout = 0;

        dsfac = rslen / numel(inp);
        [dsnr, dsdr] = rat(dsfac);

        if iscircular

            inpx = cos(inp);
            inpy = sin(inp);

            inpx_try = resample_padded_timeseries(inpx, dsnr, dsdr, padlensec);
            if length(inpx_try)==rslen
                inpx = inpx_try;
            else
                for upfac = 2:4
                    for tryadd = -3 : 3

                        inpx_try = resample_padded_timeseries(inpx, upfac*dsnr, upfac*dsdr+tryadd, padlensec);

                        if length(inpx_try)==rslen
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

            inpy = resample_padded_timeseries(inpy, dsnr, dsdr, padlensec);

            outp = atan2(inpy, inpx);
            if length(outp)~=rslen
                error("failed resample")
            end

        else

            inp_try = resample_padded_timeseries(inp, dsnr, dsdr, padlensec);
            if length(inp_try)==rslen
                outp = inp_try;
            else
                for upfac = 2:4
                    for tryadd = -3 : 3

                        inp_try = resample_padded_timeseries(inp, upfac*dsnr, upfac*dsdr+tryadd, padlensec);

                        if length(inp_try)==rslen
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
            if length(outp)~=rslen
                error("failed resample")
            end

        end


    case 'volumes'

        if iscircular
            Au = unique(inds,'stable'); %index of each volume
            inpcos = cos(inp);
            inpx = arrayfun(@(i)mean(inpcos(inds==Au(i))),1:numel(Au)); %average of inpcos for each volume 
            inpsin = sin(inp);
            inpy = arrayfun(@(i)mean(inpsin(inds==Au(i))),1:numel(Au)); %average of inpsin for each volume
            outp = atan2(inpy, inpx);
        else
            Au = unique(inds,'stable'); %index of each volume
            outp = arrayfun(@(i)mean(inp(inds==Au(i))),1:numel(Au)); %average of inp for each volume
        end


    case 'frames'

        error("work in progress")
        if iscircular
            Au = unique(inds,'stable'); %index of each frame
            inpcos = cos(inp);
            inpx = arrayfun(@(i)mean(inpcos(inds==Au(i))),1:numel(Au)); %average of inpcos for each frame
            inpsin = sin(inp);
            inpy = arrayfun(@(i)mean(inpsin(inds==Au(i))),1:numel(Au)); %average of inpsin for each frame
            outp = atan2(inpy, inpx);
        else
            Au = unique(inds,'stable'); %index of each frame
            outp = arrayfun(@(i)mean(inp(inds==Au(i))),1:numel(Au)); %average of inp for each frame
        end


end

