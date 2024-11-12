function ts = tscell2mat(ts)

%convert cell of timeseries to matrix

arguments
    ts % timeseries to be plotted; each cell element must be timeseries vector, and cell must be vector (multiple channels not yet distinguihsed in the cell structure) 
end

if ~all(cellfun(@isvector, ts))
    error("if input argument ts is a cell, each element must be a vector")
end
if ~isvector(ts)
    error("if input argument ts is a cell, it must be a vector (n,1) or (1,n)")
end
for k = 1:numel(ts)
    if isrow(ts{k})
        ts{k} = ts{k}(:);
    end
end
if ~all(cellfun(@iscolumn, ts))
    error("each element of ts must be a column vector after above line, something must be wrong")
end
ts = ts(:)'; %make sure cell is row
ts = cell2mat(ts);
ts = permute(ts, [2 1 3]);

if size(ts,1)>size(ts,2)
    fprintf("warning, size of first dimension is greater than size of second dimension; 1st dimension should be timeseries index, 2nd dimension should be time; you may have this reversed")
end
