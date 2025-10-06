function [out, fld, idx] = structind(inp)

%{

convert char vector or string into fields and indices for getfield or setfield (out); 
separate field and indices also output as fld and idx   

%}

spl = convertStringsToChars(strsplit(inp, '.'));
if ~iscell(spl)
    spl = {spl};
end
fld = cell(1,numel(spl));
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
    fld{q} = fldtmp;
    idx{q} = idxtmp;
end
out = vec(cat(1, fld, idx))';
if isequal(out{end}, {':'})
    out(end) = [];
end

end