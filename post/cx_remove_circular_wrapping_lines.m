function out = cx_remove_circular_wrapping_lines(inp, diffwin)

%replace diffs (over diffwin num samples) greater than thresh with nan in the wrapped variable inp because the lines make it difficult to read
out = inp;

thresh = pi;
if diffwin
    filt = [zeros(1,diffwin-1) 1 zeros(1,diffwin-1) -1];

    difsig = conv(inp, filt, 'full');
    difsig = difsig((length(filt) - 1)+1:end-(length(filt) - (1 + (diffwin-1))));
    difsig = [zeros((diffwin-1)+1, 1); difsig]; %get index right by appending 0 to front of diff
    naninds = abs(difsig)>thresh;
    out(naninds) = nan;

end