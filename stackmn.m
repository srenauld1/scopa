function stack = stackmn(stack, opt)

% average trailing dimensions of stack until ndims(stack)=numdimout; maintains data type

arguments
    stack
    opt.numdimout = 2
end
numdimout = opt.numdimout;

numdimin = ndims(stack);
for i = 1:abs(numdimout-numdimin)
    numdimin = ndims(stack);
    if numdimin~=numdimout 
        stack = mean( stack, numdimin, 'native');
    end
end