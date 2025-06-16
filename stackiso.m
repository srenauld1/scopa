function [stacknew, upfac] = stackiso(stack, widyxz, mthd)

%resize stack to have cube voxels (equal size in y,x,z), assumes yxztc dimension order 

arguments
    stack
    widyxz
    mthd = []
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

widmin = min(widyxz);
upfac = widyxz / widmin;
sz = size(stack, [1,2,3]);
szup = round(sz.*upfac);

stacknew = zeros([szup, size(stack,4), size(stack,5)], class(stack));
for c = 1:size(stack,5)
    for k = 1:size(stack,4)
        stacknew(:,:,:,k,c) = imresize3(stack(:,:,:,k,c), szup, mthd);
    end
end

end
