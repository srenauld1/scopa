
%% input

% this will load any or all of raw, registered, and denoised stacks for any recording 
% will try to load mat file, 
% if mat doesn't exist, will read tif and save as mat to save time in future runs
% will plot all stacks as a single movie, concatenated along first dim, and save as gif

% will also plot rescaled movie, and mean movie with and without rescaling
% can optionally rescale all subplots to same range 
% you can choose which z and t indices to plot/save 

% nans inserted above each subplot to separate them clearly (nan_numlines)   

% this script converts raw scanimage tif to uint16
% and assumes registered and denoised tifs were saved as uint16 

% script rescales manually to keep array as uint16 

% this will error if there are two files with the exact same name 
% in different directories within filepath_super  

close all
clear all
clc

plot_raw = 1; %optional
plot_reg = 1; %optional
plot_dn = 1; %optional
nan_numlines = 4; %how many lines of nans to insert in dim 1 above each subplot
rescale_each_subplot = 1; %rescale each subplot to same range 0-1 before combining
rescale_fac_bottom_wholeplot = 0; %combined plot rescale lower clip
rescale_fac_top_wholeplot = 6; %combined plot rescale upper clip
plotinds_t = 1:30:3000; %time indices to plot
plotinds_z = [1:8]; %z indices to plot
swapdim = 1; %true will flip z and t for plotting to change perspective on registration, recommended for length(plotinds_z)>1
smooth_window_temporal = 100;


filepath_super = '~/Documents/ambrose/stacks/';

recdate = '20230424';
flyind = '*';
trial = '*';

ncol = 256; %num colors in plot

%% filenames

if strcmp(trial, '*')
    fn_pattern = [filepath_super '**/' recdate '-' flyind '_*_trial_*_*.tif'];
else
    fn_pattern = [filepath_super '**/' recdate '-' flyind '_*_trial_' sprintf( '%03d', str2double(trial) ) '_*.tif'];
end
pth_all = rdir(fn_pattern);

for ri = 1:length(pth_all)

    pth_raw_tif = pth_all(ri).name;
    display(['processing : ' pth_raw_tif] )
    [pth_fldr, fn_raw, ~] = fileparts(pth_raw_tif);

    spl = strsplit(fn_raw, '_');
    spl2 = strsplit(spl{1}, '-');

    datenum = str2double(spl2{1});
    flynum = str2double(spl2{2});
    trialnum = double(sscanf(cell2mat(spl(find(strcmp(spl, 'trial'))+1)), '%d')); %extract number from underscore-separated substring following 'trial' substring
    recid = [spl2{1} '_' spl2{2} '_' num2str(trialnum)];
    recid_tit = [spl2{1} ' ' spl2{2} ' ' num2str(trialnum)];

    pth_raw_mat = [pth_raw_tif(1:end-4) '.mat'];

    pth_reg_tif = [pth_fldr '/' recid '_cmrg_.tif'];
    pth_reg_mat = [pth_reg_tif(1:end-4) '.mat'];

    pth_dn_tif = [pth_fldr '/' recid '_cmrg_dcdn_.tif'];
    pth_dn_mat = [pth_dn_tif(1:end-4) '.mat'];

    pth_metadata = [pth_fldr '/' recid '_metadatanew_.mat'];

    load(pth_metadata) %file created in initial python part of pipeline
    sz = [md.ypix md.xpix md.numslice md.numvol];

    size_z_read_from_raw = md.numslice_withflyback; %raw tif includes flyback
    size_z_read_from = sz(3);
    size_t_read_from = sz(4);
    inds_z_read_from = 1:size_z_read_from; %can choose to not read the flyback frames here
    inds_t_read_from = 1:size_t_read_from;
    size_read_to = [length(inds_t_read_from), length(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed, permute within cx_read_tif_tzyx

    nanins = single(nan([nan_numlines, size_read_to(4), length(plotinds_z), length(plotinds_t)]));
    nanins_mn = nanins(:,:,:,1);

    plotinds_z_str = sprintf('%.0f,', plotinds_z);
    plotinds_z_str = plotinds_z_str(1:end-1);% strip final comma
    rescale_str = [' rescale ' num2str(rescale_fac_bottom_wholeplot) ' ' num2str(rescale_fac_top_wholeplot)];
    
    if rescale_each_subplot
        rseachstr = 'eachrescaled';
    else
        rseachstr = '';
    end

    stackall = [];
    stackall_mn = [];
    fn_gif_insert = '';

    %% read raw


    if plot_raw

        try
            load(pth_raw_mat)
        catch
            out_datatype = "int16"; %NOTE: SCANIMAGE SAVES INT16 NOT UINT16, CONVERT BELOW
            stackraw = cx_read_tif_tzyx(pth_raw_tif, ...
                out_datatype, size_read_to, ...
                size_z_read_from_raw, size_t_read_from, ...
                inds_z_read_from, inds_t_read_from);
            
            datmin_raw = min(stackraw(:));
            datmax_raw = max(stackraw(:));
            stackraw = single(stackraw);
            stackraw = stackraw - double(datmin_raw);
            if datmax_raw > 2^16-1
                "ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE"
                error
            end
            stackraw = uint16(stackraw);

            save(pth_raw_mat, 'stackraw', '-v7.3', '-mat')

        end

        if smooth_window_temporal
            stackraw = smoothdata(stackraw, 4, 'gaussian', smooth_window_temporal);
        end

        tmp = single(stackraw(:,:,plotinds_z, plotinds_t));
        tmp_mn = mean(stackraw, 4);
        tmp_mn = single(tmp_mn(:,:,plotinds_z));
        if rescale_each_subplot
            tmp = rescale(tmp);
            tmp_mn = rescale(tmp_mn);
        end
        stackall = cat(1, stackall, nanins, tmp);
        stackall_mn = cat(1, stackall_mn, nanins_mn, tmp_mn);
        clear stackraw tmp*
        fn_gif_insert = [fn_gif_insert 'raw_'];

    end

    %% read registered

    if plot_reg
        
        try
            load(pth_reg_mat)
        catch
            out_datatype = "uint16"; %UINT16 HERE BECAUSE WRITTEN THAT WAY IN PYTHON
            stackreg = cx_read_tif_tzyx(pth_reg_tif, ...
                out_datatype, size_read_to, ...
                size_z_read_from, size_t_read_from, ...
                inds_z_read_from, inds_t_read_from);
            save(pth_reg_mat, 'stackreg', '-v7.3', '-mat')
        end


        if smooth_window_temporal
            stackreg = smoothdata(stackreg, 4, 'gaussian', smooth_window_temporal);
        end

        tmp = single(stackreg(:,:,plotinds_z, plotinds_t));
        tmp_mn = mean(stackreg, 4);
        tmp_mn = single(tmp_mn(:,:,plotinds_z));
        if rescale_each_subplot
            tmp = rescale(tmp);
            tmp_mn = rescale(tmp_mn);
        end
        stackall = cat(1, stackall, nanins, tmp);
        stackall_mn = cat(1, stackall_mn, nanins_mn, tmp_mn);
        clear stackreg tmp*
        fn_gif_insert = [fn_gif_insert 'reg_'];

    end

    %% read denoised

    if plot_dn
        
        try
            load(pth_dn_mat)
        catch
            out_datatype = "uint16"; %UINT16 HERE BECAUSE WRITTEN THAT WAY IN PYTHON
            stackdn = cx_read_tif_tzyx(pth_dn_tif, ...
                out_datatype, size_read_to, ...
                size_z_read_from, size_t_read_from, ...
                inds_z_read_from, inds_t_read_from);
            save(pth_dn_mat, 'stackdn', '-v7.3', '-mat')
        end

        if smooth_window_temporal
            stackdn = smoothdata(stackdn, 4, 'gaussian', smooth_window_temporal);
        end

        tmp = single(stackdn(:,:,plotinds_z, plotinds_t));
        tmp_mn = mean(stackdn, 4);
        tmp_mn = single(tmp_mn(:,:,plotinds_z));
        if rescale_each_subplot
            tmp = rescale(tmp);
            tmp_mn = rescale(tmp_mn);
        end
        stackall = cat(1, stackall, nanins, tmp);
        stackall_mn = cat(1, stackall_mn, nanins_mn, tmp_mn);
        clear stackdn tmp*
        fn_gif_insert = [fn_gif_insert 'dn_'];

    end

    %% plot

    tit_gif_insert = strrep(fn_gif_insert, '_', ' ');
    
    plot_gif_fast(rescale(stackall), ...
        ncol, swapdim, ...
        [pth_fldr '/' recid '_' fn_gif_insert rseachstr '_zinds' plotinds_z_str '_.gif'], ...
        {[recid_tit ' : ' tit_gif_insert]; ['z inds ' plotinds_z_str]})
    
    plot_gif_fast(rescale(stackall, rescale_fac_bottom_wholeplot, rescale_fac_top_wholeplot), ...
        ncol, swapdim, ...
        [pth_fldr '/' recid '_' fn_gif_insert rseachstr '_zinds' plotinds_z_str  '_allrescaled_.gif'], ...
        {[recid_tit ' : ' tit_gif_insert]; ['z inds ' plotinds_z_str]; rescale_str})
    
    plot_gif_fast(rescale(stackall_mn), ...
        ncol, swapdim, ...
        [pth_fldr '/' recid '_' fn_gif_insert rseachstr '_zinds' plotinds_z_str '_meanframe_.gif'], ...
        {[recid_tit ' : ' tit_gif_insert ' meanframe']; ['z inds ' plotinds_z_str]})
    
    plot_gif_fast(rescale(stackall_mn, rescale_fac_bottom_wholeplot, rescale_fac_top_wholeplot), ...
        ncol, swapdim, ...xz
        [pth_fldr '/' recid '_' fn_gif_insert rseachstr '_zinds' plotinds_z_str  '_meanframe_allrescaled_.gif'], ...
        {[recid_tit ' : ' tit_gif_insert ' meanframe']; ['z inds ' plotinds_z_str]; rescale_str})

    

end

