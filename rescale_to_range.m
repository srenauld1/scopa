function inp = rescale_to_range(inp, source, target, skipnan, dim)

% rescale inp from source to target (source and target can be arrays, in which case limits are extracted, or limits themselves)
% normal rescale would use inp as source, and target of [0 1]

arguments
    inp
    source
    target
    skipnan = 1
    dim = 1
end

if dim~=1
    error("right now dim must be 1")
end

inp_cell = 0;
nanpad = 0;
if iscell(inp)
    inp_cell = 1;
    if ~all(cellfun(@isvector, inp))
        error("if input argument inp is a cell, each element must be a vector")
    end
    if ~isvector(inp)
        error("if input argument inp is a cell, it must be a vector (n,1) or (1,n)")
    end
    if numel(inp)>1 && all(cellfun(@(x) isequal(size(inp{1}), size(x)), inp(2:end)))
        inp = tscell2mat(inp);
    else
        nanpad = 1;
        inp = inp(:); %make sure it's a column vector
        numelmax = max(cellfun(@numel, inp));
        for k = 1:numel(inp) %insert nan padding to convert cell to mat
            padlen{k} = numelmax-numel(inp{k});
            inp{k} = padarray(inp{k}(:), padlen{k}, nan, 'post');
        end
        inp = tscell2mat(inp);
    end
end

if size(source, 1)~=size(inp,1)
    source = source';
end
if size(target, 1)~=size(inp,1)
    target = target';
end
if iscell(source)
    if numel(source)~=1
        stmp = cellfun(@size, source, 'UniformOutput', false);
        maxsz = max(cell2mat(cellfun(@numel, stmp, 'UniformOutput', false)));
        if ~isequal(stmp{:})
            if maxsz==3 && min(cell2mat(cellfun(@numel, stmp, 'UniformOutput', false)))==2
                repidx = cell2mat(cellfun(@numel, stmp, 'UniformOutput', false))~=maxsz;
                source(repidx) = cellfun(@(x) repmat(x, [1 1 2]), source(repidx), 'UniformOutput', false);
            else
                error("source size mistmatch")
            end
        end
    end
    source = cell2mat(source);
end
if iscell(target)
    target = cell2mat(target);
end
if numel(source)~=2 && ~isequal(ndims(source), ndims(inp)) && size(source, 1)~=size(inp,1)
    error("source must either be 2 element vector or size (2,n) or (n,2) where n is size(inp, dim)")
end
if numel(target)~=2 && ~isequal(ndims(target), ndims(inp)) && size(target, 1)~=size(inp,1)
    error("source must either be 2 element vector or size (2,n) or (n,2) where n is size(inp, dim)")
end
if numel(source)==2
    source = repmat(vec(source)', size(inp,1), 1);
end
if numel(target)==2
    target = repmat(vec(target)', size(inp,1), 1);
end


if ~isvector(inp)
    if isempty(dim)
        error("must specify dim if inp is not vector")
    end
end

for k = 1:size(inp, dim)

    C = repmat({':'},1,ndims(inp));
    C{dim} = k;

    inptmp = inp(C{:});
    tgttmp = target(C{:});
    srctmp = source(C{:});


    if skipnan
        tmin = min(tgttmp, [], 'all', 'omitmissing');
        tmax = max(tgttmp, [], 'all', 'omitmissing');
    else
        tmin = min(tgttmp, [], 'all');
        tmax = max(tgttmp, [], 'all');
    end
    if skipnan
        smin = min(srctmp, [], [1 2], 'omitmissing');
        smax = max(srctmp, [], [1 2], 'omitmissing');
    else
        smin = min(srctmp, [], [1 2]);
        smax = max(srctmp, [], [1 2]);
    end

    inptmp = tmin + [(inptmp-smin)./(smax-smin)].*(tmax-tmin);

    inp(C{:}) = inptmp;


end


if inp_cell
    inp = tsmat2cell(inp); %return inp to original form
    if nanpad %remove nan padding
        for k = 1:numel(inp)
            inp{k} = inp{k}(1:end-padlen{k});
        end
    end
end
