function [epochs, eidstr, eidnum] = epochidget(expid, eid)

arguments
    expid % experiment ID (maps to different epoch sets)
    eid = [] % scalar/vector of numeric or string id(s) for epoch(s); will output corresponding string or numeric id(s), respectively 
end

% get epoch ids; optionally get numeric or string code for input stimulus epochs

switch expid
    case 'ocld'
        epochs.closedinitiallight = 1;
        epochs.openslow = 2;
        epochs.openfast = 3;
        epochs.closedinterleave = 4;
        epochs.dark = 5;
        epochs.closedfinaldark = 6;
    case 'ocld2'
        epochs.slowpos = 1;
        epochs.fastpos = 2;
        epochs.slowneg = 3;
        epochs.fastneg = 4;
        epochs.dark = 5;
        epochs.closedinterleave = 6;
    case 'cl'
        epochs.closed = 1;
end

if ~isnumeric(eid)
    if ~iscell(eid)
        eid = {eid};
    end
end

fns = fieldnames(epochs);
numepochs = numel(fns);

if isempty(eid)
    eid = 1:numepochs;
end

if iscellstr(eid) || isstring(eid)
    eidstr = eid;
    for k = 1:numel(eid)
        eidnum(k) = epochs.(eid{k});
    end
else
    eidnum = eid;
    for k = 1:numel(eid)
        idx = find(structfun(@(x) x==eid(k),epochs));
        eidstr{k} = fns{idx};
    end
end


