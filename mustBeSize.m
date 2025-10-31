function mustBeSize(x,varargin)

%ensure array size matches varargin, can be any number dimensions; input ':' means any

if numel(varargin)<2
    error("size must be at least 2 elements in argument validation function mustBeSize")
end

k = strcmp(varargin, ':');
kp = find(~k);
szx_kp = size(x,kp);
sz_kp = cell2mat(varargin(kp));

if ~isequal(szx_kp, sz_kp)
    lab = num2str(varargin{1});
    for k = 2:numel(varargin)
        lab = [lab ',' num2str(varargin{k})];
    end
    error("must be size (" + lab + ")")
end

end