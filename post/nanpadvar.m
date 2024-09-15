function outp = nanpadvar(inp, goallen, opt)

arguments
    inp
    goallen
    opt.vecdim = 1 %dimension along which vectors are defined (not pad dimension)
    opt.paddim = [] %dim to pad
end
vecdim = opt.vecdim;
paddim = opt.paddim;
if isempty(paddim)
    paddim = setxor(vecdim, [1 2]);
end

if ndims(inp)>3
    error("inp must be 1d or 2d or 3d right now; nd coming soon")
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
    if ndims(inp)>3
        error("inp cannot be >3d")
    end
end

szpaddim = size(inp, paddim);
szdim3 = size(inp, 3);

numsamp_pad = goallen-szpaddim;
if paddim==1
    nanpad = nan(numsamp_pad, 1, szdim3);
elseif paddim==2
    nanpad = nan(1, numsamp_pad, szdim3);
end

for j = 1:size(inp, vecdim)

    C = repmat({':'},1,ndims(inp));
    C{vecdim} = j;
    tmp = inp(C{:});

    outp(C{:}) = cat(paddim, tmp, nanpad);

end

end