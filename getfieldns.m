function out = getfieldns(s,field)

% get field values in nonscalar struct
% all indices of s must have same fields
% inputs s and field can be nested (for struct a.b.c.d, field might be b.c.d . . . any and all levels can be nonscalar)
% out is equivalent to the requested fields if s were flattened
% structure of nonscalar structs is lost in the output, except their order

tmp = strsplit(field, '.');

if numel(tmp)>1
    tmp1 = tmp{1};
    % if strcmp(tmp1, '*')
    %     tmp1 = fieldnames(s);
    % end
    tmp2 = strjoin(tmp(2:end), '.');
    if isfield(s, tmp1)
        try
            out = getfieldns([s.(tmp1)],tmp2);
        catch ME
            if contains(ME.message, 'Concatenation of structure arrays requires that these arrays have the same set of fields')
                fprintf("YOU GOT THIS ERROR: " + newline + ME.message + newline + "ALL INDICES OF INPUT STRUCT MUST HAVE SAME FIELDS")
            else
                fprintf("YOU GOT THIS ERROR: " + newline + ME.message + newline)
            end
            out = {};
        end
    else
        fprintf(tmp1 + " IS NOT A FIELD IN INPUT STRUCT; OUTPUT FOR THIS INDEX (AND ANY NESTED INDEX) WILL BE AN EMPTY CELL" + newline)
        out = {};
    end
else
    if isfield(s, tmp)
        out = {s.(field)};
    else
        fprintf(tmp + " IS NOT A FIELD IN INPUT STRUCT; OUTPUT AT THIS INDEX (AND ANY NESTED INDEX) WILL BE AN EMPTY CELL" + newline)
        out = {};
    end
end

end
