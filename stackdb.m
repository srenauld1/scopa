function [stack, psfe] = stackdb(stack, opt)

%deblur stack; work in progress

arguments
    stack %yxzt image stack
    opt.doiso = 0 % 1 to resample stack into cube voxels before deblur, then put back to original size after
    opt.domnt = 0 % 1 to average all frames before optimizing deblur kernel then deblur all frames 
    opt.doet = 0 %1 to use edge taper
    opt.frac = 0.25 %deblur kernal size as fraction of xyz size 
    opt.itplt = 1 % frames to plot 
    opt.dmplt = 'yxz(t)' % dimensions to plot; default is yxz on each gif frame, and time across gif frames
    opt.doplt (1,1) {mustBeBinary} = 0 % 1 to plot results
    opt.widyxz = [] %width of voxel in yxz
end
doiso = opt.doiso;
domnt = opt.domnt;
doet = opt.doet;
frac = opt.frac;
itplt = opt.itplt;
dmplt = opt.dmplt;
doplt = opt.doplt;
widyxz = opt.widyxz;

if isequal(itplt,1) && ~isequal(size(stack,4),1)
    itplt = linspace(1,size(stack,4),20);
end

szpsf = round(size(stack, [1,2,3])*frac); %size of deblur kernel
psfi = ones(szpsf); %initialize deblur kernel with ones

stacktmp = stack(:,:,:,itplt); %set some frames of original blurred stack aside for optional plotting

if doiso
    if isempty(widyxz)
        error("widyxz cannot be empty if doiso is true")
    end
    stack = stackiso(stack,widyxz,dir='for'); %resample stack into cube voxels (forward direction)
end

if domnt
    [stackmntdb_init, psfe_init] = deconvblind(mean(stack,4),psfi); %matlab deblur function, apply to mean of all frames
    psfi = psfe_init; %use deblur kernel to initialize deblur optimization for each frame below
end

if doet
    stack = edgetaper(stack,psfi); %apply edge tapering to reduce deblur ringing at edges
end

for k = 1:size(stack,4)
    [stack(:,:,:,k), psfe] = deconvblind(stack(:,:,:,k),psfi); %matlab deblur function, apply to each frame
end

if doiso
    stack = stackiso(stack,widyxz,dir='rev'); %resample stack into original size (reverse direction)
end

if doplt
    stacktmpdb = stack(:,:,:,itplt); %set some frames aside from deblurred stack for optional plotting
    dmplt_no_t = erase(dmplt, {'(',')','t'});
    if ~isequal(dmplt,dmplt_no_t)
        stackplt({stacktmp;stacktmpdb}, dmplt=erase(dmplt_no_t, 't')) %plot
    end
    stackplt({stacktmp;stacktmpdb}, dmplt=dmplt) %plot
end

end
