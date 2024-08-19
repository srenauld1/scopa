function fitin = fitmdl(stack, fitin, roiinfo, md, opts, pixfitflag)

% for docs, see file fitmdl_notes.m

% indvpre and depvpre are independent and dependent variables before processing 
% the unintuitive thing that needs to be changed is that depvpre first dimension is the number of dependent variables (model is fit to vector dependent variables, looping over first dim), 
% while for indvpre, the whole array input to fitmdl is the independent variable . . . need to check if there's a goodreason for this or whether choose_timeseries should output vector depvpre (and input them to this function fitmdl)  

%% check some inputs and prepare save path


if isvector(fitin.vars.indvpre) & iscolumn(fitin.vars.indvpre)
    fitin.vars.indvpre = fitin.vars.indvpre(:)';
end

[ fitin.num_dim_indvpre, fitin.num_samp_indvpre ] = size(fitin.vars.indvpre);
[ fitin.num_dim_depvpre, fitin.num_samp_depvpre ] = size(fitin.vars.depvpre);

if fitin.num_samp_indvpre~=fitin.num_samp_depvpre | ndims(fitin.vars.depvpre)~=2 | ndims(fitin.vars.indvpre)~=2
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

pth_fitdata_prefix = [fitin.fn_save_prefix  '_' opts.mdlname '_' num2str(opts.mdl_length_sec) '_' num2str(opts.mdl_lag_sec) pixfitflagstr];
pth_fitdata_prefix = strrep(pth_fitdata_prefix, '.', 'p');

%% create pixelwise fit for background of hsv plot (if requested) by calling fitmdl here, with pixfitflag==1

if strcmp(opts.plt.hsv_background, 'pixels') && pixfitflag==0 %only do if pixfitflag==0, to avoid infinite recursion
    pixfitflag = 1;
    roipixind2 = logical(sum(roiinfo.roipixinds)); %THESE ARE PIXEL INDICES FROM ALLROI MASK, NOT EACH ROI, ALL NOT SUPERSET OF EACH IF IF ANY ROIS ARE OVERLAPPING
    depv2 = reshape(stack, [], size(stack, 4));
    depv2 = depv2(cell2mat(roipixind2), :);
    fitin2.vars.depvpre = depv2;
    roiinfo2 = roiinfo;
    roiinfo2.roipixinds = roipixind2;
    fitmdl(stack, fitin2, roiinfo2, md, opts, pixfitflag); %call fitmdl on pixels if you want a pixel fit background behind your roi fit background
    pixfitflag = 0; %reset to zero
end

%% prepare indv and depv

fitin = fitmdl_prepvars(fitin, opts, md, pth_fitdata_prefix);

%% set up model fitting and plotting options

fitin.opop = fitmdl_setup(fitin.num_samp_mdl, fitin.num_dim_indv, fitin.num_dim_indvpre, opts.mdlname, opts.chopt, md.dtmni, fitin.stats, pth_fitdata_prefix);

%% loop over epochinds, fitting model to each (fit to different requested subsets of indv/depv)

for epi = 1:length(opts.epochinds) %for each indv epoch, crop indv and depv according to epoch indices, then fit model to cropped indv/depv
    fitin = fitmdl_epochs(fitin, opts, epi, pth_fitdata_prefix);
end

% fitmdl_plots(fitin, roiinfo, stack, opts, pth_fitdata_prefix)

