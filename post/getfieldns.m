function out = getfieldns(s,field)

% get field values in nonscalar struct
% inputs s and field can be nested (for struct a.b.c.d, field might be b.c.d . . . any and all levels can be nonscalar)
% out is equivalent to the requested fields if s were flattened
% structure of nonscalar structs is lost in the output, except their order 

tmp = strsplit(field, '.');

if numel(tmp)>1
    tmp1 = tmp{1};
    tmp2 = strjoin(tmp(2:end), '.');
    out = getfieldns([s.(tmp1)],tmp2);
else
    out = {s.(field)};
end

end
