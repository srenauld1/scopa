function stackmn(stack, numdimout)

% average trailing dimensions of stack until ndims(stack)=numdimout; maintains data type

arguments
    stack
    numdimout = 2
end

numdimin = ndims(stack);
for i = 1:abs(numdimout-numdimin)
    numdimin = ndims(stack);
    if numdimin~=numdimout 
        stack = mean( stack, numdimin, 'native');
    end
end