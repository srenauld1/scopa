function mustBeAllInt(x, emptyflag)

%check that all elements of input are integer-valued (of any numeric class); cell will error

emptyok = 0;
if exist('emptyflag', 'var')
    if strcmp(emptyflag, 'emptyok')
        emptyok = 1;
    else
        error("second positional argument must be omitted or be 'emptyok'")
    end
end

if ~emptyok && isempty(x) || any(mod(x,1)~=0)
    error("all elements of must be integer")
end