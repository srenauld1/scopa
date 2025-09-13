function [xout, lab, ix] = vecsub(x, opt)

%{

use input x to create subset of name-value argument 'superset'
if x is vector subset of superset, x and xout are equal
if x is one of the valid shorthand operators, and superset is nonempty, xout is derived from superset (depending on shorthand)
valid shorthand operators:
    (1) if x is empty, xout equals superset
    (2) if x is negative integer scalar, x=linspace(superset(1), superset(end), x) 
    (3) if x is complex, real part is number of equispaced segments in entire superset, and imaginary part is number of elements in each segment
        --if imaginary part is positive, first element of xout is first element of superset, if imaginary part is negative, last element of xout is last element of superset,
if name-value argument dosort=1, superset is sorted before applying subset operation
if superset is empty, shorthand operators cannot be used 
output:
    xout:
        if superset is empty, and x is not a shorthand operator, xout=x are equal
        if superset is nonempty, output xout=superset(ix), where ix is vector of indices computed from input x 
        xout matches vector orientation of superset
    lab:
        lab is character vector label for xout (created 
    ix:
        ix is vector of indices used to subset superset

%}

arguments
    x = [] %input used to translate superset into xout using one of the valid shorthand operators (see above)
    opt.superset = [] %if nonempty, superset of which xout must be member (error if not member of superset); if empty, xout is simply same as input x
    opt.dosort = 0 %sort superset before applying special operators
    opt.labprefix char = '' %for label, prefix (name) of output vector x
    opt.labdelim char = ',' %for label, delimiter separating each vector element in lab
    opt.labmaxn = 20 %max num char to print
end
superset = opt.superset;
dosort = opt.dosort;
labprefix = opt.labprefix;
labdelim = opt.labdelim;
labmaxn = opt.labmaxn;

if ~isempty(x) && ( ~isvector(x) || ( any(isnan(x)) && any(~isnan(x)) ) )
    error("input x must be empty or vector without nan, or vector of all nan")
end
if ~isempty(superset) && ~isvector(superset)
    error("name-value argument superset must be empty or vector")
end

emptyop = 0;
if isempty(x)
    if isempty(superset)
        error("to use empty input x as 'all elements' operator, you must pass in name-value argument 'superset' as a reference")
    else
        emptyop = 1;
    end
end

negop = 0;
if ~isempty(x) && all(x<0)
    if isscalar(x)
        if mod(x, 1)==0
            if isempty(superset)
                error("to use negative input x as linspace operator, you must pass in name-value argument 'superset' as a reference")
            else
                negop = 1;
            end
        else
            error("to use negative input x as linspace operator, negative input x must be integer")
        end
    else
        error("to use negative input x as linspace operator, negative input x must be scalar")
    end
end

compop = 0;
if ~isempty(x) && ~isreal(x)
    if isscalar(x)
        if real(x)>0
            if isempty(superset)
                error("to use complex input x as discontiguous vector operator, you must pass in name-value argument 'superset' as a reference")
            else
                compop = 1;
            end
        else
            error("to use complex input x as discontiguous vector operator, real part of complex input x must be positive")
        end
    else
        error("to use complex input x as discontiguous vector operator, complex input x must be scalar")
    end
end

if dosort
    superset = sort(superset);
end

if emptyop
    ix = 1:numel(superset);
elseif negop
    if -x<=numel(superset)
        ix = round(linspace(1, numel(superset), -x));
    else
        error("negative input x is requesting more elements than there are elements in superset")
    end
elseif compop
    numseg = real(x);
    seglen = abs(imag(x));
    segspacing = floor(numel(superset)/numseg);
    seginc = 1;
    if imag(x)<0
        ix = [1:seginc:seglen]'+segspacing*([1:numseg]-1);
    elseif imag(x)>0
        ix = [1:seginc:seglen]'+segspacing*([1:numseg]-1)+segspacing-seglen+1;
    end
    if numel(ix)>numel(superset) || any(ix<0, 'all')
        fprintf("seglength*numseg exceeds numel(superset), output will equal superset" + newline)
        ix = 1:numel(superset);
    end
else
    ix = x;
end

if any(isnan(ix), 'all') && any(~isnan(x)) %use all here because ix may not be vector yet
    error("output ix cannot have any nans, unless it's all nan, and input x did not have nan")
end

if all(isnan(ix))
    xout = ix;
else
    if ~isempty(superset) && any(~ismember(ix, 1:numel(superset)), 'all')
        error("at least one element of xout is outside superset")
    end
    xout = superset(ix);
end

if compop && numseg*2<=labmaxn && seglen>2 %special label for complex input x (not created by
    lab = cell(1,size(xout,2));
    for k = 1:size(xout,2)
        lab{k} = [num2str(xout(1,k)) ':' num2str(xout(end,k))];
    end
    lab = strjoin(lab, ',');
else
    lab = num2lab(xout(:), delim=labdelim, prefix=labprefix, maxn=labmaxn);
end

ix = ix(:);
xout = xout(:);
if isrow(superset)
    ix = ix.';
    xout = xout.';
end


end

