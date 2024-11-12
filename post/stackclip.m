function stack = stackclip(stack, opt)

% clip outliers (can ignore zeros), rescale

arguments
    stack
    opt.clip = [0 100] % (1,2) vector; bottom and top percentiles for clipping (adjusting contrast); to adjust contrast, this function rescales the image rather than adjusting image property CLim because    
    opt.rs = 0 % 1 will rescale after clipping 
    opt.skipzero = 0 % 1 will ignore zeros in computing percentiles
    opt.pthpre = ''; % path for plot
    opt.doplt = 0 % 1 will do plot; requires double memory
end
clip = opt.clip;
rs = opt.rs;
skipzero = opt.skipzero;
pthpre = opt.pthpre;
doplt = opt.doplt;

if skipzero
    idx = stack~=0;
end

if skipzero
    stack(idx) = filloutliers(stack(idx), 'clip', 'percentiles', clip); %do this after the stack averaging
    stack(idx) = rescale(stack(idx));
else
    stack = filloutliers(stack, 'clip', 'percentiles', clip); %do this after the stack averaging
    stack = rescale(stack);
end

if doplt %plot; sweep all integer clip percentiles from no clip ([0 100]) to input clip (bottom clip and top clip)

    if isempty(pthpre)
        pthpre = pthauto(suffix='.gif', usetime=1);
    end

    numdims_out = ndims(stack);
    otherdims = repmat({':'},1,numdims_out);

    clipbottom_all = [0:clip(1)]; 
    cliptop_all = fliplr([clip(2):100]);
    outall = zeros([size(stack) length(clipbottom_all)*length(cliptop_all)]);
    cnt = 0;
    for clipbot = clipbottom_all
        for cliptop = cliptop_all
            cnt = cnt+1;
            stackout = stack;
            stackout(idx) = filloutliers(stackout(idx), 'clip', 'percentiles', [clipbot cliptop]); 
            if rs
                stackout(idx) = rescale(stackout(idx));
            end
            outall(otherdims{:},cnt) = stackout;
        end
    end
    stackplt(outall, pthgif=[pthpre(1:end-4) '_contrastsweep_.gif'])

end
