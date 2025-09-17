function [tr,i,ip,t,tp] = trmake(epochts, opt)

%make struct tr, which holds epoch and bout indices for a trial, and optional corresponding timestamps, with optional padding around each bout
%optionally also output fields of struct tr as separate vectors, but for a single epoch-bout pair specified with name-value argument 'eb'  
%epochs must be one-indexed (zeros in epochts are treated as not belonging to any epoch)
%each field of tr is a {k,q} cell, where k is epoch (not epoch index) and q is bout (ie if epochts has only epochs 2 and 3) first row of all output cells will be empty  

arguments
    epochts %vector of epoch indices for each sample
    opt.eb = [] %if nonempty, epoch and bout to output separately from tr
    opt.t = [] %vector of timestamps for each sample
    opt.padlen = 0 %if scalar, number of samples to include on either side of each bout; if length-2 vector, number samples before and after each bout, respectively
    opt.padlent = 0 %same as padlen but in seconds
end
eb = opt.eb;
tin = opt.t;
padlen = opt.padlen;
padlent = opt.padlent;

if iscell(epochts) || iscell(eb) || iscell(tin) || iscell(padlen) || iscell(padlent)
    error("none of 'epochts', 'eb', 't', 'padlen', and 'padlent' can be cell")
end
if ~isempty(epochts) && ~isvector(epochts)
    error("epochts must be vector")
end
if ~isempty(tin) && ~isvector(tin)
    error("if name-value argument t is nonempty, it must be vector")
end
if ~isempty(tin) && ~isequal(numel(tin), numel(epochts))
    error("if name-value argument t is nonempty, it must be same length as epochts")
end
if any(~ismember(padlen,0)) && any(~ismember(padlent,0))
    error("padlen and padlent cannot both be nonzero")
end
if any(padlen<0)
    error("all elements of name-value argument padlen must be greater than or equal to zero")
end
if numel(padlen)>2
    error("name-value argument padlen must be scalar or ordinary vector of 2 elements")
end
if isscalar(padlen)
    padlen = repelem(padlen, 2);
end
if any(padlent<0)
    error("all elements of name-value argument padlent must be greater than or equal to zero")
end
if numel(padlent)>2
    error("name-value argument padlent must be scalar or ordinary vector of 2 elements")
end
if isscalar(padlent)
    padlent = repelem(padlent, 2);
end
if any(~ismember(padlent,0)) && isempty(tin)
    error("if name-value argument t is empty, all elements of name-value argument padlent must be zero")
end
if ~isempty(eb) && ~isequal(numel(eb), 2)
    error("name-value argument eb must be empty, or an ordinary vector of 2 elements")
end

epochs = unique(epochts(epochts~=0)); %ignore zeros, they don't count as epochs

ttmp = [];
ttmppad = [];
for k = 1:numel(epochs)
    ek = epochs(k);
    samptmp = find(sampepoch(epochts, ek));
    startsamp = samptmp([0 find(diff(samptmp)>1)]+1);
    stopsamp = samptmp([find(diff(samptmp)>1) numel(samptmp)]);
    for q = 1:numel(startsamp)
        idx{ek,q} = startsamp(q):stopsamp(q);
        padlentmp = padlen;
        if any(~ismember(padlent,0))
            dtmp = tin(idx{ek,q}(1))-padlent(1);
            if dtmp<min(tin)
                dtmp = min(tin); %if padlent takes you below min(t), just stop at min(t)
            end
            [~, mtmp] = min(abs(tin-dtmp));
            padlentmp(1) = round(abs(idx{ek,q}(1)-mtmp));
            dtmp = tin(idx{ek,q}(end))+padlent(2);
            if dtmp>max(tin)
                dtmp = max(tin); %if padlent takes you above max(t) 0, just stop at max(t)
            end
            [~, mtmp] = min(abs(tin-dtmp));
            padlentmp(2) = round(abs(idx{ek,q}(end)-mtmp));
        end
        if startsamp(q)-padlentmp(1)<1
            padlentmp(1) = 0;
        end
        if stopsamp(q)+padlentmp(2)>numel(epochts)
            padlentmp(2) = 0;
        end
        idxpad{ek,q} = idx{ek,q}(1)-padlentmp(1):idx{ek,q}(end)+padlentmp(2);
        if ~isempty(tin)
            ttmp{ek,q} = tin(idx{ek,q});
            ttmppad{ek,q} = tin(idxpad{ek,q});
        end
    end
end

tr.i = idx;
tr.ip = idxpad;
tr.t = ttmp;
tr.tp = ttmppad;

i = [];
ip = [];
t = [];
tp = [];
if ~isempty(eb)
    if eb(1)>size(idx,1) || eb(2)>size(idx,2)
        error("name-value argument eb requests an epoch-bout pair that does not exist")
    end
    if isempty(idx{eb(1),eb(2)})
        error("name-value argument eb requests an epoch-bout pair that does not exist")
    end
    i = idx{eb(1),eb(2)};
    ip = idxpad{eb(1),eb(2)};
    if ~isempty(tin)
        t = ttmp{eb(1),eb(2)};
        tp = ttmppad{eb(1),eb(2)};
    end
end
