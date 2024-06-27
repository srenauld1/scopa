
function [varargout] = nanpadvars(numsamp_max, varargin)

for j = 1:numel(varargin)
    numsamp_pad = numsamp_max-numel(varargin{j});
    varargout{j} = cat(1, varargin{j}(:), nan(numsamp_pad, 1));
end

end