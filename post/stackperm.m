function [stack, dmstackdf, sznew] = stackperm(stack, dmstack, dmstackdf)

% put stack into default dimension order, given current order dmstack, and default order dmstackdf; inserts singleton dims if necessary

arguments
    stack
    dmstack %char array, current stack dim order
    dmstackdf = [] %char array, default stack dim order (yxztck if empty)
end

if isempty(dmstackdf)
    dmstackdf = glb('dmstackdf');
    if isempty(dmstackdf)
        fprintf("using dmdf yxztck" + newline)
        dmstackdf = 'yxztck';
    end
end

if ~isempty(dmstack) && ~isequal(dmstack, dmstackdf)

    if iscell(stack)
        if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
            error("all stacks (each cell element) must be the same size")
        end
        sz = size(stack{1}); %taking first cell because below code makes sure all stacks are same size, if multiple
    else
        sz = size(stack); %taking first cell because below code makes sure all stacks are same size, if multiple
    end


    if isequal(dmstack, dmstackdf)
        dmstack = dmstackdf(1:numel(sz));
    end
    if numel(dmstack)~=numel(sz)
        error("dm length must match ndims(stack)")
    end
    if isempty(dmstack)
        dmstack = dmstackdf;
    end
    for k = 1:numel(dmstack)
        loc(k) = strfind(dmstackdf, dmstack(k));
    end

    [~, ordnew] = sort(loc);

    sznewcell = num2cell(ones(numel(dmstackdf), 1));
    if numel(unique(loc))~=numel(loc)
        error("there cannot be repeated dm")
    end
    for k = 1:numel(loc)
        sznewcell{loc(k)} = sz(k);
    end
    if ~isequal(vec(cell2mat(sznewcell)), sz(:))
        fprintf("reshaping stack with dimension order " + dmstack + " into order " + dmstackdf + newline)
        if iscell(stack)
            for k = 1:numel(stack)
                stack = permute(stack{k}, ordnew);
                stack{k} = reshape(stack{k}, sznewcell{:});
            end
            sznew = size(stack{1}); %taking first cell because below code makes sure all stacks are same size, if multiple
        else
            stack = permute(stack, ordnew);
            stack = reshape(stack, sznewcell{:});
            sznew = size(stack); %taking first cell because below code makes sure all stacks are same size, if multiple
        end
        fprintf("new size is " + mat2str(sznew) + newline)
    end



end
