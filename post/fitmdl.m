function [ft, gof, indvpref] = fitmdl(stack, fitin, roiinfo, md, opts, pixfitflag)

% for docs, see file fitmdl_notes.m


%% check some inputs and prepare save path

if isvector(fitin.indv_pre) & iscolumn(fitin.indv_pre)
    fitin.indv_pre = fitin.indv_pre(:)';
end

[ fitin.num_dim_indv_pre, fitin.num_samp_indv_pre ] = size( fitin.indv_pre );
[ fitin.num_dim_depv_pre, fitin.num_samp_depv_pre ] = size(fitin.depv_pre);

if fitin.num_samp_indv_pre~=fitin.num_samp_depv_pre | ndims(fitin.depv_pre)~=2 | ndims(fitin.indv_pre)~=2
    error("incorrectly sized input(s)")
end

if ~exist('pixfitflag', 'var')
    pixfitflag = 0;
    pixfitflagstr = '';
else
    if pixfitflag==1
        pixfitflagstr = '_PIX';
    end
end

pth_fitdata_prefix = [fitin.fn_save_prefix  '_' opts.modeltype '_' num2str(opts.model_length_sec) '_' num2str(opts.model_lag_sec) pixfitflagstr];
pth_fitdata_prefix = strrep(pth_fitdata_prefix, '.', 'p');

%% create pixelwise fit for background of hsv plot (if requested) by calling fitmdl here, with pixfitflag==1

if strcmp(opts.plt.hsv_background, 'pixels') && pixfitflag==0 %only do if pixfitflag==0, to avoid infinite recursion
    pixfitflag = 1;
    pixinds_roi2 = logical(sum(roiinfo.pixinds_roi)); %THESE ARE PIXEL INDICES FROM ALLROI MASK, NOT EACH ROI, ALL NOT SUPERSET OF EACH IF IF ANY ROIS ARE OVERLAPPING
    depv2 = reshape(stack, [], size(stack, 4));
    depv2 = depv2(cell2mat(pixinds_roi2), :);
    fitin2.depv = depv2;
    roiinfo2 = roiinfo;
    roiinfo2.pixinds_roi = pixinds_roi2;
    fitmdl(stack, fitin2, roiinfo2, md, opts, pixfitflag); %call fitmdl on pixels if you want a pixel fit background behind your roi fit background
    pixfitflag = 0; %reset to zero
end

%% prepare indv and depv

fitin = fitmdl_prepvars(fitin, opts, md, pth_fitdata_prefix);

%% set up model fitting and plotting options

[fitin, opts] = setup_model(fitin, opts, md.dtmni, pth_fitdata_prefix);

%% loop over epochinds, fitting model to each (fit to different requested subsets of indv/depv)

for epi = 1:length(opts.epochinds) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv
    for epi = 1:length(opts.epochinds) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv
        fitin = fitmdl_epochs(fitin, opts, epi, pth_fitdata_prefix);
    end
end

model_plots(fitin, roiinfo, stack, opts, pth_fitdata_prefix)

