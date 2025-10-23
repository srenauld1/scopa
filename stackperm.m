function [stack, dmstackout, sznew] = stackperm(stack, dmstackin, dmstackout)

% permute stack from dimension order dmstackin (char vector) to dmstackout (char vector); inserts singleton dims if necessary

arguments
    stack
    dmstackin %char vector, current stack dim order
    dmstackout = [] %char vector, new stack dim order (glbfile('dmstackdf') if empty)
end

if isempty(dmstackout)
    dmstackout = glbfile('dmstackdf');
    if isempty(dmstackout)
        error("must pass in dmstackout, or set glbfile('dmstackdf')")
    end
end
dmstackin = convertStringsToChars(dmstackin);
dmstackout = convertStringsToChars(dmstackout);

numdim = numel(dmstackin);

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
if numdim>numel(dmstackout)
    error("length of dmstackin cannot exceed length of dmstackout")
end

if ~isempty(dmstackin) && ~isequal(dmstackin, dmstackout(1:numdim))


    loc = zeros(1,numdim);
    for k = 1:numdim
        tmploc = strfind(dmstackout, dmstackin(k));
        if isempty(tmploc)
            error("you must have passed in a character in dmstackin that is not in dmstackout")
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

    sznewcell = num2cell(ones(numel(dmstackout), 1));
    for k = 1:numel(loc)
        sznewcell{loc(k)} = sz(k);
    end
    if ~isequal(vec(cell2mat(sznewcell)), sz(:))
        fprintf("reshaping stack with dimension order " + dmstackin + " into order " + dmstackout + newline)
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

    fprintf("not permuting stack because 'dmstackin' is empty, or matches 'dmstackout' for first ndims(stack) dimensions" + newline)

end
