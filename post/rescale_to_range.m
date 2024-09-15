function inp = rescale_to_range(inp, source, target, skipnan, dim)

%rescale inp from source to target
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

if size(source, 1)~=size(inp,1)
    source = source';
end
if size(target, 1)~=size(inp,1)
    target = target';
end
if iscell(source)
    stmp = cellfun(@size, source, 'UniformOutput', false);
    maxsz = max(cell2mat(cellfun(@numel, stmp, 'UniformOutput', false)));
    if ~isequal(stmp{:})
        if maxsz==3 && min(cell2mat(cellfun(@numel, stmp, 'UniformOutput', false)))==2
            repidx = cell2mat(cellfun(@numel, stmp, 'UniformOutput', false))~=maxsz;
            source(repidx) = cellfun(@(x) repmat(x, [1 1 2]), source(repidx), 'UniformOutput', false);
            source = cell2mat(source);
        else
            error("source size mistmatch")
        end
    else
        source = cell2mat(source);
    end
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

for j = 1:size(inp, dim)

    C = repmat({':'},1,ndims(inp));
    C{dim} = j;

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


