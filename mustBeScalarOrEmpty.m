function mustBeScalarOrEmpty(x)

if ~isempty(x) && ~isscalar(x)
    error("must be empty or scalar")
end

end