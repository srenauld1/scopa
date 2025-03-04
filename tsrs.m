function tsout = tsrs(vtype, tsin, newlen, inds)

% need to generalize this function for nd

arguments
    vtype {mustBeText} %if circular, tsin must be in radians
    tsin %must be in radians if vtype is circular (but doens't have to be wrapped, so not sure how to assert this other than the fprint warnings below)
    newlen = [] %new length of resampled timeseries
    inds = [] %resampling indices; if empty, resample tsin using resample function, to make tsout length match newlen; if numeric, resample using these indices, if cell, resample using these indices
end


if size(tsin,1) < size(tsin, 2)
    tsin = tsin';
end

if isempty(inds) %if inds are empty, use 'resample', looping strategy to match newlen

    dsfac = newlen / numel(tsin);
    [dsnr, dsdr] = rat(dsfac);
    breakout = 0;

    if strcmp(vtype, 'normal')

        inp_try = tsrspad(tsin, dsnr, dsdr);
        currlen = numel(inp_try);
        if currlen==newlen
            tsout = inp_try;
        else
            prevmin = Inf;
            for upfac = 1:3
                for tryadd = -3:3
                    for tryadd2 = -3:3

                        dsnr_new = upfac*dsnr+tryadd;
                        dsdr_new = upfac*dsdr+tryadd2;
                        inp_try = tsrspad(tsin, dsnr_new, dsdr_new);

                        currlen = numel(inp_try);

                        if currlen==newlen
                            tsout = inp_try;
                            breakout = 1;
                            break
                        else
                            if currlen>newlen
                                if currlen-newlen<prevmin
                                    prevmin = currlen-newlen;
                                    dsnr_sv = dsnr_new;
                                    dsdr_sv = dsdr_new;
                                end
                            end
                        end
                    end
                    if breakout
                        break
                    end
                end
                if breakout
                    break
                end
            end
            if currlen~=newlen
                fprintf("failed precise resample, using smallest output that is larger than goal length and cropping extra frames" + newline)
                inp_try = tsrspad(tsin, dsnr_sv, dsdr_sv);
                tsout = inp_try(1:newlen);
            end
        end

    elseif strcmp(vtype, 'circular')

        inpx = cos(tsin);
        inpy = sin(tsin);

        inpx_try = tsrspad(inpx, dsnr, dsdr);
        currlen = numel(inpx_try);
        if currlen==newlen
            inpx = inpx_try;
        else
            prevmin = Inf;
            for upfac = 1:3
                for tryadd = -3:3
                    for tryadd2 = -3:3

                        dsnr_new = upfac*dsnr+tryadd;
                        dsdr_new = upfac*dsdr+tryadd2;
                        inpx_try = tsrspad(inpx, dsnr_new, dsdr_new);

                        currlen = numel(inpx_try);

                        if currlen==newlen
                            inpx = inpx_try;
                            dsnr = dsnr_new;
                            dsdr = dsdr_new;
                            breakout = 1;
                            break
                        else
                            if currlen>newlen
                                if currlen-newlen<prevmin
                                    prevmin = currlen-newlen;
                                    dsnr_sv = dsnr_new;
                                    dsdr_sv = dsdr_new;
                                end
                            end
                        end
                    end
                    if breakout
                        break
                    end
                end
                if breakout
                    break
                end
            end
        end

        if currlen==newlen
            inpy = tsrspad(inpy, dsnr, dsdr);
        else
            fprintf("failed precise resample, using smallest output that is larger than goal length and cropping extra frames" + newline)
            inpx = tsrspad(inpx, dsnr_sv, dsdr_sv);
            inpx = inpx(1:newlen);
            inpy = tsrspad(inpy, dsnr_sv, dsdr_sv);
            inpy = inpy(1:newlen);
        end

        tsout = atan2(inpy, inpx);



    elseif strcmp(vtype, 'categorical') %would mode be better than nearest for categorical variables?

        tmp = linspace(1,numel(tsin),newlen+1);
        tmp = tmp(1:end-1);
        mhd = mean(diff(tmp))/2;
        tmp = tmp + mhd;
        tmp = round(tmp); % roughly equidistant centroids
        nzi = find(tsin);
        tsout = interp1(nzi, tsin(nzi), tmp', 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero tsin index

    end


else %if inds are nonempty, average tsin during each index of inds


    if isnumeric(inds)
        riu = unique(inds(inds~=0),'stable'); %index of each frame
        inds_tmp = cell(numel(riu), 1);
        for k = 1:numel(riu)
            inds_tmp{k} = find(inds==riu(k)); %do this once, before taking mean, etc, since this is the slow part
        end
    elseif iscell(inds)
        inds_tmp = inds;
    else
        error("inds must be cell by this point")
    end

    nrs = numel(inds_tmp);
    if ~isequal(newlen, nrs)
        error("if using inds to resample, number cells must match newlen")
    end

    if strcmp(vtype, 'normal')

        tsout = zeros(nrs, 1);
        for k = 1:nrs
            tsout(k) = mean(tsin(inds_tmp{k})); %this is fast and arrayfun is not faster
        end

    elseif strcmp(vtype, 'circular')

        fprintf("USER REQUESTED 'circular' vtype, input must be in radians; assuming that it is and proceeding" + newline)

        tsinx = cos(tsin);
        tsiny = sin(tsin);

        tsoutx = zeros(nrs, 1);
        tsouty = zeros(nrs, 1);
        for k = 1:nrs
            tsoutx(k) = mean(tsinx(inds_tmp{k})); %this is fast and arrayfun is not faster
            tsouty(k) = mean(tsiny(inds_tmp{k})); %this is fast and arrayfun is not faster
        end
        tsout = atan2(tsouty, tsoutx);

    elseif strcmp(vtype, 'categorical') %takes value nearest centroid of each frame (alt approach was mode, seems less appropriate)

        cntr = zeros(nrs, 1);
        for k = 1:nrs %loop is much faster than using arrayfun
            cntr(k) = round(mean(inds_tmp{k})); %find center index for each frame
        end
        nzi = find(tsin);
        tsout = interp1(nzi, tsin(nzi), cntr, 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero tsin index

    end


end

