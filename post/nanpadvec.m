function outp = nanpadvec(inp, numsamp_max, vecdim)

arguments
    inp
    numsamp_max
    vecdim = 1 %dimension along which vectors are defined (not pad dimension)
end

if numel(size(inp))>2
    error("inp must be 1d or 2d right now; nd coming soon")
end
if isvector(inp) && vecdim==1 && iscolumn(inp)
    error("make dim 2 for column vector input")
end
if isvector(inp) && vecdim==2 && isrow(inp)
    error("make dim 1 for row vector input")
end


if ~isvector(inp)
    if isempty(vecdim)
        error("must specify dim is inp is not vector")
    end
    if ndims(inp)>2
        error("inp cannot be >2d")
    end
end


for j = 1:size(inp, vecdim)

    C = repmat({':'},1,ndims(inp));
    C{vecdim} = j;
    tmp = inp(C{:});

    numsamp_pad = numsamp_max-numel(tmp);
    if vecdim==1
        outp(C{:}) = cat(vecdim, tmp(:), nan(numsamp_pad, 1));
    elseif vecdim==2
        outp(C{:}) = cat(vecdim, tmp(:)', nan(1, numsamp_pad));
    end

end

end