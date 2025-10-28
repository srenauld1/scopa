function vecout = vecrs(vtype, vecin, rskey)

%{

resample vector using matlab function resample (scalar rskey), or user-specified resampling indices (nonscalar rskey)
    if rskey is scalar, rskey is length of resampled vector 
    if rskey is nonscalar, must be vector of integers, same length as vecin
        for example; [0 1 1 0 2 2] and [1 1 0 2 2] are valid, but [0 1 1 0 3 3] is not; 
        rskey = [0 1 1 0 2 2] would output a 2-element vecout from a 6-element vecin, where vecout(1) = f(vecin(2:3)) and vecout(2) = f(vecin(5:6)), and f is a function that depends on vtype   
input vector can be angular (radians or degrees) or categorical or "normal"; 
vecin and vecout orientations are matched
todo: generalize for nd

%}

arguments
    vtype char {mustBeMember(vtype, {'n', 'r', 'd', 'c'})}  % 'r' radians, 'd' degrees, 'c' categorical (not necessarily categorical, just means it uses nearest interp, so output contains only input values), 'n' everything else
    vecin {mustBeNonscalarVector} %vector to be resampled; if vtype is r or d, must be circular data in radians or degrees, respectively
    rskey (:,1) single {mustBeNonnegative, mustBeFinite, mustBeVector, mustBeNonempty} % rskey means resampling key; if scalar number, rskey is the new length of resampled timeseries, resampled with matlab 'resample' function (padded to avoid start/end transients); if numeric vector, rskey is indices for resampling, and rskey and vecin must be equal in length (see docs above for more detail)
end

wasrow = 0;
if isrow(vecin)
    wasrow = 1;
    vecin = vecin';
end


if ~isscalar(rskey)   %if rskey is not scalar, average vecin during each index of rskey

    if ~isequal(numel(rskey), numel(vecin))
        error("numel(rskey) must equal numel(vecin)")
    end

    rskeydiff = [0; logical(diff(rskey))]; 
    segstart = find(rskeydiff>0);  %start index in vecin for each resampling time bin
    segend = segstart(rskey(segstart)==0)-1; %end index in vecin for each resampling time bin
    segstart(rskey(segstart)==0) = [];
    segend = sort([segend; segstart-1]); 
    segend(rskey(segend)==0) = [];
    if rskey(1)>0
        segstart = [1; segstart];
    end
    if rskey(end)>0
        segend = [segend; numel(rskey)];
    end
    seglen = zeros(1, numel(segend));
    for k = 1:numel(segend)
        seglen(k) = numel(segstart(k):segend(k)); %length of each segment
    end
    newlen = numel(seglen);
    nanmat = nan(max(seglen), newlen, 'single'); %preallocate nan, so we can take vectorized mean with nan padding that won't affect anything
    if strcmp(vtype, 'c')
        for k = 1:numel(segend)
            nanmat(1:seglen(k), k) = segstart(k):segend(k); %for 'c' variables, nanmat contains indices, not values, for finding index centroid (then nearest neighbor interp onto that centroid)
        end
    else
        for k = 1:numel(segend)
            nanmat(1:seglen(k), k) = vecin(segstart(k):segend(k)); %for all other variables nanmat contains values (for averaging them)
        end
    end


    if strcmp(vtype, 'n')

        vecout = mean(nanmat, 'omitmissing');

    elseif strcmp(vtype, 'r') || strcmp(vtype, 'd')

        if strcmp(vtype, 'd')
            nanmat = deg2rad(nanmat);
        end

        vecout = atan2(mean(sin(nanmat),'omitmissing'), mean(cos(nanmat),'omitmissing'));

    elseif strcmp(vtype, 'c') %takes value nearest centroid of each output sample (alt approach was mode, seems less appropriate)

        cntr = mean(nanmat, 'omitmissing'); %find centroid of each index
        nzi = find(vecin);
        vecout = interp1(nzi, vecin(nzi), cntr, 'nearest', 'extrap'); %use extrap to deal with final query point, which can be greater than greatest nonzero vecin index

    end

else %if rskey is scalar, use 'resample' to resample into rskey-length vector (looping strategy with numupfac and tryrange below is meant to match newlen precisely, if possible)

    numupfac = 3; %number of different upsamplings to try to get output the correct length
    tryrange = 3; %try adding -tryrange:tryrange to numerator and denominator when resampling to get output the correct length

    newlen = rskey;

    dsfac = newlen / numel(vecin);
    [p, q] = rat(dsfac);
    breakout = 0;

    if strcmp(vtype, 'n')

        inp_try = vecrspad(vecin, p, q);
        currlen = numel(inp_try);
        if currlen==newlen
            vecout = inp_try;
        else
            prevmin = Inf;
            for upfac = 1:numupfac
                for tryadd = -tryrange:tryrange
                    for tryadd2 = -tryrange:tryrange

                        p_new = upfac*p+tryadd;
                        if p_new<=0
                            p_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end
                        q_new = upfac*q+tryadd2;
                        if q_new<=0
                            q_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end
                        inp_try = vecrspad(vecin, p_new, q_new);

                        currlen = numel(inp_try);

                        if currlen==newlen
                            vecout = inp_try;
                            breakout = 1;
                            break
                        else
                            if currlen>newlen
                                if currlen-newlen<prevmin
                                    prevmin = currlen-newlen;
                                    p_sv = p_new; %set aside best p/q factors thusfar, in case resample fails to match desired length 
                                    q_sv = q_new; %set aside  best p/q factors thusfar, in case resample fails to match desired length 
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
                inp_try = vecrspad(vecin, p_sv, q_sv);
                vecout = inp_try(1:newlen);
            end
        end

    elseif strcmp(vtype, 'r') || strcmp(vtype, 'd')

        if strcmp(vtype, 'd')
            vecin = deg2rad(vecin);
        end

        inpx = cos(vecin);
        inpy = sin(vecin);

        inpx_try = vecrspad(inpx, p, q);
        currlen = numel(inpx_try);
        if currlen==newlen
            inpx = inpx_try;
        else
            prevmin = Inf;
            for upfac = 1:numupfac
                for tryadd = -tryrange:tryrange
                    for tryadd2 = -tryrange:tryrange

                        p_new = upfac*p+tryadd;
                        if p_new<=0
                            p_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end
                        q_new = upfac*q+tryadd2;
                        if q_new<=0
                            q_new = tryrange-tryadd; %instead of subtracting, try adding more by subtracting the negative from the max
                        end

                        inpx_try = vecrspad(inpx, p_new, q_new);

                        currlen = numel(inpx_try);

                        if currlen==newlen
                            inpx = inpx_try;
                            p = p_new;
                            q = q_new;
                            breakout = 1;
                            break
                        else
                            if currlen>newlen
                                if currlen-newlen<prevmin
                                    prevmin = currlen-newlen;
                                    p_sv = p_new;
                                    q_sv = q_new;
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
            inpy = vecrspad(inpy, p, q);
        else
            fprintf("failed precise resample, using smallest output that is larger than goal length and cropping extra frames" + newline)
            inpx = vecrspad(inpx, p_sv, q_sv);
            inpx = inpx(1:newlen);
            inpy = vecrspad(inpy, p_sv, q_sv);
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

end

if strcmp(vtype, 'd')
    vecout = rad2deg(vecout);
end

if wasrow
    if iscolumn(vecout)
        vecout = vecout';
    end
else
    if isrow(vecout)
        vecout = vecout';
    end
end


end



function vecout = vecrspad(vecin, p, q)

default_antialiasing_filter_order_scalefac = 10; %this is matlab default
default_antialiasing_filter_order = 2*default_antialiasing_filter_order_scalefac*max(q,p); %also matlab default
default_antialiasing_filter_length = default_antialiasing_filter_order+1; %also matlab default
padlength = default_antialiasing_filter_length+1; %make this the pad length to remove edge transients

padfront = repmat(vecin(1), padlength, 1); %make it column
padback = repmat(vecin(end), padlength, 1); %make it column
vecinpad = cat(1, padfront, vecin, padback); % extend by 2s on each side
vecoutpad = resample(vecinpad, p, q); %resample the padded vector
padfrontnew = floor(padlength/q*p+1); %find new length of pad front
padbacknew = floor(padlength/q*p); %and new length of pad back
vecout = vecoutpad(padfrontnew : length(vecoutpad)-padbacknew); %remove new pad front and back

end

