function mustBeVectorOrEmpty(x)

if ~isempty(x) && ~isvector(x)
    error("must be empty or vector")
end

end