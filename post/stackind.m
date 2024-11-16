function [stack, ind, lab] = stackind(stack, ind, lab, dmstackdf)

arguments
    stack
    ind %char array, current stack dim order
    lab
    dmstackdf = [] %char array, default stack dim order (yxztck if empty)
end

if ~isempty(ind)

    if isempty(dmstackdf)
        dmstackdf = glb('dmstackdf');
        if isempty(dmstackdf)
            fprintf("using dmdf yxztck" + newline)
            dmstackdf = 'yxztck';
        end
    end
    maxnumdims = numel(dmstackdf);

    inddim = inputname(2);
    inddim = inddim(2);

    szin = ones(maxnumdims,1);
    if iscell(stack)
        if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
            error("all stacks (each cell element) must be the same size")
        end
        szintmp = size(stack{1}); %taking first cell because below code makes sure all stacks are same size, if multiple
    else
        szintmp = size(stack); %taking first cell because below code makes sure all stacks are same size, if multiple
    end
    szin(1:numel(szintmp)) = szintmp;

    dtmp = repmat({':'},1,maxnumdims);
    dim = strfind(dmstackdf, inddim);

    if numel(szintmp)<dim && ~isequal(ind,1) && ~isequal(ind,-1)
        error("you requested non-singular i" + inddim + " but stack is less than " + num2str(dim) + "dimensions")
    end
    ind = indsmake(ind, indsall=szin(dim));
    dtmp{dim} = ind;

    if iscell(stack)
        stack = cellfun(@(x) x(dtmp{:}), stack, 'UniformOutput', false);
    else
        stack = stack(dtmp{:});
    end
    lab{dim} = ind;

end


end