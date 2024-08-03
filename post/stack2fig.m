function stack2fig(stack, fngif, gif_visibility, roipixind, roiinds, roi_colors, roialpha, cmap, display_range, framenumdims, dimorder, title_prefix, index_labels, figsidelength, axord, numcolorsgif)

%alphamapping is not yet an option

arguments
    stack %image stack(s), matrix if single stack, cell if multiple; if cell, must be same size; stack dimensions assumed to be (y,x,z,t,pmtchannel,colorchannel); can be any data type; if passing cmap, stack scaled to colormap range; if no cmap, assumed to be rgb
    fngif char = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'))
    gif_visibility char = 'on'
    roipixind = []
    roiinds = []
    roi_colors = [1 0 0]
    roialpha = 0.3
    cmap double = gray(256) %colormap or 'rgb' if stack is truecolor (final dim length 3 . . . can be any numeric type)
    display_range = [0,1] %[low,high] for image property CLim (contrast); ignored if stack is RGB
    framenumdims = 2 %how many dims to display on a each frame
    dimorder = 1:numel(size(stack)) %dim order from left to right, top to bottom, first to last frame (y,x,z,t,pmt,colorchannel)
    title_prefix char = ''
    index_labels cell = {} %ids for the indices represented by stack, each cell corresponds to each dim of stack, and must match in length
    figsidelength double = 0.75 %figure size as proportion of your available screen small dimension (cannot find the available size of your monitor bc it is not same as full size, so to be safe, keep this under 0.75 to prevent overfilling / causing nonsquare aspect)
    axord char = 'rowmajor'
    numcolorsgif double = 128
end

clear make_roi_overlay %to clear the persistent variable within

if strcmp(cmap, 'rgb')
    error("don't pass truecolor stack yet, testing still")
end

%% check vars

dimlabels = vec(num2cell('yxztpc'));
fontmedium = 10;
maxnumdims = 6;
margins_fig = 0.05;
margins_subplot = 0;
max_num_inds_to_print = 20;
max_num_im_per_frame = 60;

if ~iscell(display_range)
    if numel(display_range)~=2
        error("display range must be a cell of 2-element vectors or a 2-element vector")
    end
    display_range = {display_range};
end

if any(vec(cell2mat(cellfun(@(x) x<0 | x>1 , display_range, 'UniformOutput', false))))
    error("display_range must be in range 0-1")
end

if any(cell2mat(cellfun(@(x) x(1)>x(2) , display_range, 'UniformOutput', false)))
    error("display_range(1) must be less than display_range(2)")
end

if iscell(stack)
    if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
        error("all stacks (each cell element) must be same size")
    end
    if numel(stack)~=1 && ~isempty(roipixind)
        error("cannot currently plot roi overlay on multi-stack image")
    end
    if numel(display_range)~=1 && numel(display_range)~=numel(stack)
        error("display_range length must be 1, or match number of stacks")
    end
    if numel(display_range)==1
        display_range = repmat(display_range, [numel(stack) 1]);
    end

    for si = 1:numel(stack) %if you are combining multiple stacks, rescale them to apply the display range, and make [0 1] new display_range (CLim)
        stackmin = double(min(stack{si}(:)));
        stackmax = double(max(stack{si}(:)));
        stackrange = stackmax-stackmin; %(max-min)*display_range+min = [0 1]

        if stackmin<0
            error("need to fix rescaling for negative stack")
        end
        rsa = [display_range{si}(1) 1-display_range{si}(1); %display_range{si}(1)*newmax - display_range{si}(1)*newmin + newmin = 0;
            display_range{si}(2) 1-display_range{si}(2)]; %display_range{si}(2)*newmax - display_range{si}(2)*newmin + newmin = 1;
        rsb = [0;1];
        rstmp = mldivide(rsa, rsb); %two equations two unknowns 
        newmax = rstmp(1);
        newmin = rstmp(2);
        stack{si} = newmin + ((stack{si} - stackmin) / stackrange)*(newmax-newmin);
    end

    clim_tmp = [0 1]; %clim is [0 1] since stacks got rescaled 
    stack = cell2mat(stack(:)); %convert to mat and cat multiple stacks along first dim
else %if there's only one stack, don't rescale it, just assign display_range to CLim 
    if numel(display_range)~=1
        error("display_range length must be 1 if one stack is passed as argument")
    end
    stackmin = double(min(stack(:)));
    stackmax = double(max(stack(:)));
    if stackmin<0
        error("need to fix rescaling for negative stack")
    end
    stackrange = stackmax-stackmin;
    clim_tmp = stackrange*display_range+stackmin;
end


if isempty(roipixind)
    roi_loop_size = 1;
    if isempty(roiinds)
        roi_message = ', roi-NaN';
    else
        roi_message = ', roi-not plotting roi without pixinds roi argument';
    end
else
    if ~iscell(roipixind)
        if isvector(roipixind)
            roipixind = {roipixind};
        else
            error("roipixind must be cell, or vector")
        end
    end
    if numel(size(stack))>3
        error("you passed roipixind as argument; to plot roi overlay, pass stack xyz only; do not include any additional dimensions (t, p, or c)")
    end
    if isempty(roiinds)
        roiinds = 1:numel(roipixind);
        roi_loop_size = numel(roipixind);
    else
        roi_loop_size = numel(roiinds);
    end
end

if size(roi_colors, 1)==1
    roi_colors = repmat(roi_colors, [roi_loop_size 1]);
end


numdims = ndims(stack);
szo = size(stack);
num_missing_dims = maxnumdims-numdims;

if numdims>maxnumdims
    error("max numdims is 6 (y,x,z,t,pmtchannel,colorchannel) ")
end

if strcmp(cmap, 'rgb') && size(stack, numdims)~=3
    error("last dimension must be length 3 if cmap argument is 'rgb'")
end

if framenumdims>numdims
    error("framenumdims must not exceed numdims")
end
if ~isequal(sort(dimorder), 1:numdims)
    error("dimorder must contain all integers 1 to numdims")
end

if isempty(index_labels)
    index_labels = arrayfun(@(x) 1:x(end), size(stack), 'UniformOutput', false);
end

if numel(index_labels)~=numdims
    error("index_label length must match numdims")
end


%% prep images

dimorder = [dimorder [1:num_missing_dims]+numel(dimorder)];
stack = permute(stack, dimorder);
dimlabels = dimlabels(dimorder);
index_labels = cat(1, index_labels(:), repelem({[nan]}, num_missing_dims, 1));
index_labels = index_labels(dimorder);
sztmp = size(stack);
sz_framedims = sztmp(1:framenumdims);
sz_framedims = num2cell([sz_framedims(1:2) prod(sz_framedims(3:framenumdims))]);
stack = reshape(stack, sz_framedims{:}, []); %collapse framenumdims into 3d (possible singleton 3rd dim), keep them separate, collapse remaining dims into last dim

numxpix = size(stack,2);
numypix = size(stack,1);
numim_per_frame = size(stack,3); %after reshaping, size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if framenumdims==2)
numframes = size(stack,4); %after reshaping, size of 4th dim is number gif frames
dummyim = nan(numypix, numxpix);
dummyim_rgb = nan(numypix, numxpix, 3);


if numim_per_frame>max_num_im_per_frame
    error(sprintf("you are attempting to plot " + num2str(numim_per_frame) + " images per frame, which exceeds the default max of " + num2str(max_num_im_per_frame)))
end

%% prep titles

dr_str = vec(cellfun(@num2str, display_range, 'UniformOutput', false))';
dr_str = cellfun(@(x,y,z) regexprep(x,y,z), dr_str, repelem({' +'}, numel(dr_str)), repelem({'to'}, numel(dr_str)), 'UniformOutput', false);
dr_str = cellfun(@(x,y,z) strrep(x,y,z), dr_str, repelem({'.'}, numel(dr_str)), repelem({'p'}, numel(dr_str)), 'UniformOutput', false);
dr_str = ['dr-' strjoin(dr_str, ',')];

lab_framestable = {dr_str};
index_labels_tmp = index_labels(1:framenumdims); %labels that are the same on every frame
for li = 1:numel(index_labels_tmp)
    [~, index_labels_tmp{li}] = make_plot_inds(index_labels_tmp{li}, index_labels_tmp{li}, dimlabels{li}, max_num_inds_to_print);
end
lab_framestable = cat(1, lab_framestable, index_labels_tmp);
dims_changing_across_frames = framenumdims+1:maxnumdims;
lab_framechange = index_labels(dims_changing_across_frames); %labels that can change on each frame
lab_framechange_numel = cellfun(@numel, lab_framechange);

framecount = 0;
for ri = 1:roi_loop_size % loop over all rois, or if none, roi_loop_size is 1
    if isempty(roipixind)
        roinum_title = roi_message;
    else
        roinum_title = [', roi-' num2str(roiinds(ri))];
    end
    for k = 1:numframes
        framecount = framecount+1;
        [i1,i2,i3,i4,i5,i6]=ind2sub(lab_framechange_numel(:)', k); %subscript of frame in all possible dimensions
        subtmp = [i1,i2,i3,i4,i5,i6];
        subtmp = subtmp(1:numel(lab_framechange));
        labtmp = cellfun(@(x,y) x(y), lab_framechange, num2cell(subtmp(:)), 'UniformOutput', false); %frame changing part of label
        labtmp = cellfun(@num2str, labtmp, 'UniformOutput', false);
        labtmp = cellfun(@horzcat, dimlabels(dims_changing_across_frames), repelem({'-'}, size(labtmp,1), 1), labtmp, 'UniformOutput', false); %frame changing part of label
        titlesuffix = cat(1, lab_framestable(:), labtmp(:));
        titlesuffix = strjoin(titlesuffix, ', ');
        titlesuffix = [titlesuffix roinum_title];
        titlenew{framecount} = {strrep(title_prefix, '_', ' '); titlesuffix};
    end
end

%% init subplots

ax = arrange_subplots(stack, margins_subplot, margins_fig);

hfg = figure;
aspect_screen = hfg.Parent.ScreenSize(3) / hfg.Parent.ScreenSize(4); %get screen aspect ratio
close(hfg)

hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', gif_visibility, 'Position', [0, 0, 1, 1]);
if aspect_screen>1
    hfg.Position = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
else
    hfg.Position = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
end

haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
htx = text( haxmain, 0.5, 0.99, '', 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );


for j = 1:numim_per_frame

    hax{j} = axes( 'Parent', hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition' );
    hax{j}.InnerPosition(1) = ax.(axord).xp(j);
    hax{j}.InnerPosition(2) = ax.(axord).yp(j);
    hax{j}.InnerPosition(3) = ax.xe(1);
    hax{j}.InnerPosition(4) = ax.ye(1);
    hax{j}.DataAspectRatio = [1 1 1]; %don't think this is necessary
    hax{j}.XLim = [1 numxpix];
    hax{j}.YLim = [1 numypix];
    hax{j}.CLim = clim_tmp;
    colormap(hax{j}, cmap);
    axis off
    axis ij

    hold(hax{j}, 'on')
    hpl{j} = image(hax{j}, 'CData', dummyim); %dummy_index_dim5=1 will work to initialize for roi_type pixel and roi
    hpl{j}.CDataMapping = 'scaled'; %this way, full range of any data type will be mapped to cmap range
    hol{j} = image(hax{j}, 'CData', dummyim_rgb, 'AlphaData', dummyim);
    hold(hax{j}, 'off')

end

%% plot

framecount = 0;
for ri = 1:roi_loop_size % loop over all rois, or if none, roi_loop_size is 1
    if ~isempty(roipixind)
        [imroi, imalpha] = make_roi_overlay(stack, roipixind{roiinds(ri)}, roi_colors(ri,:), roialpha); %make an overlay for one roi
    end
    for k = 1:numframes %for each figure/gif frame, which is collapsed dimensions after framenumdims
        framecount = framecount+1;
        for j = 1:numim_per_frame %size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if framenumdims==2)

            hpl{j}.CData = stack(:,:,j,k);
            if ~isempty(roipixind) %&& k==1 %if there are roi variables
                hol{j}.CData = squeeze(imroi(:,:,j,k,:)); %squeeze to make it 3d (2d plus color channel)
                hol{j}.AlphaData = imalpha(:,:,j,k);
            end

        end

        htx.String = titlenew{framecount};

        fig2gif(hfg, framecount, fngif, numcolorsgif)

    end

end

clear make_roi_overlay %to clear the persistent variable within

end

