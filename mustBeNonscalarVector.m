function mustBeNonscalarVector(x)

if isscalar(x) || ~isvector(x)
    error("must be nonscalar vector")
end

end