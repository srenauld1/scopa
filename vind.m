function [v, lab] = vind(v, dm, inds)

arguments (Input)
    v
    dm %char array, default dim order for input variable v
    inds %struct of indices; if dm = 'yxztck' (eg if v is stack), validinds are 'iy', 'ix', 'iz', 'it', 'ic', 'ik'; other fieldnames will error
end

arguments (Output)
    v % same as input variable v, after indexing with inds
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

            if iscell(v)
                if ~all(cellfun(@(e) isequal(size(v{1}), size(e)), v(2:end)))
                    error("all stacks (each cell element) must be the same size")
                end
                szintmp = size(v{1}); %taking first cell because below code makes sure all stacks are same size, if multiple
            else
                szintmp = size(v); %taking first cell because below code makes sure all stacks are same size, if multiple
            end
            szin(1:numel(szintmp)) = szintmp;

            dim = strfind(dm, dmnm);

            if numel(szintmp)<dim && ~isequal(ind,1) && ~isequal(ind,-1)
                error("you requested non-singular " + fnnm + " but stack is less than " + num2str(dim) + " dimensions")
            end
            ind = indsmake(ind, indsall=szin(dim));
            
            dtmp{dim} = ind;
            lab{dim} = ind;

        end
    end

end

if iscell(v)
    v = cellfun(@(x) x(dtmp{:}), v, 'UniformOutput', false);
else
    v = v(dtmp{:});
end

end