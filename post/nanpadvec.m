function outp = nanpadvec(inp, numsamp_max, dim)

arguments
    inp
    numsamp_max
    dim = 1
end


if ~isvector(inp)
    if isempty(dim)
        error("must specify dim is inp is not vector")
    end
    if ndims(inp)>2
        error("inp cannot be >2d")
    end
end


for j = 1:size(inp, dim)

    C = repmat({':'},1,ndims(inp));
    C{dim} = j;
    tmp = inp(C{:});

    numsamp_pad = numsamp_max-numel(tmp);
    outp(C{:}) = cat(dim, tmp(:), nan(numsamp_pad, 1));

end

end