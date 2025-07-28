function out = structfield(s,inp)

%{

get field values in nonscalar struct
all indices of s must have same fields
inputs s and field can be nested (for struct a.b.c.d, field might be b.c.d . . . any and all levels can be nonscalar)
out is equivalent to the requested fields if s were flattened
structure of nonscalar structs is lost in the output, except their order
%}

arguments
    s
    inp
end

% use structind from glb to format field and index then getfield like this
%         sind = structind(inp);
%         out = getfield(gset, sind{:});

tmp = strsplit(inp, '.');
fld = tmp{1};
[fld, idx] = getidx(fld);
if numel(tmp)>1
    % if strcmp(fld, '*')
    %     fld = fieldnames(s);
    % end
    suffix = strjoin(tmp(2:end), '.');
    if isfield(s, fld)
        try
            out = structfield([s.(fld)(idx)],suffix);
        catch ME
            if contains(ME.message, 'Concatenation of structure arrays requires that these arrays have the same set of fields')
                fprintf("YOU GOT THIS ERROR: " + newline + ME.message + newline + "ALL INDICES OF INPUT STRUCT MUST HAVE SAME FIELDS")
            else
                fprintf("YOU GOT THIS ERROR: " + newline + ME.message + newline)
            end
            out = {};
        end
    else
        fprintf(fld + " IS NOT A FIELD IN INPUT STRUCT; OUTPUT FOR THIS INDEX (AND ANY NESTED INDEX) WILL BE AN EMPTY CELL" + newline)
        out = {};
    end
else
    if isfield(s, fld)
        out = {s.(fld)(idx)};
        % sind = structind(inp);
        % out = getfield(gset, sind{:});
    else
        fprintf(tmp + " IS NOT A FIELD IN INPUT STRUCT; OUTPUT AT THIS INDEX (AND ANY NESTED INDEX) WILL BE AN EMPTY CELL" + newline)
        out = {};
    end
end

end



function [fld, idx] = getidx(fld)

idx = ':';
if contains(fld, '(')
    idx = regexp(fld, '\(\d+\)$', 'match');
    if isscalar(idx)
        idx = idx{1};
        fld = erase(fld, idx);
        idx = str2double(erase(idx, {'(', ')'}));
    else
        error("noscalar index not properly formatted")
    end
end


end