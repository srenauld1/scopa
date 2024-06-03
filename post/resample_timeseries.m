function outp = resample_timeseries(daqvartype, inp, inds, newlength)

arguments
    daqvartype char
    inp double
    inds double = []
    newlength double = []
end

if size(inp,1) < size(inp, 2)
    inp = inp';
end

if ~isempty(inds) %if inds are nonempty, average inp during each index

    Au = unique(inds(inds~=0),'stable'); %index of each frame
    if strcmp(daqvartype, 'circular')
        inpcos = cos(inp);
        inpx = arrayfun(@(i)mean(inpcos(inds==Au(i))),1:numel(Au)); %average of inpcos for each frame
        inpsin = sin(inp);
        inpy = arrayfun(@(i)mean(inpsin(inds==Au(i))),1:numel(Au)); %average of inpsin for each frame
        outp = atan2(inpy, inpx);
    elseif strcmp(daqvartype, 'categorical')
        outp = arrayfun(@(i)mode(inp(inds==Au(i))),1:numel(Au)); %mode of inp for each frame
    elseif strcmp(daqvartype, 'normal')
        outp = arrayfun(@(i)mean(inp(inds==Au(i))),1:numel(Au)); %average of inp for each frame
    end

else %else use 'resample', looping strategy to match newlength

    dsfac = newlength / numel(inp);
    [dsnr, dsdr] = rat(dsfac);
    breakout = 0;

    if strcmp(daqvartype, 'circular')

        inpx = cos(inp);
        inpy = sin(inp);

        inpx_try = resample_padded_timeseries(inpx, dsnr, dsdr);
        if length(inpx_try)==newlength
            inpx = inpx_try;
        else
            for upfac = 2:4
                for tryadd = -3 : 3

                    inpx_try = resample_padded_timeseries(inpx, upfac*dsnr, upfac*dsdr+tryadd);

                    if length(inpx_try)==newlength
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

        inpy = resample_padded_timeseries(inpy, dsnr, dsdr);

        outp = atan2(inpy, inpx);
        if length(outp)~=newlength
            error("failed resample")
        end

    elseif strcmp(daqvartype, 'normal')

        inp_try = resample_padded_timeseries(inp, dsnr, dsdr);
        if length(inp_try)==newlength
            outp = inp_try;
        else
            for upfac = 2:4
                for tryadd = -3 : 3

                    inp_try = resample_padded_timeseries(inp, upfac*dsnr, upfac*dsdr+tryadd);

                    if length(inp_try)==newlength
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
        if length(outp)~=newlength
            error("failed resample")
        end


    elseif strcmp(daqvartype, 'categorical')

        error("when there is no frame clock, and variable is categorical, need to use nearest interp, will insert that soon")

    end


end

