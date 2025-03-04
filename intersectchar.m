function out = intersectchar(inp)

arguments
    inp cell %must be cell
end

inpchar = char(inp(:));
all_rows_same = all(diff(inpchar, [], 1) == 0, 1);
common_cols = find(~all_rows_same, 1, 'first')-1;
if isempty(common_cols)
    error("there is no common substring")
else
    out = inp{1}(1:common_cols);
end

