function vecout = vecrs(vtype, vecin, rskey)

%{

resample vector using matlab function resample, or user-specified resampling indices
input vector can be angular (radians or degrees) or categorical or "normal"; 
vecin and vecout orientations are matched
todo: generalize for nd

%}

arguments
    vtype char {mustBeTextScalar, mustBeMember(vtype, {'n', 'r', 'd', 'c'})}  % 'r' radians, 'd' degrees, 'c' categorical (not necessarily categorical, just means it uses nearest interp, so output contains only input values), 'n' everything else
    vecin {mustBeVector} %vector to be resampled; if vtype is r or d, must be circular data in radians or degrees, respectively
    rskey {mustBeVector, mustBeA(rskey, {'numeric', 'cell'})} % rskey means resampling key; if scalar number, new length of resampled timeseries, resampled with matlab 'resample' function (padded to avoid start/end transients; if numeric vector, indices for resampling, where rskey index maps to vecin index, and rskey value maps to vecout index; if cell, each element is an index in vecout, and each element contains linear indices of vecin; if numeric vector or cell, will resample using interp1, where method depends on vtype)
end

wasrow = 0;
if isrow(vecin)
    wasrow = 1;
    vecin = vecin';
end


numupfac = 3; %number of different upsamplings to try to get output the correct length
tryrange = 3; %try adding -tryrange:tryrange to numerator and denominator when resampling to get output the correct length  

if isscalar(rskey) && isnumeric(rskey) %if rskey are empty, use 'resample', looping strategy to match newlen precisely, if possible

    newlen = rskey;

    dsfac = newlen / numel(vecin);
    [dsnr, dsdr] = rat(dsfac);
    breakout = 0;

    if strcmp(vtype, 'n')

        inp_try = vecrspad(vecin, dsnr, dsdr);
        currlen = numel(inp_try);
        if currlen==newlen
            vecout = inp_try;
        else
            prevmin = Inf;
            for upfac = 1:numupfac
                for tryadd = -tryrange:tryrange
                    for tryadd2 = -tryrange:tryrange

                        dsnr_new = upfac*dsnr+tryadd;
                        if dsnr_new<=0
                            dsnr_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end
                        dsdr_new = upfac*dsdr+tryadd2;
                        if dsdr_new<=0
                            dsdr_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end
                        inp_try = vecrspad(vecin, dsnr_new, dsdr_new);

                        currlen = numel(inp_try);

                        if currlen==newlen
                            vecout = inp_try;
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
                inp_try = vecrspad(vecin, dsnr_sv, dsdr_sv);
                vecout = inp_try(1:newlen);
            end
        end

    elseif strcmp(vtype, 'r') || strcmp(vtype, 'd')

        if strcmp(vtype, 'd')
            vecin = deg2rad(vecin);
        end

        inpx = cos(vecin);
        inpy = sin(vecin);

        inpx_try = vecrspad(inpx, dsnr, dsdr);
        currlen = numel(inpx_try);
        if currlen==newlen
            inpx = inpx_try;
        else
            prevmin = Inf;
            for upfac = 1:numupfac
                for tryadd = -tryrange:tryrange
                    for tryadd2 = -tryrange:tryrange

                        dsnr_new = upfac*dsnr+tryadd;
                        if dsnr_new<=0
                            dsnr_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end
                        dsdr_new = upfac*dsdr+tryadd2;
                        if dsdr_new<=0
                            dsdr_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end

                        inpx_try = vecrspad(inpx, dsnr_new, dsdr_new);

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
            inpy = vecrspad(inpy, dsnr, dsdr);
        else
            fprintf("failed precise resample, using smallest output that is larger than goal length and cropping extra frames" + newline)
            inpx = vecrspad(inpx, dsnr_sv, dsdr_sv);
            inpx = inpx(1:newlen);
            inpy = vecrspad(inpy, dsnr_sv, dsdr_sv);
            inpy = inpy(1:newlen);
        end

        vecout = atan2(inpy, inpx);


    elseif strcmp(vtype, 'c') %would mode be better than nearest for categorical variables?

        tmp = linspace(1,numel(vecin),newlen+1);
        tmp = tmp(1:end-1);
        mhd = mean(diff(tmp))/2;
        tmp = tmp + mhd;
        tmp = round(tmp); % roughly equidistant centroids
        nzi = find(vecin);
        vecout = interp1(nzi, vecin(nzi), tmp', 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero vecin index

    end


else %if rskey is not scalar number, average vecin during each index of rskey

    if isnumeric(rskey)
        riu = unique(rskey(rskey~=0),'stable'); %index of each output sample
        rsinds = cell(numel(riu), 1);
        for k = 1:numel(riu)
            rsinds{riu(k)} = find(rskey==riu(k)); %do this once, before taking mean, etc, since this is the slow part
        end
    elseif iscell(rskey)
        rsinds = rskey;
    end

    nrs = numel(rsinds);

    if strcmp(vtype, 'n')

        vecout = zeros(nrs, 1);
        for k = 1:nrs
            vecout(k) = mean(vecin(rsinds{k})); %this is fast and arrayfun is not faster
        end

    elseif strcmp(vtype, 'r') || strcmp(vtype, 'd')

        if strcmp(vtype, 'd')
            vecin = deg2rad(vecin);
        end

        vecinx = cos(vecin);
        veciny = sin(vecin);

        vecoutx = zeros(nrs, 1);
        vecouty = zeros(nrs, 1);
        for k = 1:nrs
            vecoutx(k) = mean(vecinx(rsinds{k})); %this is fast and arrayfun is not faster
            vecouty(k) = mean(veciny(rsinds{k})); %this is fast and arrayfun is not faster
        end
        vecout = atan2(vecouty, vecoutx);

    elseif strcmp(vtype, 'c') %takes value nearest centroid of each output sample (alt approach was mode, seems less appropriate)

        cntr = zeros(nrs, 1);
        for k = 1:nrs %loop is much faster than using arrayfun
            cntr(k) = round(mean(rsinds{k})); %find center index for each output sample
        end
        nzi = find(vecin);
        vecout = interp1(nzi, vecin(nzi), cntr, 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero vecin index

    end


end

if strcmp(vtype, 'd')
    vecout = rad2deg(vecout);
end

if wasrow
    vecout = vecout';
end


end



function y = vecrspad(x, fs_new, fs_old)

if size(x,1) < size(x, 2)
    x = x';
end

default_antialiasing_filter_order_scalefac = 10; %this is matlab default
default_antialiasing_filter_order = 2*default_antialiasing_filter_order_scalefac*max(fs_old,fs_new);
default_antialiasing_filter_length = default_antialiasing_filter_order+1;
padlength = default_antialiasing_filter_length+1;

padfront = repmat(x(1), padlength, 1); %make it column
padback = repmat(x(end), padlength, 1); %make it column
xpad = cat(1, padfront, x, padback); % extend by 2s on each side
ypad = resample(xpad, fs_new, fs_old);
padfrontnew = floor(padlength/fs_old*fs_new+1);
padbacknew = floor(padlength/fs_old*fs_new);
y = ypad(padfrontnew : length(ypad)-padbacknew);

end

