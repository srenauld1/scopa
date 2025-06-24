function [sout, fnout] = structunflat(s, opt)

%{

unflatten a struct that was flattened with structflat
input cannot have any nesting if nonest is true (it should be flattened struct, eg with structflat)

%}
arguments
    s
    opt.delim = []
    opt.nonest = 0 %0 allows nested input structs, 1 does not
end
delim = opt.delim;
nonest = opt.nonest;

if isempty(delim)
    % fprintf("USING DEFAULT DELIMITER DOUBLE UNDERSCORE IN structunflat" + newline)
    delim = '__';
end


fn = fieldnames(s);
sout = struct;
fnout = cell(1,numel(fn));
for k = 1:numel(fn)
    if nonest && isstruct(s.(fn{k}))
        error("input to structunflat must be flat struct; you passed a struct with nesting")
    end
    fnsplit = strsplit(fn{k}, delim);
    idxtmp = cell(1,numel(fnsplit)*2);
    for q = 1:numel(fnsplit)
        if isnan(str2double(fnsplit{q}))
            idxtmp{1+2*(q-1)} = '.';
            idxtmp{2+2*(q-1)} = fnsplit{q};
        else
            idxtmp{1+2*(q-1)} = '()';
            idxtmp{2+2*(q-1)} = {str2double(fnsplit{q})}; %put number in cell
        end
    end
    valtmp = s.(fn{k});
    sout = subsasgn(sout,substruct(idxtmp{:}),valtmp);
    fntmp = regexprep(fn{k}, [delim '(\d+)' delim], '($1).'); %nonscalar index . . . this should not happen --> regexprep(fnnew, [delim '(\d+)', '($1)') because this is number at end, which is an array index not a struct index
    fntmp = strrep(fntmp, delim, '.');
    fnout{k} = fntmp;
end

end