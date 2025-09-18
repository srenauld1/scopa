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
    opt.cumlag = 0 %1 to apply lags cumulatively (each variable is lagged by sum of its lag and all preceding) 
end
dm = opt.dm;
cumlag = opt.cumlag;

if ~isequal(dm, 2)
    error("for now, dm must be 2")
end
if ~isequal(cumlag, 0)
    error("keep cumlag false for now because i think it is incorrectly written")
end

ts = cat(2, ts0, ts);
nt = unique(cellfun(@(x) size(x,2), ts));
if numel(nt)>1
    error("all ts must be equal in size of 2nd dimension (time)")
end
if numel(ts)<2
    error("must have at least 2 timeseries input")
end

for k = 1:numel(ts)-1

    lagtmp = abs(lag{k});
    lagcum = sum(abs(cell2mat(lag(1:k))));

    if lag{k}<=0
        lagi1 = 1+abs(lagtmp):nt;
        if cumlag
            lagi2 = 1:nt-abs(lagcum);
        else
            lagi2 = 1:nt-abs(lagtmp);
        end
    else
        lagi1 = 1:nt-abs(lagtmp);
        if cumlag
            lagi2 = 1+abs(lagcum):nt;
        else
            lagi2 = 1+abs(lagtmp):nt;
        end
    end

    ts(1:end-k) = cellfun(@(x) x(:,lagi1,:), ts(1:end-k), UniformOutput=0);
    ts{k} = ts{k}(:,lagi2,:);

end

