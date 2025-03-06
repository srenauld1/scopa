function s = structsort(s, opt)

arguments
    s %struct to be ordered 
    opt.vectype = []; %empty, row, or column; transpose any vector in s that is not vectype; skip if empty
    opt.nocells = 0; %convert char in cell to singleton char, convert char cell array to string array (to dismbiguate cell (which designates options for expansion) and string arrays, which get mixed up in jsonencode and jsondecode) 
end
vectype = opt.vectype;
nocells = opt.nocells;

if numel(s)>1
    for k = numel(s): -1 : 1 %for each element in nonscalar struct, backwards to preallocate
        [rind, cind] = ind2sub(size(s), k);
        tmp(rind, cind) = structsort(s(rind, cind), vectype=vectype, nocells=nocells);
    end
    s = tmp;
else
    fn = fieldnames(s);
    for k = 1:numel(fn)
        if isstruct(s.(fn{k}))
            s.(fn{k}) = structsort(s.(fn{k}), vectype=vectype, nocells=nocells);
        else
            if isscalar(s.(fn{k}))
                if nocells && iscell(s.(fn{k}))
                    s.(fn{k}) = s.(fn{k}){1}; %if nocells, remove from cell if scalar
                end
            else
                if nocells && iscell(s.(fn{k}))
                    if all(cellfun(@ischar,s.(fn{k})))
                        s.(fn{k}) = convertCharsToStrings(s.(fn{k})); %if nocells, make char cell array a string array
                    elseif all(cellfun(@isstring,s.(fn{k})))
                        s.(fn{k}) = string(s.(fn{k})); %if nocells, make string cell array a string array
                    else
                        error("nocell option is true, so no cells are allowed in struct except string and char, which are converted to string arrays")
                    end
                end
                if strcmp(opt.vectype,'row') && iscolumn(s.(fn{k}))
                    %fprintf("converting column vector " + fn{k} + " to row vector because vectype is row" + newline)
                    s.(fn{k}) = s.(fn{k}).';
                elseif strcmp(opt.vectype,'column') && isrow(s.(fn{k}))
                    %fprintf("converting row vector " + fn{k} + " to column vector because vectype is column" + newline)
                    s.(fn{k}) = s.(fn{k}).';
                end
            end
        end
    end
    s = orderfields(s, natsortrows(fieldnames(s))); %natural sorting; not the same as orderfields(structin);
end


