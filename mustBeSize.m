function mustBeSize(x,varargin)

%{

ensure input array x matches input
x can be any number of dimensions, and any class
subsequent input arguments must be integers (or ':') denoting lengths of each dimension
input ':' means any length for corresponding dimension

%}

if numel(varargin)<2
    error("size must be at least 2 elements in argument validation function mustBeSize")
end

numdim = numel(varargin);
numdimx = ndims(x);
if numdimx~=numdim
    error("number dimensions is " + num2str(numdimx) + ", but must be " + num2str(numdim) + " (since " + num2str(numdim) + " size inputs were specified)")
end

k = strcmp(varargin, ':');
kp = find(~k);
if isempty(kp)
    error("cannot specify ':' for all dimensions (if any size is valid, there is no need to use this function)")
end
szx_kp = size(x,kp);
if any(cellfun(@istextall, varargin(kp)))
    error("one of the size inputs is text; the only valid text input is ':', which means 'any length'")
end
sz_kp = cell2mat(varargin(kp));

if ~isequal(szx_kp, sz_kp)
    lab = num2str(varargin{1});
    for k = 2:numel(varargin)
        lab = [lab ',' num2str(varargin{k})];
    end
    error("must be size (" + lab + ")")
end

end