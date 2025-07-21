function [inds, indslab] = indsmake(indsin, opt)


arguments
    indsin {mustBeNumeric} = []
    opt.indsall {mustBeNumeric} = []
    opt.label_prefix char = ''
    opt.delimprefix char = ': '; %colon with whitespace 
    opt.delimvec char = ',';
    opt.printmax = 20
end

indsall = opt.indsall;
printmax = opt.printmax;
label_prefix = opt.label_prefix;
delimprefix = opt.delimprefix;
delimvec = opt.delimvec;


if isscalar(indsall)
    indsall = 1:indsall;
end

if any(indsin<0) & numel(indsin)>1
    error("negative inds must be scalar")
end
if isempty(indsall) && ( isempty(indsin) || indsin<0 || mod(indsin, 1)~=0 )
    error("for empty, negative, or fractional inds, you must pass in indsall (inds' superset) as a reference")
end

fractional_indsin = 0;

if isempty(indsin)
    indslab = ['1to' num2str(numel(indsall))];
    inds = 1:numel(indsall);
elseif indsin<0
    indslab = ['neg' num2str(indsin)];
    if mod(indsin, 1)~=0
        error("negative inds must be integer")
    end
    if -indsin<numel(indsall)
        inds = round(linspace(1, numel(indsall), -indsin));
    else
        inds = 1:numel(indsall);
    end
elseif all(isnan(indsin))
    inds = indsin;
elseif mod(indsin, 1)~=0
    fractional_indsin = 1;
    if numel(indsin)>1 || indsin<0
        error("fractional inds must be positive scalar")
    end
    seglength = fix(indsin);
    factmp = 10^(numel(num2str(indsin))-numel(num2str(seglength))-1);
    numseg = mod(indsin, 1)*factmp;
    numseg = round(numseg);
    segspacing = floor(numel(indsall)/numseg);
    inds = [1:seginc:seglength]+segspacing*([1:numseg]'-1)+segspacing-seglength;
    for j = 1:size(inds,1)
        indslab{j} = [num2str(inds(j,1)) '-' num2str(inds(j,end))];
    end
    indslab = strjoin(indslab, ': ');
    inds = vec(inds.');
    if numel(inds)>numel(indsall) | any(inds<0)
        sprintf("seglength*numseg exceeds num inds, plotting all inds")
        inds = 1:numel(indsall);
    end
else
    inds = indsin;
end

inds = inds(:)';

%regardless of what happens above, apply this as an additional step
if isequal(inds, min(inds):max(inds))
    indslab = [num2str(min(inds)) '-' num2str(max(inds))];
elseif isequal(sort(inds), min(inds):max(inds))
    indslab = [num2str(min(inds)) '-' num2str(max(inds)) 'unsorted'];
else
    if ~fractional_indsin
        if numel(inds)<printmax
            indslab = regexprep( mat2str(inds), {'\[', '\]', '\s+'}, {'', '', delimvec});
        else
            indslab = 'noprint';
        end
    end
end

if ~isempty(label_prefix)
    indslab = [label_prefix delimprefix indslab];
end

end

