function mustBeUnique(x)

if ~isequal(numel(x), numel(unique(x)))
    error("all elements must be unique")
end
