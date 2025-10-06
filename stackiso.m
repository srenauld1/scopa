function [stacknew, upfac] = stackiso(stack, widyxz, mthd, opt)

%resize stack to have cube voxels (equal size in y,x,z), assumes yxztc dimension order 

arguments
    stack
    widyxz
    mthd = []
    opt.dir = []
end
dir = opt.dir;

if isempty(dir)
    dir = 'for';
end
if ~ismember(dir, {'for', 'rev'})
    error("dir must be for or rev")
end
if isempty(mthd)
    mthd = 'linear';
end

if ndims(stack)<3
    error("in stackiso, stack must be volumetric (for now)")
end
if ndims(stack)>5
    error("in stackiso, stack cannot have more than 5 dimensions")
end


sz = size(stack, [1,2,3]);
widmin = min(widyxz);
upfac = widyxz / widmin;

if strcmp(dir, 'for')
    sznew = round(sz.*upfac);
elseif strcmp(dir, 'rev')
    sznew = round(sz./upfac);
end

stacknew = zeros([sznew, size(stack,4), size(stack,5)], class(stack));
for c = 1:size(stack,5)
    for k = 1:size(stack,4)
        stacknew(:,:,:,k,c) = imresize3(stack(:,:,:,k,c), sznew, mthd);
    end
end

end
