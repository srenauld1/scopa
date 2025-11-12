function mustBeUnique(x)

if ~isequal(numel(x), numel(unique(x)))
    error("cannot have any repeated elements")
end
