function [stack, lab] = stackind(stack, opt)

%index into stack using indices naqmed after stack dimensions, relative to dm (named stack dimensions)

arguments (Input)
    stack
    opt.dm = [] %char array, default dim order for input variable stack
    opt.iy = [] 
    opt.ix = [] 
    opt.iz = [] 
    opt.it = [] 
    opt.ic = [] 
    opt.ik = [] 
end
arguments (Output)
    stack % same as input variable stack, after indexing with inds
    lab % cell of inds (for making labels)
end

dm = opt.dm;
opt = rmfield(opt, 'dm');

maxnumdims = numel(dm);

if iscell(stack)
    if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
        error("all stacks (each cell element) must be the same size")
    end
    szintmp = size(stack{1}); %taking first cell because below code makes sure all stacks are same size, if multiple
else
    szintmp = size(stack); %taking first cell because below code makes sure all stacks are same size, if multiple
end
if numel(szintmp)>maxnumdims
    error("ndims(stack) cannot exceed numel(dm)")
end
szin = ones(maxnumdims,1);
szin(1:numel(szintmp)) = szintmp;

validinds = strcat('i', cellstr(dm'));

lab = cell(maxnumdims,1);

dtmp = repmat({':'}, 1, maxnumdims);
fn = fieldnames(opt);
for k = 1:numel(fn)

    if any(strcmp(fn{k}, validinds))

        ind = opt.(fn{k});
        dim = strfind(dm, fn{k}(2));

        if isempty(ind)

            lab{dim} = 1:szin(dim);

        else

            if numel(szintmp)<dim && ~isequal(ind,1) && ~isequal(ind,-1)
                error("you requested non-singular " + fn{k} + " but stack is less than " + num2str(dim) + " dimensions")
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