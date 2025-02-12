function vin = rescale2(vin, source, target, omitnan, dim)

% rescale vin from source to target (source and target can be arrays, in which case limits are extracted, or source and target can be the limits themselves)
% normal rescale would use vin itself as source, and target of [0 1]

arguments
    vin
    source
    target
    omitnan = 1
    dim = 1 %dimension vin is separated along to apply source and target (vin, source, and target must all match in size of this dimension, unless source and/or target is vector, in which case vector min/max is applied to all dimension dim of vin to rescale)
end

if dim~=1
    error("right now dim must be 1; there are several spots below that assume dim=1 and treat dim 2 as rescaling dim")
end

viniscell = 0;
if iscell(vin)
    viniscell = 1;
    if ~isvector(vin)
        error("if input argument vin is a cell, it must be a vector (n,1) or (1,n)")
    end
    if numel(vin)>1 && ~all(cellfun(@(x) isequal(ndims(vin{1}), ndims(x)), vin(2:end)))
        error("all input vin must have same number of dimensions")
    end
    vin = vin(:); %make sure it's a column vector
    numelmax = max(cell2mat(cellfun(@(x) size(x), vin, 'UniformOutput', false)), [], 1);
    padlen = repelem({zeros(1,ndims(vin))}, numel(vin));
    for k = 1:numel(vin) %insert nan padding to convert cell to mat, in case different sizes
        dimnot{k} = setxor(dim, 1:ndims(vin{k}));
        szone{k} = size(vin{k}, dim);
        padlen{k}(dimnot{k}) = numelmax(dimnot{k})-size(vin{k}, dimnot{k});
        vin{k} = padarray(vin{k}, padlen{k}, nan, 'post');
    end
    vin = cell2mat(vin);
end

if iscell(source)
    if numel(source)~=1
        stmp = cellfun(@size, source, 'UniformOutput', false);
        maxnumdims = max(cell2mat(cellfun(@numel, stmp, 'UniformOutput', false)));
        minnumdims = min(cell2mat(cellfun(@numel, stmp, 'UniformOutput', false)));
        if ~isequal(stmp{:}) %if all cells are not same size
            if maxnumdims==3 && minnumdims==2
                repidx = cell2mat(cellfun(@numel, stmp, 'UniformOutput', false))~=maxnumdims; %indices with 2 dims
                source(repidx) = cellfun(@(x) repmat(x, [1 1 2]), source(repidx), 'UniformOutput', false); %repmat them to make them 3 dims, won't affect rescaling
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
if ~isvector(source) && size(source, dim)~=size(vin,dim)
    error("source must either be vector, or matrix where size(source, dim) = size(vin, dim)")
end
if ~isvector(target) && size(target, dim)~=size(vin,dim)
    error("target must either be vector, or matrix where size(target, dim) = size(vin, dim)")
end

if ~isvector(vin)
    if isempty(dim)
        error("must specify dim if vin is not vector")
    end
end

C = repmat({':'},1,ndims(vin));
for k = 1:size(vin, dim)

    C{dim} = k;

    vintmp = vin(C{:});
    if isvector(source)
        srctmp = source;
    else
        srctmp = source(C{:});
    end
    if isvector(target)
        tgttmp = target;
    else
        tgttmp = target(C{:});
    end

    if omitnan
        smin = min(srctmp, [], [1 2], 'omitmissing');
        smax = max(srctmp, [], [1 2], 'omitmissing');
    else
        smin = min(srctmp, [], [1 2]);
        smax = max(srctmp, [], [1 2]);
    end

    if omitnan
        tmin = min(tgttmp, [], 'all', 'omitmissing');
        tmax = max(tgttmp, [], 'all', 'omitmissing');
    else
        tmin = min(tgttmp, [], 'all');
        tmax = max(tgttmp, [], 'all');
    end


    vintmp = tmin + [(vintmp-smin)./(smax-smin)].*(tmax-tmin);

    vin(C{:}) = vintmp;

end


if viniscell
    tmp = 0;
    vintmp = cell(1, numel(szone));
    C = repmat({':'},1,ndims(vin));
    for k = 1:numel(szone)
        idx = [1:szone{k}]+tmp;
        C{dim} = idx;
        vintmp{k} = vin(C{:}); %return to original form
        tmp = tmp + szone{k};
    end
    vin = cell(1, numel(vintmp));
    for k = 1:numel(vin)
        for m = 1:numel(padlen{k})
            C = repmat({':'},1,ndims(vintmp{k}));
            C{m} = 1:size(vintmp{k},m)-padlen{k}(m);
            vintmp{k} = vintmp{k}(C{:}); %remove nan padding, if any
        end
        vin{k} = vintmp{k};
    end
end


end

