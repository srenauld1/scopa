function [kpo, tso] = epochcrop(epochts, epoch, ts, opt)

%{
index timeseries (ts) using indices (epoch) from input vector (epochts)
output kpo is logical array, samples belonging to an index listed in input 'epoch' assigned 1
output tso is same as input ts, but only samples belonging to an index listed in input 'epoch' are retained
if epoch is not scalar, outputs are union of each epoch seubset  
%}

arguments (Input)
    epochts {mustBeVector}
    epoch = []
end
arguments (Input,Repeating)
    ts
end
arguments (Input)
    opt.dm = []
end
arguments (Output)
    kpo
end
arguments (Output,Repeating)
    tso
end


%%%% FORMAT/CHECK INPUTS %%%%

if isempty(epoch)
    epoch = num2cell(unique(epochts));
end
if ~iscell(epoch)
    epoch = {epoch};
end
if ~ismember(opt.dm, [1 2])
    error("name-value argument dm (indexing dimension) must be 1 or 2")
end

n = numel(epochts);
nts = numel(ts);
ne = numel(epoch);

tscell = zeros(1, nts, 'logical');
for q = 1:numel(ts)
    if iscell(ts{q})
        tscell(q) = 1;
        ts{q} = cell2mat(ts{q});
    end
end
if any(cellfun(@ndims,ts)>2)
    error("all ts must be 1d or 2d")
end


%%%% COMPUTE INDEX AND APPLY TO ALL ts %%%%

kpo = zeros(ne, n, 'logical');
kp = zeros(size(epochts), 'logical');
for q = 1:nts
    tso{q} = cell(1,ne);
end
for k = 1:ne

    if isempty(epoch{k}) %if you pass in nonempty epoch with empty element, that means use the whole timeseries for that element's index (if you pass in empty epoch, index using each element of epochts)
        kp(:) = 1;
    else
        kp(:) = 0;
        for w = 1:numel(epoch{k})
            if ~any(ismember(epochts, epoch{k}(w)))
                fprintf("warning, requested epoch " + epoch{k}(w) + " does not exist in epochts, ignoring it (if this is your only requested epoch, output will be empty)" + newline)
            end
            kp = kp | ismember(epochts, epoch{k}(w));
        end
    end

    for q = 1:nts
        if ~isempty(ts{q})
            if isequal(size(ts{q},1), size(ts{q},2)) && isempty(opt.dm)
                error("size(ts,1) is equal to size(ts,2), and you did not pass in argument 'dm', so indexing dimension is ambiguous")
            end
            if (isequal(opt.dm,1) && isequal(size(ts{q},1), n)) || (isempty(opt.dm) && isequal(size(ts{q},1), n))
                tso{q}{k} = ts{q}(kp,:);
            elseif (isequal(opt.dm,2) && isequal(size(ts{q},2), n)) || (isempty(opt.dm) && isequal(size(ts{q},2), n))
                tso{q}{k} = ts{q}(:,kp);
            else
                error("for each ts input, numel(epochts) must equal size(ts,opt.dm), if or if opt.dm is empty, either size(ts,1) or size(ts,2)")
            end
            if tscell(q)
                tso{q}{k} = {tso{q}{k}};
            end
        end
    end

    kpo(k,:) = kp;
end

if ne==1
    for q = 1:nts
        if ~tscell(q)
            tso{q} = cell2mat(tso{q});
        end
    end
end
