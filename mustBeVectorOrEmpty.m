function mustBeVectorOrEmpty(x)

if ~isempty(x) && ~isvector(x)
    error(inputname(1) + " must be empty or vector")
end

end