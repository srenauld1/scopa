function [respout] = normalize_response(respin, response_normalization_string, fieldnameprefix, f0_pct)

%several normalization methods, input respin is 2d single or double, space x time

respout.f = respin;

if any(strcmp(response_normalization_string, 'rescale0100'))
    rowmin = min(respin, [], 2);
    rowmax = max(respin, [], 2);
    respout.rsc = rescale(respin, "InputMin", rowmin, "InputMax", rowmax); %allows to rescale by row
end

if any(strcmp(response_normalization_string, 'rescale595'))
    topprct = 95;
    botprct = 5;
    pfn1 = prctile(respin, topprct, 2);
    pfn2 = prctile(respin, botprct, 2);
    respout.f595 = (respin-pfn1)./(pfn2-pfn1); %arbitrary rescaling to specified percentiles
end

if any(strcmp(response_normalization_string, 'zscore'))
    respout.fz = zscore(respin,1,2); %2nd arg is 1 to use population not sample
end

if any(strcmp(response_normalization_string, 'dffmov'))
    f0_moving = RankOrderFilter(respin, window_f0, f0_pct);
    respout.dffmov = (respin - f0_moving) ./ f0_moving; %find the dF/F in each cluster
end

if any(ismember(response_normalization_string, {'dff', 'dffzscore', 'dff595'}))

    f0 = prctile(respin, f0_pct, 2); %static baseline
    respout.dff = (respin - f0) ./ f0; %df/f

    if any(strcmp(response_normalization_string, 'dffzscore'))
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

if any(ismember(response_normalization_string, {'nonnegative', 'boxcox'}))

    respout.fnn = respin - min(respin, [], 2) + 1; %nonnegative

    if any(strcmp(response_normalization_string, 'boxcox'))
        respout.fnnbox = zeros(size(respout.fnn), 'single');
        respout.fnnbox = nan(size(respout.fnn));
        for i = 1:size(respin, 1)
            [respout.fnnbox(i,:), ~] = boxcox(respout.fnn(i,:)'); %boxcox input must be nonnegative
        end
    end

    if ~any(strcmp(response_normalization_string, 'nonnegative'))
        respout = rmfield(respout, 'fnn');
    end

end

% 
% fn1 = fieldnames(respout);
% for fn1i = 1:length(fn1)
%     fieldnamenew = [fieldnameprefix '_' fn1{fn1i}];
%     respout.(fieldnamenew) = respout.(fn1{fn1i});
%     respout = rmfield(respout, fn1{fn1i});
% end
