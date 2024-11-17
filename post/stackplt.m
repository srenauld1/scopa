function h = stackplt(stack, opt)

%alphamapping is not yet an option

arguments
    stack %image stack(s), matrix if single stack, cell if multiple; if cell, must be same size; stack dimensions assumed to be (y,x,z,t,c,j); can be any data type; if passing cmap, clim property of image scaled to colormap range; if cmap is 'rgb', image must be rgb
    opt.pthgif char = ''
    opt.gifvis char = 'on'
    opt.roipx = []
    opt.ir = []
    opt.roicols = [1 0 0]
    opt.roialpha = 0.3
    opt.cmap = gray(256) %colormap or 'rgb' if stack is truecolor (final dim length 3 . . . can be any numeric type)
    opt.title_prefix char = ''
    opt.index_labels cell = {} %ids for the indices represented by stack, each cell corresponds to each dim of stack, and must match in length
    opt.szf = 1 %% scalar denoting fig size; 0-1 makes square until 1 makes largest square fig for your screen, sz 1-2 fills larger dimension until 2 is fullscreen
    opt.numcolorsgif = 128
    opt.dmplt = []; %dim order; 1 and 2 are rows and columns of each image, respectively, >2 are subplots with standard matlab arrangement (left to right, top to bottom); dimensions in parentheses are put in separate frames of gif; dimensions in dmstack, but not dmplt, are averaged; for example, if dmstack='yxztc' and dmplt='xyc(t)': each frame has c images, each image is x by y (row by column), there are t frames in the gif, and for all images z has been averaged, and there is no k dimension  
    opt.dmstack = [] %input stack dimensions; make empty for default (yxztck)
    opt.dr = [0 1]; %[low,high] for image property CLim (contrast); ignored if stack is RGB
    opt.iy = [];
    opt.ix = [];
    opt.iz = [];
    opt.it = [];
    opt.ic = []; %pmt indices (red or green channel
    opt.ik = []; %rgb color channel indices
    opt.doui = 0;
    opt.stackjust = 'center' %how to justify stack image; center, minimize, none
    opt.marginfg = 0.05;
    opt.marginax = 0.01;
    opt.fontsz = 10;
    opt.dosave = 1 %whether to write to gif 
end

eval(structvars(opt).'); %bad practice; turn opt into local variables with the same name as opt fields; using this function because there are so many here, but it's bad practice

clear roiolmake %to clear the persistent variable within

if isempty(pthgif)
    pthgif = pthauto(suffix='.gif', usetime=1);
end

if ~exist('dmstackdf', 'var') || isempty(dmstackdf)
    dmstackdf = glb('dmstackdf');
    if isempty(dmstackdf)
        fprintf("using dmdf yxztck" + newline)
        dmstackdf = 'yxztck';
    end
end


dimlabels = vec(num2cell(dmstackdf)); 
maxnumdims = numel(dmstackdf);
max_num_inds_to_print = 10;
max_num_im_per_frame = 60;
max_num_gif_frames = 2000;

if ndims(stack)>maxnumdims 
    error("stack exceeds maximum allowed number dimensions")
end
if ndims(stack)==maxnumdims || strcmp(cmap, 'rgb')
    error("stackplt does not currently support rgb stacks")
end
if strcmp(cmap, 'rgb') && size(stack, ndims(stack))~=3
    error("last dimension must be length 3 if cmap argument is 'rgb'")
end
if ~isempty(dmstack) && ( ~ischar(dmstack) || ~isequal(numel(erase(dmstack, {'(', ')'})), numel(unique(erase(dmstack, {'(', ')'})))) || any(~ismember(unique(dmstack), [dmstackdf '()'])) )
    error("dmstack must a char vector, without repeats, and can only contain the following characters: " + [dmstackdf '()'])
end
if ~isempty(dmplt) && ( ~ischar(dmplt) || ~isequal(numel(erase(dmplt, {'(', ')'})), numel(unique(erase(dmplt, {'(', ')'})))) || any(~ismember(unique(dmplt), [dmstackdf '()'])) )
    error("dmstack must be a char vector, without repeats, and can only contain the following characters: " + [dmstackdf '()'])
end
if iscell(stack) && ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
    error("all stacks (each cell element) must be the same size")
end


%% put stack into default order and apply any input indexing

stack = stackperm(stack, dmstack, dmstackdf);

if iscell(stack)
    stack_oneframe = stack{1}(:,:,:,1,1,1); %doing this before or after indexing is fine since if roipx is nonempty and xyz indexes are used error gets thrown
    szdfo = size(stack{1});
else
    stack_oneframe = stack(:,:,:,1,1,1); %doing this before or after indexing is fine since if roipx is nonempty and xyz indexes are used error gets thrown
    szdfo = size(stack);
end

[stack, index_labels_opt] = stackind(stack, opt, dmstackdf);


%% dmplt (put stack into user-input plot order)


if isempty(dmplt)
    dmplt = 'yxczk(t)'; %this will work for mean t or not, and with 1 or 2 channel, and 1 or more z; any t wil be shown across channels, everything else in each frame (if you don't like that just change dmplt
end
dmfrtmp = cell2mat(regexp(dmplt, '(\([a-z]*\))', 'match'));
if isempty(dmfrtmp)
    dm_acrossframes = []; %this is not used in this case, if dmfrtmp is empty, it's just here for clarity
    dm_eachframe = dmplt;
    dmplt_all = dm_eachframe;
else
    dm_acrossframes = erase(dmfrtmp, {'(', ')'});
    dm_eachframe = erase(dmplt, dmfrtmp);
    dmplt_all = [dm_eachframe dm_acrossframes];
end

numdim_eachframe = numel(dm_eachframe);

dimorder_notaveraged = zeros(1, numel(dmplt_all));
for k = 1:numel(dmplt_all)
    dimorder_notaveraged(k) = strfind(dmstackdf, dmplt_all(k));
end
dimorder = [dimorder_notaveraged setxor(dimorder_notaveraged, 1:numel(dmstackdf))];
dimorder_averaged = setxor(1:numel(dimorder_notaveraged), 1:numel(dmstackdf));

if iscell(stack)
    for k = 1:numel(stack)
        stack{k} = permute(stack{k}, dimorder);
        dimorder_averaged_nontrivial = dimorder_averaged(size(stack{1},dimorder_averaged)~=1); %do this after indexing and permuting, but before averaging
        if ~isempty(dimorder_averaged) %do this after applying any indices
            stack{k} = mean(stack{k}, dimorder_averaged, 'native');
        end
    end
else
    stack = permute(stack, dimorder);
    dimorder_averaged_nontrivial = dimorder_averaged(size(stack,dimorder_averaged)~=1); %do this after indexing and permuting, but before averaging
    if ~isempty(dimorder_averaged) %do this after applying any indices
        stack = mean(stack, dimorder_averaged, 'native');
    end
end

if isequal(dm_eachframe(1), 'x') %if the first in-frame dimension is x, use normal axis y direction, otherwise use reverse, which is default in initaxim 
    ydir = 'normal'; 
else
    ydir = 'reverse'; 
end


%% dr (apply display range to adjust contrast)


if ~iscell(dr)
    if numel(dr)~=2
        error("display range must be a cell of 2-element vectors or a 2-element vector")
    end
    dr = {dr};
end

if any(cell2mat(cellfun(@(x) x(1)>x(2), dr, 'UniformOutput', false)))
    error("dr(1) must be less than dr(2)")
end

if iscell(stack)
    if ~all(cellfun(@(e) isequal(size(stack{1}), size(e)), stack(2:end)))
        error("all stacks (each cell element) must be same size")
    end
    if numel(stack)~=1 && ~isempty(roipx)
        error("cannot currently plot roi overlay on multi-stack image")
    end
    if numel(dr)~=1 && numel(dr)~=numel(stack)
        error("dr length must be 1, or match number of stacks")
    end
    if numel(dr)==1
        dr = repmat(dr, [numel(stack) 1]);
    end

    for si = 1:numel(stack) %if you are combining multiple stacks, rescale them to apply the display range, and make [0 1] new dr (CLim)
        stackmin = double(min(stack{si}(:)));
        stackmax = double(max(stack{si}(:)));
        stackrange = stackmax-stackmin; %(max-min)*dr+min = [0 1]
        rsa = [dr{si}(1) 1-dr{si}(1); %dr{si}(1)*newmax - dr{si}(1)*newmin + newmin = 0;
            dr{si}(2) 1-dr{si}(2)]; %dr{si}(2)*newmax - dr{si}(2)*newmin + newmin = 1;
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

else %if there's only one stack, don't rescale it, just assign dr to CLim
    if numel(dr)~=1
        error("dr length must be 1 if one stack is passed as argument")
    end
    stackmin = double(min(stack(:)));
    stackmax = double(max(stack(:)));
    stackrange = stackmax-stackmin;
    clim_tmp = stackrange*cell2mat(dr)+stackmin;
end

%% roipx (roi pixel indices)

if isempty(roipx)
    dool = 0;
    roi_loop_size = 1;
    if isempty(ir)
        roi_message = ', roi: NaN';
    else
        roi_message = ', roi: not plotting roi without pixinds roi argument';
    end
else
    dool = 1;
    if ( numel(dmplt_all)>3 && any(~ismember(dmplt_all(1:3), 'yxz')) ) || ( numel(dmplt_all)<=3 && any(~ismember(dmplt_all, 'yxz')) )
        error("roipx currently only supports xyz as first 3 dimensions, in any order, in frame or across frames") 
    end
    if ~isempty([ix iy iz])
        error("cannot pass ix, iy, or it with roipx since stackplt assumes roipx refers to indices into the entire xyz")
    end
    if ~iscell(roipx)
        if isvector(roipx)
            roipx = {roipx};
        else
            error("roipx must be cell, or vector")
        end
    end
    if isempty(ir)
        ir = 1:numel(roipx);
        roi_loop_size = numel(roipx);
    else
        kpir = ismember(ir, 1:numel(roipx));
        if any(kpir==0)
            fprintf("you requested to plot some rois (ir) that don't exist, according to the roi pixel indices you passed as argument (roipx), so ignoring those rois" + newline)
        end
        ir = ir(kpir);
        roi_loop_size = numel(ir);
    end
end

if size(roicols, 1)==1
    roicols = repmat(roicols, [roi_loop_size 1]);
end


%% reshape stack into per-gif-frame and across-gif-frame images

sztmp = size(stack);
if numdim_eachframe>numel(sztmp)
    numdim_eachframe = numel(sztmp);
end
sz_framedims = sztmp(1:numdim_eachframe);
sz_framedims = num2cell([sz_framedims(1:2) prod(sz_framedims(3:numdim_eachframe))]);
stack = reshape(stack, sz_framedims{:}, []); %collapse numdim_eachframe into 3d (possible singleton 3rd dim), keep them separate, collapse remaining dims into last dim

numim_per_frame = size(stack,3); %after reshaping, size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if numdim_eachframe==2)
numframes = size(stack,4); %after reshaping, size of 4th dim is number gif frames

if numim_per_frame>max_num_gif_frames
    error(sprintf("you are attempting to plot " + num2str(numframes) + " gif frames, which exceeds the (optional) default max of " + num2str(max_num_gif_frames)))
end
if numim_per_frame>max_num_im_per_frame
    error(sprintf("you are attempting to plot " + num2str(numim_per_frame) + " images per frame, which exceeds the (optional) default max of " + num2str(max_num_im_per_frame)))
end


%% prep titles

if ~isempty(intersect(find(~cellfun(@isempty, index_labels)), find(~cellfun(@isempty, index_labels_opt)))) % any(~cellfun(@isempty, index_labels_opt))
    error("for at least one stack dimension you defined index_labels and passed a stack index name-value argument (iy,ix,iz,it,ic, or ik); if you pass an index name-value argument, do not pass index_labels for that same dimension")
else
    index_labels_default = arrayfun(@(x) 1:x(end), szdfo, 'UniformOutput', false);
    missing_dims = numel(index_labels_default)+1:numel(index_labels_opt);
    index_labels_default(missing_dims) = {nan};
    nmitmp = ~cellfun(@isempty, index_labels);
    index_labels_opt(nmitmp) = index_labels(nmitmp); %for each dimension, if opt is empty, assign index_label input (opt will always be length 6)
    nmitmp = cellfun(@isempty, index_labels_opt);
    index_labels_opt(nmitmp) = index_labels_default(nmitmp); %for each dimension, assign default if there is no index_label input and no *inds input  (ie if still empty after above)
    index_labels = index_labels_opt;
end
dimlabels = dimlabels(dimorder);
index_labels = index_labels(dimorder);


index_labels_avg = cell(numel(index_labels), 1);
for k = 1:numel(dimorder_averaged_nontrivial) %averaged dimensions 
    il = dimorder_averaged_nontrivial(k);
    [~, index_labels_avg{il}] = indsmake(index_labels{il}, indsall=index_labels{il}, label_prefix=dimlabels{il}, printmax=max_num_inds_to_print);
end

index_labels_tmp = index_labels(1:numdim_eachframe); %labels that are the same on every frame
for k = 1:numel(index_labels_tmp)
    [~, index_labels_tmp{k}] = indsmake(index_labels_tmp{k}, indsall=index_labels_tmp{k}, label_prefix=dimlabels{k}, printmax=max_num_inds_to_print);
end
lab_framestable = index_labels_tmp;

dims_after_permute_changing_across_frames = numdim_eachframe+1:maxnumdims;
lab_framechange = index_labels(dims_after_permute_changing_across_frames); %labels that can change on each frame
lab_framechange_numel = cellfun(@numel, lab_framechange);

dr_str = vec(cellfun(@num2str, dr, 'UniformOutput', false))';
dr_str = cellfun(@(x,y,z) regexprep(x,y,z), dr_str, repelem({' +'}, numel(dr_str)), repelem({'-'}, numel(dr_str)), 'UniformOutput', false);
% dr_str = cellfun(@(x,y,z) strrep(x,y,z), dr_str, repelem({'.'}, numel(dr_str)), repelem({'p'}, numel(dr_str)), 'UniformOutput', false);
dr_str = [', dr: ' strjoin(dr_str, ' AND ')];

cnt = 0;
for ri = 1:roi_loop_size % loop over all rois, or if none, roi_loop_size is 1
    if isempty(roipx)
        roinum_title = roi_message;
    else
        roinum_title = [', roi: ' num2str(ir(ri))];
    end
    for k = 1:numframes
        cnt = cnt+1;
        [i1,i2,i3,i4,i5,i6]=ind2sub(lab_framechange_numel(:)', k); %subscript of frame in all possible dimensions
        subtmp = [i1,i2,i3,i4,i5,i6];
        subtmp = subtmp(1:numel(lab_framechange));
        labtmp = cellfun(@(x,y) x(y), lab_framechange, num2cell(subtmp(:)), 'UniformOutput', false); %frame changing part of label
        labtmp = cellfun(@num2str, labtmp, 'UniformOutput', false);
        labtmp = cellfun(@horzcat, dimlabels(dims_after_permute_changing_across_frames), repelem({': '}, size(labtmp,1), 1), labtmp, 'UniformOutput', false); %frame changing part of label
        titlesuffix = cat(1, lab_framestable(:), labtmp(:));
        titlesuffix(dimorder_averaged_nontrivial) = index_labels_avg(dimorder_averaged_nontrivial); %update index labels for any dimensions that are changing across frames and that have been non-trivially averaged (so that they are stable showing the averaged indices on every gif frame)
        titlesuffix(dimorder_averaged_nontrivial) = insertAfter(titlesuffix(dimorder_averaged_nontrivial), ':', '(avg)');
        titlesuffix = strjoin(titlesuffix, ', ');
        titlesuffix = [titlesuffix, roinum_title, dr_str];
        titlenew{cnt} = {strrep(title_prefix, '_', ' '); titlesuffix};
    end
end

%% init subplots

ax = axarr(stack, marginax=marginax, marginfg=marginfg, stackjust=stackjust);
h = initfig(fontsz=fontsz, szf=szf);
h.st = initaxim(h.hfg, ax, stack, dool=dool, doui=doui, cmap=cmap, ydir=ydir);

%% plot

cnt = 0;
for ri = 1:roi_loop_size % loop over all rois, or if none, roi_loop_size is 1
    if ~isempty(roipx)
        
        [imroi, imalpha] = roiolmake(stack_oneframe, roipx{ir(ri)}, col=roicols(ri,:), alp=roialpha); %make an overlay for one roi
        
        sz_framedims_ol = sz_framedims(1:ndims(stack_oneframe));
        dimorder_ol = [dimorder(1:ndims(stack_oneframe)) ndims(stack_oneframe)+1];

        imroi = permute(imroi, dimorder_ol);
        imroi = reshape(imroi, sz_framedims_ol{:}, [], size(imroi, ndims(imroi))); %collapse numdim_eachframe into 3d (possible singleton 3rd dim), keep them separate, collapse remaining dims into last dim

        imalpha = permute(imalpha, dimorder_ol(1:end-1));
        imalpha = reshape(imalpha, sz_framedims_ol{:}, []); %collapse numdim_eachframe into 3d (possible singleton 3rd dim), keep them separate, collapse remaining dims into last dim

        szolz = size(imroi,4);

    end
    for k = 1:numframes %for each figure/gif frame, which is collapsed dimensions after numdim_eachframe
        cnt = cnt+1;
        for j = 1:numim_per_frame %size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if numdim_eachframe==2)

            if k==1
                h.st.hax{j}.CLim = clim_tmp;
            end

            h.st.hpl{j}.CData = stack(:,:,j,k);
            if ~isempty(roipx) %&& k==1 %if there are roi variables
                frameol = mod(k-1, szolz)+1;
                h.st.hol{j}.CData = squeeze(imroi(:,:,j,frameol,:)); %squeeze to make it 3d (2d plus color channel)
                h.st.hol{j}.AlphaData = imalpha(:,:,j,frameol);
            end

        end

        h.httl.String = titlenew{cnt};

        if dosave
            fig2gif(h.hfg, cnt, pthgif, numcolorsgif) %save each frame to gif
        end

    end

end

clear roiolmake %to clear the persistent variable within


end

