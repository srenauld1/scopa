function [respout] = normalize_response(respin, response_normalization_string)

%several normalization methods, input respin is 2d space x time, single or double precision

if any(strcmp(response_normalization_string, 'f'))
    respout.f = respin; %f is no normalization
end

if any(strcmp(response_normalization_string, 'rsc'))
    rowmin = min(respin, [], 2);
    rowmax = max(respin, [], 2);
    respout.rsc = rescale(respin, "InputMin", rowmin, "InputMax", rowmax); %allows to rescale by row
end

if any(strcmp(response_normalization_string, 'rsc595'))
    topprct = 95;
    botprct = 5;
    pfn1 = prctile(respin, topprct, 2);
    pfn2 = prctile(respin, botprct, 2);
    respout.rsc595 = (respin-pfn1)./(pfn2-pfn1); %arbitrary rescaling to specified percentiles
end

if any(strcmp(response_normalization_string, 'fz'))
    respout.fz = zscore(respin,1,2); %2nd arg is 1 to use population not sample
end


if any(ismember(response_normalization_string, {'dff', 'dffz', 'dff595'}))

    f0 = prctile(respin, f0_pct, 2); %static baseline
    respout.dff = (respin - f0) ./ f0; %df/f

    if any(strcmp(response_normalization_string, 'dffz'))
        respout.dffz = zscore(respout.dff,1,2); %2nd arg is 1 to use population not sample,
    end

    if any(strcmp(response_normalization_string, 'dff595'))
        topprct = 95;
        botprct = 5;
        pfn1 = prctile(respout.dff, topprct, 2);
        pfn2 = prctile(respout.dff, botprct, 2);
        respout.dff955 = (respout.dff-pfn1)./(pfn2-pfn1);
    end

    if ~any(strcmp(response_normalization_string, 'dff'))
        respout = rmfield(respout, 'dff');
    end

end



if any(ismember(response_normalization_string, {'dffmv', 'dffmvz', 'dffmv595'}))

    f0_pct = 1;
    window_f0_sec = 1;
    f0_moving = RankOrderFilter(respin, window_f0_sec, f0_pct);
    respout.dffmv = (respin - f0_moving) ./ f0_moving; %find the dF/F in each cluster

    if any(strcmp(response_normalization_string, 'dffmvz'))
        respout.dffz = zscore(respout.dffmv,1,2); %2nd arg is 1 to use population not sample,
    end

    if any(strcmp(response_normalization_string, 'dffmv595'))
        topprct = 95;
        botprct = 5;
        pfn1 = prctile(respout.dffmv, topprct, 2);
        pfn2 = prctile(respout.dffmv, botprct, 2);
        respout.dffmv595 = (respout.dffmv-pfn1)./(pfn2-pfn1);
    end

    if ~any(strcmp(response_normalization_string, 'dffmv'))
        respout = rmfield(respout, 'dffmv');
    end

end


if any(ismember(response_normalization_string, {'nn', 'box'}))

    respout.nn = respin - min(respin, [], 2) + 1; %nonnegative

    if any(strcmp(response_normalization_string, 'box'))
        respout.box = zeros(size(respout.nn), 'single');
        respout.box = nan(size(respout.nn));
        for i = 1:size(respin, 1)
            [respout.box(i,:), ~] = boxcox(respout.nn(i,:)'); %boxcox input must be nonnegative
        end
    end

    if ~any(strcmp(response_normalization_string, 'nn'))
        respout = rmfield(respout, 'nn');
    end

end
