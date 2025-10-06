function [lag, lagi, lagiz, lagn] = lagmake(lagin, t)

%{

given requested lags (input lagin) and vector of timestamps (t), compute/output the following:
    (1) actual lag in seconds (lagout)
    (2) their sample indices (lagi)
    (3) the sample index of zero lag if it exists (lagiz)
    (4) the number of lags (lagn)

%}
arguments
    lagin % ordinary vector of requested/estimated lags in seconds
    t = [] % ordinary vector of timestamps; if empty, will use glb('t') (if that doesn't exist, error)
end

t_glb = glb('t');
if isempty(t)
    if isempty(t_glb)
        error("you must pass in t or set glb('t')")
    else
        t = t_glb;
    end
else
    if ~isempty(t_glb)
        if ~isequal(t, t_glb)
            error("you have set both name-value argument t and glb('t'), but they are not equal")
        end
    end
end

if ~isvector(lagin) || iscell(lagin)
    error("lagin must be an ordinary vector")
end
if ~isempty(t) && ( ~isvector(t) || iscell(t) )
    error("t must be an ordinary vector, or empty")
end

ticumdiff = t - t(1);
if isequal(lagin, 0)
    lagi = 0;
    lag = 0;
else
    ticumdiff = ticumdiff(:); %make sure it's a column vector
    lagin = lagin(:)';  %make sure it's a row vector
    lagsecn = abs(lagin(lagin<0));
    if isempty(lagsecn)
        lagsampn = [];
    else
        [~, lagsampn] = min(abs(ticumdiff-lagsecn));
    end
    lagsecpos = lagin(lagin>=0);
    if isempty(lagsecpos)
        lagsampp = [];
    else
        [~, lagsampp] = min(abs(ticumdiff-lagsecpos));
    end
    if isempty(lagsampn)
        lagi = lagsampp;
    elseif isempty(lagsampp)
        lagi = lagsampn;
    else
        lagi = [-lagsampn, 0, lagsampp];
    end
    lagi = unique(lagi);
    lag = [vec(-ticumdiff(abs(lagi(lagi<0))+1)); vec(ticumdiff(lagi(lagi>=0)+1))];
    lag = unique(lag);
end

lagiz = find(lagi==0);
lagn = numel(lagi);

end