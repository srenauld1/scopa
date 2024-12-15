function respout = respnorm(respin, normtype_all, sampper)

% several normalization methods, input respin is 2d space x time, single or double precision
% normtype_all is cell array of strings, each string specifies a different
% normalization method, which is applied independently to each roi's timeseries (or pixel's timeseries)
% each normalization string is comprised of 'syllables', which can be concatenated in any order for sequential normalization operations
% syllables are applied in order from left to right
% normalized responses are saved in struct 'resp' to a field whose name matches the normalization string used to produce them
% below, xxx, yyy, zzz, and www, are 3-character strings converted to integers, range 0-100 (ie use leading zeros to reach 3 characters for anything under 100)
% valid normalization syllables are:
% 'f' : no normalization
% 'dffuuuvvv' : df/f with or without sliding window, uuu as percentile to compute f0 for each window, vvv as sliding window length in seconds, if vvv is 000 then f0 is computed across the entire timeseries (not a sliding window)
% 'rscxxxyyy' : rescale, sending xxx percentile to 0, yyy percentile to 1,
% 'z' : zscore
% 'nn' : nonnegative (subtract min)
% 'box' : box-cox transformation
% for example

if ~iscell(normtype_all)
    normtype_all = {normtype_all};
end

for nti = 1:length(normtype_all)

    normtype = normtype_all{nti};
    tmp = respin;

    while normtype

        matchind = []; %reset on each loop

        if isempty(matchind)
            pat = '^f'; %starts with 'f', this does nothing
            matchind = regexp(normtype, pat);
            if ~isempty(matchind)
                patlen = length(erase(pat, {'\', '^'}));
                patmatch = normtype(matchind:matchind+patlen-1);
            end
        end

        if isempty(matchind)
            pat = '^dff\d\d\d\d\d\d'; %starts with 'dff' followed by 6 digits
            matchind = regexp(normtype, pat);
            if ~isempty(matchind)
                patlen = length(erase(pat, {'\', '^'}));
                patmatch = normtype(matchind:matchind+patlen-1);
                f0_pct = sscanf(patmatch(4:6), '%d');
                winlen = sscanf(patmatch(7:9), '%d');
                if winlen
                    if isempty(sampper)
                        error("sampper (sample period) must not be empty if using a dff window")
                    end
                    winlen = round(winlen / sampper);
                    f0 = RankOrderFilter(tmp, winlen, f0_pct); %moving baseline
                else
                    f0 = prctile(tmp, f0_pct, 2); %static baseline
                end
                tmp = (tmp - f0) ./ f0; %df/f
            end
        end

        if isempty(matchind)
            pat = '^rsc\d\d\d\d\d\d'; %starts with 'rsc' followed by 6 digits
            matchind = regexp(normtype, pat);
            if ~isempty(matchind)
                patlen = length(erase(pat, {'\', '^'}));
                patmatch = normtype(matchind:matchind+patlen-1);
                botprct = sscanf(patmatch(4:6), '%d');
                topprct = sscanf(patmatch(7:9), '%d');
                lbnd = prctile(tmp, botprct, 2);
                ubnd = prctile(tmp, topprct, 2);
                tmp = (tmp-lbnd)./(ubnd-lbnd); %rescaling to specified percentiles
            end
        end

        if isempty(matchind)
            pat = '^z'; %starts with 'z'
            matchind = regexp(normtype, pat);
            if ~isempty(matchind)
                patlen = length(erase(pat, {'\', '^'}));
                patmatch = normtype(matchind:matchind+patlen-1);
                tmp = zscore(tmp, 1, 2); %2nd arg is 1 to use population not sample
            end
        end

        if isempty(matchind)
            pat = '^nn'; %starts with 'nn'
            matchind = regexp(normtype, pat);
            if ~isempty(matchind)
                patlen = length(erase(pat, {'\', '^'}));
                patmatch = normtype(matchind:matchind+patlen-1);
                tmp = tmp - min(tmp, [], 2) + 1; %nonnegative
            end
        end

        if isempty(matchind)
            pat = '^box'; %starts with 'box'
            matchind = regexp(normtype, pat);
            if ~isempty(matchind)
                patlen = length(erase(pat, {'\', '^'}));
                patmatch = normtype(matchind:matchind+patlen-1);
                tmp2 = tmp - min(tmp, [], 2) + 1; %boxcox input must be nonnegative
                tmp = zeros(size(tmp), 'single'); %nan(size(tmp))
                for i = 1:size(tmp, 1)
                    [tmp(i,:), ~] = boxcox(tmp2(i,:)');
                end
            end
        end

        if matchind %if there was a match above
            normtype = erase(normtype, patmatch); %remove patmatch, continue loop until normtype is empty
        else
            error("there is an invalid normalization syllable")
        end

    end

    respout.(normtype_all{nti}) = tmp;

end

