
function lim = axlim(ts, opt)

%{
outputs struct with various versions of limits
    lim.each gives limits for each timeseries in ts
    lim.eachxtra adds roomfac onto lim.each
    lim.all gives limits for set of all timeseries in ts (pools dim 1 and 2)
    lim.eachxtra adds roomfac onto lim.all
    lim.rs gives limits of timeseries if they are rescaled onto newlim (name-value argument with default [0 1])
    lim.eachxtra adds roomfac onto lim.rs
%}

arguments
    ts % timeseries to be plotted; if matrix, size is (n,t,c) where n is number of timeseries, t is time, c is channel (3rd dimension, c, will not exist if ts is single-channel); if cell, each cell element must be timeseries vector, all equal in length, and cell must be vector (multiple channels not yet distinguihsed in the cell structure)   
    opt.roomfac = 0.15  %fraction of total, extra room on y axis, top and bottom
    opt.newlim = [0 1] %new limits (e.g. for setting multiple timeseries on same scale, same axis)
    opt.chanpool = 0 %1 computes limits on all channels together, 0 computes limits on all channels independently,
    opt.omitnan = 1
    opt.limtype = [] %empty [], 'all', 'each', 'rs'; if empty, output lim will be struct will all limit types; if not empty, lim will be field lim.(limtype)
end
roomfac = opt.roomfac;
newlim = opt.newlim;
chanpool = opt.chanpool;
omitnan = opt.omitnan;
limtype = opt.limtype;

domatrix = 1;

if ~omitnan
    error("currently axlim is not written for omitnan=0")
end

if iscell(ts)
    if ~all(cellfun(@isvector, ts))
        error("if input argument ts is a cell, each element must be a vector")
    end
    if ~isvector(ts)
        error("if input argument ts is a cell, it must be a vector (n,1) or (1,n)")
    end
    if numel(ts)>1 && all(cellfun(@(x) isequal(size(ts{1}), size(x)), ts(2:end)))
        ts = tscell2mat(ts);
    else
        ts = ts(:); %make sure it's a column vector
        domatrix = 0;
        vrng = cellfun(@(x) range(x, 2), ts);
        lim.each = [cellfun(@(x) min(x, [], 'all', 'omitmissing'), ts), cellfun(@(x) max(x, [], 'all', 'omitmissing'), ts)];
    end
end

if size(ts,1)>size(ts,2)
    fprintf("warning, size of first dimension is greater than size of second dimension; 1st dimension should be timeseries index, 2nd dimension should be time; you may have this reversed")
end

if chanpool
    ts = reshape(ts, size(ts,1), []); %collapse channel into time to consider all channels together
end

if domatrix %if ts is cell of different length vectors, then thes two are derived above with cellfun
    vrng = range(ts, 2);
    lim.each = [min(ts, [], 2, 'omitmissing'), max(ts, [], 2, 'omitmissing')];
end
lim.eachxtra = [lim.each(:,1,:) - vrng*roomfac, lim.each(:,2,:) + vrng*roomfac];
lim.all = [min(lim.each, [], [1 2], 'omitmissing'), max(lim.each, [], [1 2], 'omitmissing')]; %min over first two dims, in case 3rd dim >1 (channels>1)
lim.allxtra = [min(lim.eachxtra, [], [1 2], 'omitmissing'), max(lim.eachxtra, [], [1 2], 'omitmissing')];
lim.rs = newlim;
lim.rsxtra = [0 - roomfac, 1 + roomfac];

if ~isempty(limtype)
    lim = lim.(limtype);
end

end