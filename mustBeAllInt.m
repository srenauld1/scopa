function mustBeAllInt(x)

%check that all elements of input are integer-valued (of any numeric class); cell will error 

if isempty(x) || any(mod(x,1)~=0)
    error(inputname(1) + " must be scalar integer")
end