function tsout = tsrs(vartypein, tsin, inds, newlen)

arguments
    vartypein char %if circular, tsin must be in radians
    tsin double %must be in radians if vartypein is circular 
    inds double = []
    newlen double = []
end

if size(tsin,1) < size(tsin, 2)
    tsin = tsin';
end

if ~isempty(inds) %if inds are nonempty, average tsin during each index

    Au = unique(inds(inds~=0),'stable'); %index of each frame
    if strcmp(vartypein, 'circular')
        fprintf("USER REQUESTED 'circular' vartypein, input must be in radians; assuming that it is and proceeding" + newline)
        inpcos = cos(tsin);
        inpx = arrayfun(@(i)mean(inpcos(inds==Au(i))),1:numel(Au)); %average of inpcos for each frame
        inpsin = sin(tsin);
        inpy = arrayfun(@(i)mean(inpsin(inds==Au(i))),1:numel(Au)); %average of inpsin for each frame
        tsout = atan2(inpy, inpx);
    elseif strcmp(vartypein, 'categorical') %takes value nearest centroid of each frame (alt approach is mode, commented out below, seems less appropriate)
        
        usi = unique(inds(inds~=0),'stable');
        cnt = zeros(numel(usi), 1, 'single');
        for ii = 1:numel(usi) %loop is much faster than using arrayfun
            cnt(ii) = round(mean(find(inds==usi(ii)))); %find center index for each frame
        end
        nzi = find(tsin);
        tsout = interp1(nzi, tsin(nzi), cnt, 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero tsin index

        % tsout = arrayfun(@(i)mode(tsin(inds==Au(i))),1:numel(Au)); 

    elseif strcmp(vartypein, 'normal')
        tsout = arrayfun(@(i)mean(tsin(inds==Au(i))),1:numel(Au)); %average of tsin for each frame
    end

else %else use 'resample', looping strategy to match newlen

    dsfac = newlen / numel(tsin);
    [dsnr, dsdr] = rat(dsfac);
    breakout = 0;

    if strcmp(vartypein, 'circular')

        inpx = cos(tsin);
        inpy = sin(tsin);

        inpx_try = resample_padded_timeseries(inpx, dsnr, dsdr);
        if length(inpx_try)==newlen
            inpx = inpx_try;
        else
            for upfac = 2:4
                for tryadd = -3 : 3

                    inpx_try = resample_padded_timeseries(inpx, upfac*dsnr, upfac*dsdr+tryadd);

                    if length(inpx_try)==newlen
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

        tsout = atan2(inpy, inpx);
        if length(tsout)~=newlen
            error("failed resample")
        end

    elseif strcmp(vartypein, 'normal')

        inp_try = resample_padded_timeseries(tsin, dsnr, dsdr);
        if length(inp_try)==newlen
            tsout = inp_try;
        else
            for upfac = 2:4
                for tryadd = -3 : 3

                    inp_try = resample_padded_timeseries(tsin, upfac*dsnr, upfac*dsdr+tryadd);

                    if length(inp_try)==newlen
                        tsout = inp_try;
                        breakout = 1;
                        break
                    end
                end
                if breakout
                    break
                end
            end
        end
        if length(tsout)~=newlen
            error("failed resample")
        end


    elseif strcmp(vartypein, 'categorical')

        tmp = linspace(1,numel(tsin),newlen+1);
        tmp = tmp(1:end-1);
        mhd = mean(diff(tmp))/2;
        tmp = tmp + mhd;
        tmp = round(tmp); % roughly equidistant centroids 
        nzi = find(tsin); 
        tsout = interp1(nzi, tsin(nzi), tmp', 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero tsin index

    end


end

