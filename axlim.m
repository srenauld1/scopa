
function lim = axlim(ts, opt)

%{
computes various limits for input ts, outputs struct
    lim.each gives limits for each timeseries in ts
    lim.eachpad adds roomfac onto lim.each
    lim.all gives limits for set of all timeseries in ts (pools dim 1 and 2)
    lim.eachpad adds roomfac onto lim.all
    lim.rs gives limits of timeseries if they are rescaled onto newlim (name-value argument with default [0 1])
    lim.eachpad adds roomfac onto lim.rs
%}

arguments (Input, Repeating)
    ts % timeseries; cell array; within each cell element, size is (n,t,c) where n is number of timeseries, t is time, c is channel (3rd dimension, c, will not exist if ts is single-channel); 'each' option for output lim refers to each cell, unless there is one input, in which case 'each' refers to each timeseries along the first dimension; if user passes multiple timeseries as arguments, each argument is a separate single timeseries (for 'each') and first dimension is collapsed
end

arguments (Input)
    opt.roomfac = 0.15  %fraction of total, extra room on y axis, top and bottom
    opt.newlim = [0 1] %new limits (e.g. for setting multiple timeseries on same scale/axis)
    opt.chanpool = 0 %1 computes limits on all channels together, 0 computes limits on all channels independently,
    opt.omitnan = 1 %omit nan in computing limits
    opt.limtype = [] %empty [], 'all', 'allpad', 'each', 'eachpad', 'rs', 'rspad'; if empty, output lim will be struct will all limit types; if not empty, lim will be field lim.(limtype)
end

arguments (Output)
    lim %struct with various limits computed from input ts, or one field from this struct if opt.limtype is not empty; for fields containing substring 'each', size is (n,2,c), where columns represent each timeseries (parsed from ts in a way dependent on calling syntax) and 2 rows represent min and max, and c represents each channel, unless chanpool=1, in which case channels are collapsed before computing limits; for fields containing substring 'all', size is (1,2,c), where limits are computed on all timeseries, and c is the same as in 'each'
end

roomfac = opt.roomfac;
newlim = opt.newlim;
chanpool = opt.chanpool;
omitnan = opt.omitnan;
limtype = opt.limtype;


collapse_first_cell_dim = 1; %for now hard coding, in case cell arrays have multiple timeseries each (size first dim>1), consider each cell one; could allow this to be an option with a couple small changes

for k = 1:nargin
    if iscell(ts{k})
        if nargin>1
            fprintf("warning, multiple arguments passed in as ts, and at least one is itself a cell; cells within each argument will be collapsed along first dimension and considered a single timeseries for limit computation" + newline)
        end
        if numel(ts{k})>1 && ~all(cellfun(@(x) isequal(size(ts{k}{1}, [2 3]), size(x, [2 3])), ts{k}(2:end)))
            error("warning, argument number " + num2str(k) + " is a cell, but not all of its elements have same size after first dimension, so it cannot be concatenated along first dimension to be considered a single cell" + newline)
        end
        ts{k} = cell2mat(vec(ts{k})); %cat cell along first dim
    end
end
if ~omitnan
    error("currently axlim is not written for omitnan=0")
end

if any(cellfun(@iscell, ts))
    error("input ts cannot be cell of cell")
end
if ~isvector(ts)
    error("if input argument ts is a cell, it must be a vector (n,1) or (1,n)")
end
if any(cellfun(@(x) size(x,1), ts)>cellfun(@(x) size(x,2), ts))
    fprintf("warning, size of first dimension is greater than size of second dimension for at least one cell in ts; 1st dimension should be timeseries index, 2nd dimension should be time; you may have this reversed" + newline)
end
if numel(ts)>1 && ~all(cellfun(@(x) isequal(size(ts{1},3), size(x,3)), ts(2:end)))
    error("all input ts must have same number of channels")
end
if numel(ts)>1 && ~all(cellfun(@(x) isequal(size(ts{1}), size(x)), ts(2:end)))
    fprintf("warning, timeseries in axlim are not all equal in length in time" + newline)
end

if nargin>1 && collapse_first_cell_dim
    ts = cellfun(@(x) reshape(x, 1, [], size(x,3)), ts, 'UniformOutput', false); %collapse first dimension of each cell to consider each cell as a single timeseries (or 2 if 2-channel)
    dmcl = [1 2];
else
    dmcl = 2;
end

ts = ts(:); %make sure column vector

if chanpool
    ts = cellfun(@(x) reshape(x, size(x,1), []), ts, 'UniformOutput', false); %collapse channel into time to consider all channels together
end

vrng = cell2mat(cellfun(@(x) range(x,2), ts, 'UniformOutput', false));
lim.each = [cell2mat(cellfun(@(x) min(x, [], dmcl, 'omitmissing'), ts, 'UniformOutput', false)), cell2mat(cellfun(@(x) max(x, [], dmcl, 'omitmissing'), ts, 'UniformOutput', false))];

lim.eachpad = [lim.each(:,1,:) - vrng*roomfac, lim.each(:,2,:) + vrng*roomfac];
lim.all = [min(lim.each, [], [1 2], 'omitmissing'), max(lim.each, [], [1 2], 'omitmissing')]; %min over first two dims, in case 3rd dim >1 (channels>1)
lim.allpad = [min(lim.eachpad, [], [1 2], 'omitmissing'), max(lim.eachpad, [], [1 2], 'omitmissing')];
lim.rs = newlim;
lim.rspad = [0 - roomfac, 1 + roomfac];

if ~isempty(limtype)
    lim = lim.(limtype);
end

end