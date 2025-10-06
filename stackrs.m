function stackout = stackrs(stack, yxznew, opt)

arguments
    stack
    yxznew = [] %new size order yxz (empty if passing in 'like')
    opt.method = 'linear'
    opt.like = [] %stack to make size match 
end
method = opt.method;
like = opt.like;

if ndims(stack)<2 || ndims(stack)>6
    error("stack must be greater than 2d-6d")
end
if isempty(like)
    if isempty(yxznew)
        error("must pass in yxznew or name-value argument 'like'")
    end
else
    if isempty(yxznew)
        yxznew = size(like, 1:3);
    else
        error("cannot pass in yxznew and name-value argument 'like'")
    end
end
if ~isvector(yxznew) || numel(yxznew)~=2 && numel(yxznew)~=3
    error("new size must be vector length length 2 or 3")
end
yxznew = yxznew(:)';
if numel(yxznew)==2
    yxznew = [yxznew 1];
end

if isequal(yxznew, size(stack, [1 2 3]))
    stackout = stack;
else
    stackout = zeros([yxznew, size(stack,4), size(stack,5), size(stack,6)], class(stack));
    for c = 1:size(stackout,5)
        for t = 1:size(stackout,4)
            if size(stack,3)>1
                stackout(:,:,:,t,c) = imresize3(stack(:,:,:,t,c), yxznew, method);
            else
                stackout(:,:,:,t,c) = imresize(stack(:,:,:,t,c), yxznew, method);
            end
        end
    end
end

end