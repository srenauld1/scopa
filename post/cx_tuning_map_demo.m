


% this demo fits activity in each voxel in a 3d (xyt) or 4d (xyzt) imaging volume to 1d stimulus vector (length t)
% then plots hsv image of volume (minus time dimension) of model
%
% demo for multidimensional stimulus coming soon
%
% hue is a model tuning param, normalized to stimulus domain
% saturation is a goodness-of-fit metric, normalized to pixel population
% value is responsivity metric, normalized to pixel population
%
% user input string chooses from options for each
%
% plot displays hsv image for one 2d slice at a time, along with diagnostic plots
%
% plots saved as gif
%
% demo also includes cropping function to restrict model fitting / plotting to user-defined polyhedron subregion
%
%
% foreground / background option (and none)
%
% order of roi/voxel, param, slice
%
% 3d image option (to eliminate slice dimension)
%
% option to average responses option if repetitions (if values in stim vector are repeated)

% updated 231209, carl wienecke


close all
clear all
clc


%% input params

pth_super = '~/Documents/ambrose/stacks/'; %path containing all recordings, backslashes fine here, will be replaced if on pc

if ispc
    pth_super = strrep(pth_super, '/', '\');
end

recdate = '20230627'; %can use wildcards
fly = '*'; %can use wildcards
trial = '*'; %can use wildcards
fn_suffix = 'cmrg_dcdn'; %imaging data filename suffix
region_extraction_all = {'pb2'}; %name of crop fov region within which you run extraction 
stimstr = 'cueang'; %name of stim in filename 

numsamp_lag = 2; %how many samples stim precedes resp for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)

crop_to_cuboid = 1; %keep as 1 for now 
resize_factor = 0; %resize movie (0.5 downsamples by half) . . . watch out for ringing artifacts around isolated activity regions
use_mask_simple = 0; %0 for xy roi projected through z, 1 for additional refinement with edge detection within that region 
doplots_mask = 1; %plot the masks

smooth_window_temporal = 0; %gaussian window std is one fifth total length

modeltype = 'vonmises'; %'gaussian', 'vonmises' 'log' 'linear'
huestr = 'loc'; %loc or amp for modeltype linear . . . loc, amp, or wid for modeltype vonmises or gaussian 

huenorm = 'native'; %hue normalization method, see cx_model_setup
satnorm = 'relative'; %sat normalization method, see cx_model_setup
valnorm = 'relative';%val normalization method, see cx_model_setup
hrange_in_manual = []; %manual range for normalizing hue, prior to normalization to plot scale, whose max range is [0 1]), see cx_form_hsv
srange_in_manual = []; %manual range for normalizing sat, prior to normalization to plot scale, whose max range is [0 1]), see cx_form_hsv
vrange_in_manual = []; %manual range for normalizing val, prior to normalization to plot scale, whose max range is [0 1]), see cx_form_hsv
hrange_out_manual = [0.25 1]; %hue plot scale, whose max range is [0 1] hue hange around color circle, defaults to less than full circle for non-periodic plotting domain, but overwrites in cx_model_setup to [0 1] when plotting periodic param (e.g. von mises center, ie modeltype 'vonmises' huestr 'loc'), see cx_form_hsv
srange_out_manual = [0 1]; %sat plot scale, whose max range is [0 1], if you want to force saturation you can reduce (e.g. [0 0.75] will force smaller range to max saturation, see cx_form_hsv 
vrange_out_manual = [0 1];  %val plot scale, whose max range is [0 1], if you want to force value you can reduce (e.g. [0 0.75] will force smaller range to max value, see cx_form_hsv 
hueshift = 0; % 0-1, circularly shift the hue map around the color circle for change to arbitrary color assignment, applied before any clipping due to, see cx_form_hsv 

ignorehue = 0; %1 ignores it, makes constant 1
ignoresat = 0; %1 ignores it, makes constant 1
ignoreval = 0; %1 ignores it, makes constant 1

responseplot_norm = 'each'; %amplotude normalization for the detail plots at bottom, 'all' normalizes to population, 'each' normalizes to each
maxnumplotinds = 200; %number of rois that get detail view on the bottom, one per gif frame
plotinds_selection = 'gof'; %how to select rois for detail plots, 'unbiased' for equidistant maxnumplotinds, 'gof' for equidistant maxnumplotinds sorted by gof in descending order (so starts with best fit ends with worst)

standardize_resp = 1; %1 makes each response mean=0 variance=1 for fitting model (but still uses original scale for plotting), this is useful for comparing gof (if gof is default of mse, at least) of models fit to responses whose amplitudes differ 

gif_visibility = 'on'; %on shows gif while plotting/writing/saving, off saves/writes but doesn't show it 
max_tinds = 1000; %for the timeseries view of responses, how many samples to plot at the most (will take indices 1:max_tinds)

md.volrate = 5.08; %hz, volume rate
md.dt_i_mean = 1/md.volrate;


%% filenames


fn_pattern = [pth_super '**' filesep recdate '_' fly '_' trial '_' fn_suffix '_.mat'];

pth_all = rdir(fn_pattern);


for ri = 1:length(pth_all)

    pth_mov = pth_all(ri).name;
    display(['processing : ' pth_mov] )

    [pth_fldr, fn_mov, ~] = fileparts(pth_mov);
    pth_fldr = [pth_fldr filesep];
    spl = strjoin(strsplit(fn_mov, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
    spl = strsplit(spl, '_'); %then separate by underscore

    datenum = str2double(spl{1});
    flynum = str2double(spl{2});
    trialnum = str2double(spl{3});

    recid = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];
    recid_tit = strrep(recid, '_', ' ');

    pth_stim = [pth_fldr recid '_' stimstr '_.mat'];

    %% load stim


    load(pth_stim)


    %% load movie

    tmpC = struct2cell(load(pth_mov));
    stackraw = tmpC{1};
    md.sz = size(stackraw);
    if ~isa(stackraw,'uint16')
        if isa(stackraw, 'int16')
            stackraw = uint16(stackraw - min(stackraw(:)));
        else
            "MOVIE IS NOT UINT16"
            error
        end
    end

    %% smooth movie

    if smooth_window_temporal
        stackraw = smoothdata(stackraw, 4, 'gaussian', smooth_window_temporal);
    end


    %% resize movie xy


    if resize_factor
        stackrawnew = zeros(size(stackraw, 1)*resize_factor, size(stackraw, 2)*resize_factor, size(stackraw, 3), size(stackraw, 4), 'uint16');
        for rszi = 1:size(stackraw, 3)
            for rsti = 1:size(stackraw, 4)
                stackrawnew(:,:,rszi,rsti) = imresize(stackraw(:,:,rszi, rsti), resize_factor);
            end
        end
        stackraw = stackrawnew;
        stackrawnew = [];
    end


    %% crop fov

    for rei = 1:length(region_extraction_all) %for each region with extracted rois

        region_extraction = region_extraction_all{rei};
        pth_cropinds = [pth_mov(1:end-4) '_cropindscub_' region_extraction '_.mat'];
        pth_roi2d_manual = [pth_mov(1:end-4) '_roi2d_' region_extraction '_.mat'];
        pth_roidata = [pth_roi2d_manual(1:end-4) '_roidata_.mat'];
        pth_fitdata = [pth_stim(1:end-4) region_extraction '_fitdata_.mat'];

        use_hires = 0;
        hirescrop = [];
        numroi_morph = 1;
        map_hires_lores = [];
        old_project = 0;


        if crop_to_cuboid
            try
                load(pth_cropinds)
            catch
                clip_percentile_for_viz = [0 100];
                meanim = cx_process_stack_for_roi_selection(stackraw, pth_cropinds, clip_percentile_for_viz);
                cropxy = drawrois_cx(meanim, [], region_extraction);
                [yinds, xinds] = ind2sub(size(cropxy), find(cropxy));
                yinds = min(yinds):max(yinds);
                xinds = min(xinds):max(xinds);
                tmptmp = rescale(mean(stackraw, 4), 0, 2);
                figure;
                try
                    montage(rescale(mean(stackraw, 4), 0, 2))
                catch
                    [numimrows, numimcols] = subplot_tiling(size(tmptmp, 3));
                    for tti = 1:size(tmptmp, 3)
                        subplot(numimrows, numimcols, tti)
                        imshow(tmptmp(:,:,tti));
                        axis image; axis off
                    end
                end
                prompt = "select z indices in format [first:last]: ";
                zinds = input(prompt);
                tinds = 1:md.sz(4);
                save(pth_cropinds, 'yinds', 'xinds', 'zinds', 'tinds', '-v7.3', '-mat')
            end
            stackraw_crop = single(stackraw(yinds, xinds, zinds, tinds)); %need to create this and make single for draw_morphological_rois function
        else
            "IS THE DATA TOO LARGE?"
            error
        end


        try
            load(pth_roidata)
        catch
            [roiinds_mask3d, centroids_mask3d, mask3d] = ...
                cx_make_morphological_rois(stackraw_crop, use_hires, hirescrop, ...
                numroi_morph, md, pth_mov, map_hires_lores, ...
                pth_roi2d_manual, region_extraction, old_project, ...
                use_mask_simple, doplots_mask);
            save(pth_roidata, 'roiinds_mask3d', 'centroids_mask3d', 'mask3d', '-v7.3', '-mat')

        end

        roiinds_mask3d_all{rei} = roiinds_mask3d;
        yinds_all{rei} = yinds;
        xinds_all{rei} = xinds;
        zinds_all{rei} = zinds;
        tinds_all{rei} = tinds;

    end



    %% fit model and plot


    for rei = 1:length(region_extraction_all)


        stackraw_crop = single(stackraw(yinds_all{rei}, xinds_all{rei}, zinds_all{rei}, tinds_all{rei}));
        md.sz = size(stackraw_crop);
        meanvol = mean(stackraw_crop, 4);
        stackraw_crop = reshape(stackraw_crop, [], size(stackraw_crop, ndims(stackraw_crop)));

        roifitinds = find(roiinds_mask3d_all{rei});
        roiinds = cell(length(roifitinds), 1);
        for ii = 1:length(roiinds)
            roiinds{ii} = roifitinds(ii);
        end


        doplots_fit = 1;
        epochinds = {[1]};
        standardize_stim = 0;
        plot3d = 0;
        slvr = 'fmincon'; %'lsqcurvefit';
        length_model_seconds = 0; %seconds, 0 is one sample
        smoothresp = [];
        cmap_im = [];
        roipixvals_binned = zeros(length(roiinds), 1);
        roipixvals_edges = zeros(length(roiinds), 1);
        roinumpix = zeros(length(roiinds), 1);
        rcor = zeros(length(roiinds), 1);
        rsnr = zeros(length(roiinds), 1);
        synthesize_resp = 0;
        hsv_background = 'pixels'; %'rois' or 'raw' or 'supp';
        plot_class = 'hsv'; %hsv only shows one epoch per plot/gif frame, epoch shows multiple epochs but no hsv map
        excludeopts = 'none';

        if strcmp(recdate, '20230627') %if carl's demo data
            md.stimepochinds_i = zeros(1, md.sz(4));
            md.stimepochinds_i(1:2000) = 1;
            md.stimepochinds_i(~isnan(stim)) = 1;
            % roifitinds = roifitinds(1:100:end);
            % roiinds = roiinds(1:100:end);
        else
            md.stimepochinds_i = ones(1, md.sz(4)); %don't change for now
        end

      
        [fittmp, goftmp] = cx_fit(md, stim, stackraw_crop, meanvol, ...
            roifitinds, roiinds, epochinds, excludeopts, ...
            length_model_seconds, numsamp_lag, ...
            standardize_stim, standardize_resp, responseplot_norm, ...
            modeltype, huestr, slvr, ...
            plot3d, cmap_im, ...
            roipixvals_binned, roipixvals_edges, roinumpix, ...
            rcor, rsnr, smoothresp, ...
            huenorm, satnorm, valnorm, ...
            hrange_in_manual, srange_in_manual, vrange_in_manual, ...
            hrange_out_manual, srange_out_manual, vrange_out_manual, ...
            hueshift, ignorehue, ignoresat, ignoreval, ...
            hsv_background, plot_class, ...
            maxnumplotinds, plotinds_selection, max_tinds, ...
            pth_fitdata, gif_visibility, doplots_fit);


    end
end
