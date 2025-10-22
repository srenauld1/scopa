function [out, field, idx] = structind(inp)

%{

convert char vector or string into fields and indices for getfield or setfield (out); 
separate field and indices also output as field and idx   

%}

spl = convertStringsToChars(strsplit(inp, '.'));
if ~iscell(spl)
    spl = {spl};
end
field = cell(1,numel(spl));
idx = cell(1,numel(spl));
for q = 1:numel(spl)
    if contains(spl{q}, '(')
        idxtmp = regexp(spl{q}, '\(\d+(,\d)*\)$', 'match');
        if isscalar(idxtmp)
            idxtmp = idxtmp{1};
            fldtmp = erase(spl{q}, idxtmp);
            idxtmp = erase(idxtmp, {'(', ')', ','});
            idxtmp = regexp(idxtmp, '\d', 'match');
            idxtmp = num2cell(str2double(idxtmp));
        else
            error("noscalar index not properly formatted")
        end
    else
        fldtmp = spl{q};
        idxtmp = {':'};
    end
    field{q} = fldtmp;
    idx{q} = idxtmp;
end
out = vec(cat(1, field, idx))';
if isequal(out{end}, {':'})
    out(end) = [];
end

end