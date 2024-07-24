function stackout = process_stack_for_roi_selection(stackin, numdim_out, clip_prctile, scalefac, ignore_zeros, pth_stack)

% average stack, clip outliers, rescale, 
% can ignore zeros
% all of this is optional, depends on input

if ~exist('ignore_zeros', 'var')
    ignore_zeros = 1;
end

%take mean of trailing dims until reaching numdim_out
numdim_in = ndims(stackin);
for i = 1:abs(numdim_out-numdim_in)
    numdim_in = ndims(stackin);
    if numdim_in~=numdim_out %in case there's a trailing singleton dim that disappears
        stackin = mean( stackin, numdim_in );
    end
end

%apply input clipping to make the output stack
stackout = stackin;
if ignore_zeros
    idx = stackout~=0;
    stackout(idx) = filloutliers(stackout(idx), 'clip', 'percentiles', clip_prctile); %do this after the time averaging
    stackout(idx) = rescale(stackout(idx), 0, scalefac);
else
    stackout = filloutliers(stackout, 'clip', 'percentiles', clip_prctile); %do this after the time averaging
    stackout = rescale(stackout, 0, scalefac);
end

if ~isempty(pth_stack)

    %plot the clipped stack 
    stack2fig(stackout, [pth_stack(1:end-4) '_chosencontrastforROIdraw_.gif'])


    numdims_out = ndims(stackin);
    otherdims = repmat({':'},1,numdims_out);

    %for visualization, sweep all possible clip percentiles from no clip to input clip (bottom and top) 
    idx = stackin~=0; %in case there was a mask applied we want to ignore outside
    clipbottom_all = [0:clip_prctile(1)]; %
    cliptop_all = fliplr([clip_prctile(2):100]);
    outall = zeros([size(stackin) length(clipbottom_all)*length(cliptop_all)]);
    countz = 0;
    for clipbot = clipbottom_all
        for cliptop = cliptop_all
            countz = countz+1;
            stackout = stackin;
            stackout(idx) = filloutliers(stackout(idx), 'clip', 'percentiles', [clipbot cliptop]); %do this after the time averaging
            stackout(idx) = rescale(stackout(idx), 0, scalefac);
            outall(otherdims{:},countz) = stackout;
        end
    end
    stack2fig(outall, [pth_stack(1:end-4) '_contrastsweep_.gif'])

end
