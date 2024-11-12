function tsout = tsmat2cell(ts)

%convert matrix of timeseries to cell, assumes scopa dimension order of (n,t,c) where n is number of timeseries, t is time, c is channel (3rd dimension, c, will not exist if ts is single-channel); BUT CHANNEL IS NOT YET SUPPORTED IN THIS FUNCTION BECAUSE WHEN CHANNEL IS USED IT IS NOT PLACED IN CELL SO YOU WILL N EVER ENTER THIS FUNCTION WITH CHANNEL > 1 

arguments
    ts
end

if ndims(ts)>2
    error("tsmat2cell does not support ndims>2")
end
if size(ts,1)>size(ts,2)
    fprintf("warning, size of first dimension is greater than size of second dimension; 1st dimension should be timeseries index, 2nd dimension should be time; you may have this reversed")
end

for k = 1:size(ts,1)
    tsout{k} = ts(k,:);
end




