function [ts, lag] = tslag(ts0, ts, lag, opt)

% negative lag shifts preceding variable to the left (earlier in time) along dimension dm, positive lag does the opposite

arguments (Input)
    ts0 %first variable, which doesn't get a lag after it, but does get lagged
end
arguments (Input,Repeating)
    ts %variable to be lagged
    lag %lag applied to preceding ts
end
arguments (Input)
    opt.dm = 2 %lag dimension, must be 2 for now
end
dm = opt.dm;

if ~isequal(dm, 2)
    error("for now, dm must be 2")
end

ts = cat(2, ts0, ts);
lag = cat(2, {[]}, lag); %cat empty to first ts since it isn't lagged directly

nt = unique(cellfun(@(x) size(x,2), ts));
if numel(nt)>1
    error("all ts must be equal in size of 2nd dimension (time)")
end
if numel(ts)<2
    error("must have at least 2 timeseries input")
end

for kcurr = 2:numel(ts)

    kothers = setdiff(1:numel(ts), kcurr); %all ts indices except the current (k)
    lagtmp = abs(lag{kcurr});

    if lag{kcurr}<=0
        lagi_others = 1+abs(lagtmp):nt;
        lagi_curr = 1:nt-abs(lagtmp);
    else
        lagi_others = 1:nt-abs(lagtmp);
        lagi_curr = 1+abs(lagtmp):nt;
    end

    ts(kothers) = cellfun(@(x) x(:,lagi_others,:), ts(kothers), UniformOutput=0);
    ts{kcurr} = ts{kcurr}(:,lagi_curr,:);
    
    nt = unique(cellfun(@(x) size(x,2), ts)); %update nt after each lag
    if numel(nt)>1
        error("all ts must be equal in size of 2nd dimension (time)")
    end

end

