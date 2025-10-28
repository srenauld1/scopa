function mustBeBinary(x)

if any(x ~= 0 | x ~= 1, 'all')
    error("must only contain 0s and 1s")
end