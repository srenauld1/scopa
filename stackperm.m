function [stack, dmstackdf, sznew] = stackperm(stack, dmstack, dmstackdf)

% put stack into default dimension order, given current order dmstack, and default order dmstackdf; inserts singleton dims if necessary

arguments
    stack
    dmstack %char array, current stack dim order
    dmstackdf = 'yxztck' %char array, default stack dim order (yxztck if empty)
end

dmstack = convertStringsToChars(dmstack);
dmstackdf = convertStringsToChars(dmstackdf);

numdim = numel(dmstack);

if iscell(stack)
    if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
        error("all stacks (each cell element) must be the same size")
    end
    sz = size(stack{1}); %taking first cell because code above makes sure all stacks are same size, if multiple
else
    sz = size(stack); 
end

if numdim>0 && numdim~=numel(sz)
    error("dm length must match ndims(stack)")
end
if numdim>numel(dmstackdf)
    error("length of dmstack cannot exceed length of dmstackdf")
end

if ~isempty(dmstack) && ~isequal(dmstack, dmstackdf(1:numdim))


    loc = zeros(1,numdim);
    for k = 1:numdim
        tmploc = strfind(dmstackdf, dmstack(k));
        if isempty(tmploc)
            error("you must have passed in a character in dmstack that is not in dmstackdf")
        else
            loc(k) = tmploc;
        end
    end
    if numel(unique(loc))~=numel(loc)
        error("there cannot be repeated dm")
    end
    if ~all(loc)
        error("loc must not have any zeros")
    end

    [~, ordnew] = sort(loc);

    sznewcell = num2cell(ones(numel(dmstackdf), 1));
    for k = 1:numel(loc)
        sznewcell{loc(k)} = sz(k);
    end
    if ~isequal(vec(cell2mat(sznewcell)), sz(:))
        fprintf("reshaping stack with dimension order " + dmstack + " into order " + dmstackdf + newline)
        if iscell(stack)
            for k = 1:numel(stack)
                stack{k} = permute(stack{k}, ordnew);
                stack{k} = reshape(stack{k}, sznewcell{:});
            end
            sznew = size(stack{1}); %taking size of first cell because above code already makes sure all stacks are same size, if multiple
        else
            stack = permute(stack, ordnew);
            stack = reshape(stack, sznewcell{:});
            sznew = size(stack);
        end
        fprintf("new size is " + mat2str(sznew) + newline)
    end


else

    fprintf("not permuting stack because 'dmstack' is empty, or matches 'dmstackdf' for first ndims(stack) dimensions" + newline)

end
