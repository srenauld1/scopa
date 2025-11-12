function y = istextall(x)

%check if input is nothing but text (char, or string, or cell of char or cell of string)

if ischar(x) || isstring(x) || ( iscell(x) && all(cellfun(@(y) isstring(y) | ischar(y), x, 'UniformOutput', 1)) )
    y = 1;
else
    y = 0;
end

end
