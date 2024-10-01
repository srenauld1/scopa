function stack2fig(stack, opt)

%alphamapping is not yet an option

arguments
    stack %image stack(s), matrix if single stack, cell if multiple; if cell, must be same size; stack dimensions assumed to be (y,x,z,t,c,j); can be any data type; if passing cmap, stack scaled to colormap range; if no cmap, assumed to be rgb
    opt.pthgif char = ''
    opt.gif_visibility char = 'on'
    opt.roipx = []
    opt.roiinds = []
    opt.roi_colors = [1 0 0]
    opt.roialpha = 0.3
    opt.cmap = gray(256) %colormap or 'rgb' if stack is truecolor (final dim length 3 . . . can be any numeric type)
    opt.title_prefix char = ''
    opt.index_labels cell = {} %ids for the indices represented by stack, each cell corresponds to each dim of stack, and must match in length
    opt.figsidelength = 0.75 %figure size as proportion of your available screen small dimension (cannot find the available size of your monitor bc it is not same as full size, so to be safe, keep this under 0.75 to prevent overfilling / causing nonsquare aspect)
    opt.axord char = 'rowmajor'
    opt.numcolorsgif = 128
    opt.fdimnum = 2; %how many dims to display on a each frame
    opt.dimorder = []; %dim order from left to right, top to bottom, first to last frame (y,x,z,t,pmt,colorchannel)
    opt.display_range = [0 1]; %[low,high] for image property CLim (contrast); ignored if stack is RGB
    opt.iy = [];
    opt.ix = [];
    opt.iz = [];
    opt.it = [];
    opt.ic = []; %pmt indices (red or green channel
    opt.ik = []; %rgb color channel indices 
end


%NEED TO REMOVE THIS, LIST INPUTS INSTEAD
fn = fieldnames(opt);
for fi = 1:numel(fn)
    eval([fn{fi} '= opt.(fn{fi});' ]);%transform 'opt' fields into local variables
end

if iscell(stack)
    szin = size(stack{1}); %taking first cell because below code makes sure all stacks are same size, if multiple
else
    szin = size(stack); %taking first cell because below code makes sure all stacks are same size, if multiple
end

if isempty(pthgif)
    pthgif = pthauto(vnm=pthgif, suffix='.gif', usetime=1);
end
  
if isempty(dimorder)
    dimorder = 1:numel(szin); %for now only one dim order allowed, so just take from first cell if stack is a cell 
end

index_labels_opt = cell(1,6);
if ~isempty(opt.iy)
    opt.iy = make_plot_inds(opt.iy, indsall=szin(1));
    if iscell(stack)
        stack = cellfun(@(x) x(opt.iy,:,:,:,:,:), stack, 'UniformOutput', false);
    else
        stack = stack(opt.iy,:,:,:,:,:);
    end
    index_labels_opt{1} = opt.iy;
end
if ~isempty(opt.ix)
    opt.ix = make_plot_inds(opt.ix, indsall=szin(2));
    if iscell(stack)
        stack = cellfun(@(x) x(:,opt.ix,:,:,:,:), stack, 'UniformOutput', false);
    else
        stack = stack(:,opt.ix,:,:,:,:);
    end
    index_labels_opt{2} = opt.ix;
end
if ~isempty(opt.iz)
    opt.iz = make_plot_inds(opt.iz, indsall=szin(3));
    if iscell(stack)
        stack = cellfun(@(x) x(:,:,opt.iz,:,:,:), stack, 'UniformOutput', false);
    else
        stack = stack(:,:,opt.iz,:,:,:);
    end
    index_labels_opt{3} = opt.iz;
end
if ~isempty(opt.it)
    opt.it = make_plot_inds(opt.it, indsall=szin(4));
    if iscell(stack)
        stack = cellfun(@(x) x(:,:,:,opt.it,:,:), stack, 'UniformOutput', false);
    else
        stack = stack(:,:,:,opt.it,:,:);
    end
    index_labels_opt{4} = opt.it;
end
if ~isempty(opt.ic)
    if numel(szin)<5
        error("you requested ic but stack is less than 5d")
    end
    opt.ic = make_plot_inds(opt.ic, indsall=szin(5));
    if iscell(stack)
        stack = cellfun(@(x) x(:,:,:,:,opt.ic,:), stack, 'UniformOutput', false);
    else
        stack = stack(:,:,:,:,opt.ic,:);
    end
    index_labels_opt{5} = opt.ic;
end
if ~isempty(opt.ik)
    if numel(szin)<6
        error("you requested ik but stack is less than 5d")
    end
    opt.ik = make_plot_inds(opt.ik, indsall=szin(6));
    if iscell(stack)
        stack = cellfun(@(x) x(:,:,:,:,:,opt.ik), stack, 'UniformOutput', false);
    else
        stack = stack(:,:,:,:,:,opt.ik);
    end
    index_labels_opt{6} = opt.ik;
end


clear roiolay %to clear the persistent variable within

if strcmp(cmap, 'rgb')
    error("don't pass truecolor stack yet, testing still")
end

%% check vars

dimlabels = vec(num2cell('yxztck')); %c is scanimage channel and k is rgb channel
fontmedium = 10;
maxnumdims = 6;
margins_fig = 0.05;
margins_subplot = 0;
max_num_inds_to_print = 20;
max_num_im_per_frame = 60;
max_num_gif_frames = 2000;

if ~iscell(display_range)
    if numel(display_range)~=2
        error("display range must be a cell of 2-element vectors or a 2-element vector")
    end
    display_range = {display_range};
end

if any(vec(cell2mat(cellfun(@(x) x<0 | x>1 , display_range, 'UniformOutput', false))))
    error("display_range must be in range 0-1")
end

if any(cell2mat(cellfun(@(x) x(1)>x(2), display_range, 'UniformOutput', false)))
    error("display_range(1) must be less than display_range(2)")
end

if iscell(stack)
    if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
        error("all stacks (each cell element) must be same size")
    end
    if numel(stack)~=1 && ~isempty(roipx)
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
        if ~isa(stack{si}, 'single') %for the rescaling cannot be uint16
            stack{si} = single(stack{si});
        end
        stack{si} = newmin + ((stack{si} - stackmin) / stackrange)*(newmax-newmin);
    end

    clim_tmp = [0 1]; %clim is [0 1] since stacks got rescaled 
    stack = cell2mat(stack); %convert to mat and cat stacks 

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
    clim_tmp = stackrange*cell2mat(display_range)+stackmin;
end


if isempty(roipx)
    roi_loop_size = 1;
    if isempty(roiinds)
        roi_message = ', roi-NaN';
    else
        roi_message = ', roi-not plotting roi without pixinds roi argument';
    end
else
    if ~iscell(roipx)
        if isvector(roipx)
            roipx = {roipx};
        else
            error("roipx must be cell, or vector")
        end
    end
    if numel(size(stack))>3
        sprintf("you passed roipx as argument and a stack with numdims>3; \nautomatically averaging dimensions>3 to create 3d background image for roi overlay; \nyou can also pass 2d or 3d stack instead")
        tmp = size(stack); 
        tmp = num2cell(tmp(1:3)); 
        stack = mean(reshape(stack, tmp{:}, []), 4);
        dimorder = dimorder(1:3);
    end
    if ~all(diff(dimorder)==1)
        error("dimorder must be consecutive integers to visualize rois (you passed roipx as argument)")
    end
    if isempty(roiinds)
        roiinds = 1:numel(roipx);
        roi_loop_size = numel(roipx);
    else
        roi_loop_size = numel(roiinds);
    end
end

if size(roi_colors, 1)==1
    roi_colors = repmat(roi_colors, [roi_loop_size 1]);
end


numdims = ndims(stack);

if numel(opt.iz)==1 && size(stack,3)==1 && numdims<=2 %if z became singleton because of iz argument
    numdims = numdims+1;
end
if numel(opt.it)==1 && size(stack,4)==1 && numdims<=3 %if t became singleton because of it argument
    numdims = numdims+1;
end
if numel(opt.ic)==1 && size(stack,5)==1 && numdims<=4 %if c became singleton because of ic argument
    numdims = numdims+1;
end
if numel(opt.ik)==1 && size(stack,6)==1 && numdims<=5 %if k became singleton because of ik argument
    numdims = numdims+1;
end

num_missing_dims = maxnumdims-numdims;

if numdims>maxnumdims
    error("max numdims is 6 (y,x,z,t,pmtchannel,colorchannel) ")
end

if strcmp(cmap, 'rgb') && size(stack, numdims)~=3
    error("last dimension must be length 3 if cmap argument is 'rgb'")
end

if fdimnum>numdims
    error("fdimnum must not exceed numdims")
end
if ~isequal(sort(dimorder), 1:numdims)
    error("dimorder must contain all integers 1 to numdims")
end


if ~isempty(intersect(find(~cellfun(@isempty, index_labels)), find(~cellfun(@isempty, index_labels_opt)))) % any(~cellfun(@isempty, index_labels_opt))
    error("for at least one stack dimension you defined index_labels and passed an *inds name-value argument; if you pass an *inds name-value argument, do not pass index_labels for the same dimension")
else
    index_labels_default = arrayfun(@(x) 1:x(end), size(stack), 'UniformOutput', false);
    missing_dims = numel(index_labels_default)+1:numel(index_labels_opt);
    index_labels_default(missing_dims) = {nan};
    nmitmp = ~cellfun(@isempty, index_labels);
    index_labels_opt(nmitmp) = index_labels(nmitmp); %for each dimension, if opt is empty, assign index_label input (opt will always be length 6)
    nmitmp = cellfun(@isempty, index_labels_opt);
    index_labels_opt(nmitmp) = index_labels_default(nmitmp); %for each dimension, assign default if there is no index_label input and no *inds input  (ie if still empty after above)
    index_labels = index_labels_opt;
end


%% prep images

dimorder = [dimorder [1:num_missing_dims]+numel(dimorder)];
stack = permute(stack, dimorder);
dimlabels = dimlabels(dimorder);
index_labels = index_labels(dimorder);
index_labels = index_labels';
sztmp = size(stack);
if fdimnum>numel(sztmp)
    fdimnum = numel(sztmp);
end
sz_framedims = sztmp(1:fdimnum);
sz_framedims = num2cell([sz_framedims(1:2) prod(sz_framedims(3:fdimnum))]);
stack = reshape(stack, sz_framedims{:}, []); %collapse fdimnum into 3d (possible singleton 3rd dim), keep them separate, collapse remaining dims into last dim

numxpix = size(stack,2);
numypix = size(stack,1);
numim_per_frame = size(stack,3); %after reshaping, size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if fdimnum==2)
numframes = size(stack,4); %after reshaping, size of 4th dim is number gif frames
dummyim = nan(numypix, numxpix);
dummyim_rgb = nan(numypix, numxpix, 3);


if numim_per_frame>max_num_gif_frames
    error(sprintf("you are attempting to plot " + num2str(numframes) + " gif frames, which exceeds the (optional) default max of " + num2str(max_num_gif_frames)))
end
if numim_per_frame>max_num_im_per_frame
    error(sprintf("you are attempting to plot " + num2str(numim_per_frame) + " images per frame, which exceeds the (optional) default max of " + num2str(max_num_im_per_frame)))
end

%% prep titles

dr_str = vec(cellfun(@num2str, display_range, 'UniformOutput', false))';
dr_str = cellfun(@(x,y,z) regexprep(x,y,z), dr_str, repelem({' +'}, numel(dr_str)), repelem({'to'}, numel(dr_str)), 'UniformOutput', false);
dr_str = cellfun(@(x,y,z) strrep(x,y,z), dr_str, repelem({'.'}, numel(dr_str)), repelem({'p'}, numel(dr_str)), 'UniformOutput', false);
dr_str = ['dr-' strjoin(dr_str, ' AND ')];

lab_framestable = {dr_str};
index_labels_tmp = index_labels(1:fdimnum); %labels that are the same on every frame
for li = 1:numel(index_labels_tmp)
    [~, index_labels_tmp{li}] = make_plot_inds(index_labels_tmp{li}, indsall=index_labels_tmp{li}, label_prefix=dimlabels{li}, printmax=max_num_inds_to_print);
end
lab_framestable = cat(1, lab_framestable, index_labels_tmp);
dims_changing_across_frames = fdimnum+1:maxnumdims;
lab_framechange = index_labels(dims_changing_across_frames); %labels that can change on each frame
lab_framechange_numel = cellfun(@numel, lab_framechange);

framecount = 0;
for ri = 1:roi_loop_size % loop over all rois, or if none, roi_loop_size is 1
    if isempty(roipx)
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
    if ~isempty(roipx)
        [imroi, imalpha] = roiolay(stack, roipx{roiinds(ri)}, col=roi_colors(ri,:), alp=roialpha); %make an overlay for one roi
    end
    for k = 1:numframes %for each figure/gif frame, which is collapsed dimensions after fdimnum
        framecount = framecount+1;
        for j = 1:numim_per_frame %size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if fdimnum==2)

            hpl{j}.CData = stack(:,:,j,k);
            if ~isempty(roipx) %&& k==1 %if there are roi variables
                hol{j}.CData = squeeze(imroi(:,:,j,k,:)); %squeeze to make it 3d (2d plus color channel)
                hol{j}.AlphaData = imalpha(:,:,j,k);
            end

        end

        htx.String = titlenew{framecount};

        fig2gif(hfg, framecount, pthgif, numcolorsgif)

    end

end

clear roiolay %to clear the persistent variable within

end

