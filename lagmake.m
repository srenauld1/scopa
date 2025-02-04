function [lagsecout, lagsamp, lagzero, numlags] = lagmake(t, lagsec)

ticumdiff = t - t(1);
if isequal(lagsec, 0)
    lagsamp = 0;
    lagsecout = 0;
else
    ticumdiff = ticumdiff(:); %make sure it's a column vector
    lagsec = lagsec(:)';  %make sure it's a row vector
    lagsecn = abs(lagsec(lagsec<0));
    if isempty(lagsecn)
        lagsampn = [];
    else
        [~, lagsampn] = min(abs(ticumdiff-lagsecn));
    end
    lagsecpos = lagsec(lagsec>=0);
    if isempty(lagsecpos)
        lagsampp = [];
    else
        [~, lagsampp] = min(abs(ticumdiff-lagsecpos));
    end
    if isempty(lagsampn)
        lagsamp = lagsampp;
    elseif isempty(lagsampp)
        lagsamp = lagsampn;
    else
        lagsamp = [-lagsampn, 0, lagsampp];
    end
    lagsamp = unique(lagsamp);
    lagsecout = [vec(-ticumdiff(abs(lagsamp(lagsamp<0))+1)); vec(ticumdiff(lagsamp(lagsamp>=0)+1))];
    lagsecout = unique(lagsecout);
end

lagzero = find(lagsamp==0);
numlags = numel(lagsamp);

end