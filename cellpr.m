
function out = cellpr(s)
tmp = regexp(s, '{(.*)}', 'tokens');
for q = 1:numel(tmp)
    out{q} = cellprr(tmp{q});
end

end
