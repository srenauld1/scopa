function stackin = stackclip(stackin, opt)

% clip outliers (can ignore zeros), rescale

arguments
    stackin
    opt.clip = [0 100] % (1,2) vector; bottom and top percentiles for clipping (adjusting contrast); to adjust contrast, this function rescales the image rather than adjusting image property CLim because    
    opt.rescale = 0 % 1 will rescale after clipping 
    opt.skipzero = 0 % 1 will ignore zeros in computing percentiles
    opt.pthpre = ''; % path for plot
    opt.doplt = 0 % 1 will do plot 
end
clip = opt.clip;
rescale = opt.rescale;
skipzero = opt.skipzero;
pthpre = opt.pthpre;
doplt = opt.doplt;


if skipzero
    idx = stackin~=0;
end

%apply optional input clipping to make the output stack
stackout = stackin;
if skipzero
    stackout(idx) = filloutliers(stackout(idx), 'clip', 'percentiles', clip); %do this after the stack averaging
    stackout(idx) = rescale(stackout(idx));
else
    stackout = filloutliers(stackout, 'clip', 'percentiles', clip); %do this after the stack averaging
    stackout = rescale(stackout);
end

if doplt %plot; sweep all integer clip percentiles from no clip ([0 100]) to input clip (bottom clip and top clip)

    if isempty(pthpre)
        pthpre = pthauto(suffix='.gif', usetime=1);
    end

    numdims_out = ndims(stackin);
    otherdims = repmat({':'},1,numdims_out);

    clipbottom_all = [0:clip(1)]; 
    cliptop_all = fliplr([clip(2):100]);
    outall = zeros([size(stackin) length(clipbottom_all)*length(cliptop_all)]);
    cnt = 0;
    for clipbot = clipbottom_all
        for cliptop = cliptop_all
            cnt = cnt+1;
            stackout = stackin;
            stackout(idx) = filloutliers(stackout(idx), 'clip', 'percentiles', [clipbot cliptop]); 
            if rescale
                stackout(idx) = rescale(stackout(idx));
            end
            outall(otherdims{:},cnt) = stackout;
        end
    end
    stackplt(outall, pthgif=[pthpre(1:end-4) '_contrastsweep_.gif'])

end
