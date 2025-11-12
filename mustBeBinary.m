function mustBeBinary(x, emptyflag)

%check that all elements of input are 0s and 1s (of any numeric class); cell will error

emptyok = 0;
if exist('emptyflag', 'var')
    if strcmp(emptyflag, 'emptyok')
        emptyok = 1;
    else
        error("second positional argument must be omitted or be 'emptyok'")
    end
end

if ~emptyok && isempty(x)
    error("must be nonempty (to allow empty, set emptyflag to 'emptyok')")
end
if any(x~=0 & x~=1, 'all')
    error("must only contain 0s and 1s")
end
