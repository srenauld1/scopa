function [stack, lab] = stackind(stack, inds, dmstackdf)

% this function is really only meant to be called from stackplt; it is too specific to its use there for use elsewhere; should probably be moved into stackplt as local function

arguments
    stack
    inds %struct of indices, fieldnames that will have effect are 'iy', 'ix', 'iz', 'it', 'ic', 'ik', by default any other fieldname is ignored (if you change dmstackdf, it will change these fieldnames accordingly)
    dmstackdf = [] %char array, default stack dim order (yxztck if empty)
end

if isempty(dmstackdf)
    dmstackdf = glb('dmstackdf');
    if isempty(dmstackdf)
        fprintf("using dmdf yxztck" + newline)
        dmstackdf = 'yxztck';
    end
end
maxnumdims = numel(dmstackdf);
valid_ind_fieldnames = strcat('i', cellstr(dmstackdf'));

lab = cell(maxnumdims,1);
szin = ones(maxnumdims,1);

fn = fieldnames(inds);

for k = 1:numel(fn)

    if any(strcmp(fn{k}, valid_ind_fieldnames))

        fnnm = fn{k};
        dmnm = fnnm(2);
        ind = inds.(fnnm);

        if ~isempty(ind)

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
            dim = strfind(dmstackdf, dmnm);

            if numel(szintmp)<dim && ~isequal(ind,1) && ~isequal(ind,-1)
                error("you requested non-singular " + fnnm + " but stack is less than " + num2str(dim) + " dimensions")
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

end


end