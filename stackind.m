function [stack, lab] = stackind(stack, dm, inds)

%index into stack using 

arguments (Input)
    stack
    dm %char array, default dim order for input variable stack
    inds %struct of indices; if dm = 'yxztck' validinds are 'iy', 'ix', 'iz', 'it', 'ic', 'ik'; other fieldnames will error
end

arguments (Output)
    stack % same as input variable stack, after indexing with inds
    lab % char representation of inds (for making labels)
end

maxnumdims = numel(dm);
validinds = strcat('i', cellstr(dm'));

lab = cell(maxnumdims,1);
szin = ones(maxnumdims,1);

dtmp = repmat({':'}, 1, maxnumdims);
fn = fieldnames(inds);
for k = 1:numel(fn)

    if any(strcmp(fn{k}, validinds))

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

            dim = strfind(dm, dmnm);

            if numel(szintmp)<dim && ~isequal(ind,1) && ~isequal(ind,-1)
                error("you requested non-singular " + fnnm + " but stack is less than " + num2str(dim) + " dimensions")
            end
            ind = vecsub(ind, superset=1:szin(dim));
            
            dtmp{dim} = ind;
            lab{dim} = ind;

        end
    end

end

if ~isequal(dtmp, repmat({':'}, 1, maxnumdims))
    if iscell(stack)
        stack = cellfun(@(x) x(dtmp{:}), stack, 'UniformOutput', false);
    else
        stack = stack(dtmp{:});
    end
end

end