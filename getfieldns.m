function out = getfieldns(s,inp)

%{

this function needs work
get field values in nonscalar struct
all indices of s must have same fields
inputs s and field can be nested (for struct a.b.c.d, field might be b.c.d . . . any and all levels can be nonscalar)
out is equivalent to the requested fields if s were flattened
structure of nonscalar structs is lost in the output, except their order

can't use simpler approach (structind to format field and index for getfield, like in glb) because it won't return cell array of output from nonscalar struct, so this function does it an uglier way

%}

arguments
    s
    inp
end

tmp = strsplit(inp, '.');
field = tmp{1};
[field, idx] = getidx(field);
if numel(tmp)>1
    % if strcmp(field, '*')
    %     field = fieldnames(s);
    % end
    suffix = strjoin(tmp(2:end), '.');
    if isfield(s, field)
        try
            out = getfieldns([s.(field)(idx)],suffix);
        catch ME
            if contains(ME.message, 'Concatenation of structure arrays requires that these arrays have the same set of fields')
                fprintf("YOU GOT THIS ERROR: " + newline + ME.message + newline + "ALL INDICES OF INPUT STRUCT MUST HAVE SAME FIELDS")
            else
                fprintf("YOU GOT THIS ERROR: " + newline + ME.message + newline)
            end
            out = {};
        end
    else
        fprintf(field + " IS NOT A FIELD IN INPUT STRUCT; OUTPUT FOR THIS INDEX (AND ANY NESTED INDEX) WILL BE AN EMPTY CELL" + newline)
        out = {};
    end
else
    if isfield(s, field)
        out = {s(idx).(field)};
    else
        fprintf(tmp + " IS NOT A FIELD IN INPUT STRUCT; OUTPUT AT THIS INDEX (AND ANY NESTED INDEX) WILL BE AN EMPTY CELL" + newline)
        out = {};
    end
end

end




function [field, idx] = getidx(field)

idx = ':';
if contains(field, '(')
    idx = regexp(field, '\(\d+\)$', 'match');
    if isscalar(idx)
        idx = idx{1};
        field = erase(field, idx);
        idx = str2double(erase(idx, {'(', ')'}));
    else
        error("noscalar index not properly formatted")
    end
end


end