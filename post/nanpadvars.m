
function varargout = nanpadvec(numsamp_max, varargin)

for j = 1:numel(varargin)
    if ~isvector(varargin{j})
        error("must be vector")
    end
    numsamp_pad = numsamp_max-numel(varargin{j});
    varargout{j} = cat(1, varargin{j}(:), nan(numsamp_pad, 1));
end

end