
%% input

% this will load stacks output by scopa pipeline, and raw stack output by scan image 

% if mat doesn't exist, will read tif and save as mat (read large tif
% requires TIFFStack library)
%
% will plot all stacks as a single movie, concatenated along first dim, and
% save as gif (user can choose z and t indices, can be nonconsecutive)

% will also plot rescaled movie, and mean movie with and without rescaling
% can optionally rescale all subplots to same range
% nans inserted above each subplot to separate them clearly (nan_numlines)

% this script converts raw scanimage tif from int16 to uint16
% all scopa output stacks should be uint16, but if not they are converted
% if possible without clipping 


function stack = vis_tif(md, pth_use_mat, pth_stacks_prefix, ...
    pth_fldr, recid, use_hires, pth_hires_prefix, nan_numlines, ...
    rescale_each_subplot, rescalefac_wholeplot, ...
    plotinds_t, plotinds_z, ...
    swapdim, smooth_window_temporal, ...
    plot_stack_stats, plot_stack_order, plot_stack_gif, ncolgif)



sz = md.sz_o;

if isempty(plotinds_z)
    plotinds_z = 1:sz(3);
elseif plotinds_z<0
    if -plotinds_z<sz(3)
        plotinds_z = round(linspace(1, sz(3), -plotinds_z));
    else
        plotinds_z = 1:sz(3);
    end
end

if md.croptimeinds
    keepinds_t = md.croptimeinds(1)+1:sz(4)-md.croptimeinds(2);
else
    keepinds_t = 1:sz(4);
end

if isempty(plotinds_t)
    plotinds_t = 1:length(keepinds_t);
elseif plotinds_t<0
    if -plotinds_t<length(keepinds_t)
        plotinds_t = round(linspace(1, length(keepinds_t), -plotinds_t));
    else
        plotinds_t = 1:length(keepinds_t);
    end
elseif mod(plotinds_t, 1)~=0
    seglength = fix(plotinds_t);
    factmp = 10^(numel(num2str(plotinds_t))-numel(num2str(seglength))-1);
    timeseries_numsegments = mod(plotinds_t, 1)*factmp;
    timeseries_numsegments = round(timeseries_numsegments);
    segspacing = floor(length(keepinds_t)/timeseries_numsegments);
    plotinds_t = [1:seglength]+segspacing*([1:timeseries_numsegments]'-1)+segspacing-seglength;
    plotinds_t = vec(plotinds_t.');
    if numel(plotinds_t)>length(keepinds_t) | any(plotinds_t<0)
        disp("warning, seglength*timeseries_numsegments exceeds num samples, plotting all samples")
        plotinds_t = 1:length(keepinds_t);
    end
end

if length(plotinds_z)>20
    plotinds_z_str = [num2str(plotinds_z(1)) 'to' num2str(plotinds_z(end))];
else
    plotinds_z_str = sprintf('%.0f,', plotinds_z);
    plotinds_z_str = plotinds_z_str(1:end-1);% strip final comma
end
rescale_str = [' rescale ' num2str(rescalefac_wholeplot(1)) ' ' num2str(rescalefac_wholeplot(2))];

if rescale_each_subplot
    rseachstr = 'eachrescaled';
else
    rseachstr = '';
end


stackall = cell(length(pth_stacks_prefix), 1); %make it cell column so first dim is cat when cell2mat below
stackall_mn = cell(length(pth_stacks_prefix), 1); %make it cell column so first dim is cat when cell2mat below
fn_gif_insert = cell(length(pth_stacks_prefix), 1);


%%  loop over suffixes, loading and concatenating


for spi = 1:length(pth_stacks_prefix)

    if ~isempty(pth_stacks_prefix{spi}) %if it's not empty it means either mat or tif or both exist 

        [~, filnam, ~] = fileparts(pth_stacks_prefix{spi});
        pth_stack_tif = [pth_stacks_prefix{spi} '.tif'];
        pth_stack_mat = [pth_stacks_prefix{spi} '.mat'];

        try

            stack = struct2cell(load(pth_stack_mat));
            stack = stack{1};

        catch

            if ~isempty(regexp(filnam, 'raw')) || ~isempty(regexp(filnam, 'hires'))
                size_z_read_from = md.numslice_withflyback; %raw and hires includes flyback
            else
                size_z_read_from = sz(3);
            end
            size_t_read_from = sz(4);
            inds_z_read_from = 1:sz(3); %can choose any subset of z (e.g. passing 1:sz(3) will skip flyback frames for raw and hires, for example, do 1:size_z_read_from to read fluback frames), does not have to be contiguous
            inds_t_read_from = 1:size_t_read_from; %can choose any subset of t, does not have to be contiguous
            size_read_to = [length(inds_t_read_from), length(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed, permute within read_tif_tzyx

            stack = read_tif_tzyx(pth_stack_tif, ...
                size_read_to, size_z_read_from, size_t_read_from, ...
                inds_z_read_from, inds_t_read_from);

            datmin = min(stack(:));
            datmax = max(stack(:));
            if ~isa(stack, 'uint16')
                stack = single(stack);
            end
            stack = stack - double(datmin);
            if ~isa(stack, 'uint16')
                if datmax > 2^16-1
                    "ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE"
                    error
                end
                stack = uint16(stack);
            end

            if md.croptimeinds
                stack = stack(:,:,:,keepinds_t);
            end

            save(pth_stack_mat, 'stack', '-v7.3', '-mat')

        end

        stacktmp_mn = single(mean(stack, 4));
        stacktmp = single(stack(:,:,plotinds_z, plotinds_t));

        if plot_stack_stats
            tindz = 1:length(keepinds_t);
            numframes_subset_statsplots = 100;
            tindz_sub = round(linspace(1, keepinds_t, numframes_subset_statsplots));
            plots_imdata(single(stack(:,:,:,tindz)), [], sindz, tindz, tindz_sub, size(tmp), pth_stack_mat)
        end

        if smooth_window_temporal
            stack = smoothdata(stack, 4, 'gaussian', smooth_window_temporal); %ideally this comes before plot indexing but smoothdata will output double so that could be huge and not worth it
        end

        if plot_stack_gif
            if ~strcmp(pth_stack_mat, pth_use_mat) %if it's the stack for analysis outside this function
                stack = [];
            end

            if rescale_each_subplot
                stacktmp = rescale(stacktmp);
                stacktmp_mn = rescale(stacktmp_mn);
            end
            stackall{spi} = single(ones([nan_numlines+sz(1), sz(2), length(plotinds_z), length(plotinds_t)]));
            stackall_mn{spi} = single(ones([nan_numlines+sz(1), sz(2), sz(3)]));
            stackall{spi}(nan_numlines+1:end, :, :, :) = stacktmp;
            stackall_mn{spi}(nan_numlines+1:end, :, :) = stacktmp_mn;
            clear stacktmp*
            fn_gif_insert{spi} = filnam;
        end
    end
end


%% plot

if plot_stack_gif

    stackall = stackall(plot_stack_order);
    stackall = cell2mat(stackall(~cellfun( @isempty, stackall )));
    stackall_mn = stackall_mn(plot_stack_order);
    stackall_mn = cell2mat(stackall_mn(~cellfun( @isempty, stackall_mn )));
    fn_gif_insert = strjoin(fn_gif_insert(~cellfun( @isempty, fn_gif_insert )), '_AND_');

    title_insert = strrep(fn_gif_insert, '_', ' ');
    recid_title = strrep(recid, '_', ' ');
    filename_prefix = [pth_fldr recid '_' fn_gif_insert rseachstr '_zinds' plotinds_z_str '_' ];
    figtitle_prefix = {[recid_title ' : ' title_insert]; ['z inds ' plotinds_z_str]; rescale_str};

    plot_gif_fast(rescale(stackall, rescalefac_wholeplot(1), rescalefac_wholeplot(2)), ...
        ncolgif, swapdim, ...
        [filename_prefix '_.gif'], ...
        figtitle_prefix, plotinds_z, plotinds_t)

    plot_gif_fast(rescale(stackall_mn, rescalefac_wholeplot(1), rescalefac_wholeplot(2)), ...
        ncolgif, swapdim, ...
        [filename_prefix '_meanframe_.gif'], ...
        [figtitle_prefix; '_meanframe_.gif'])


end


if any(use_hires)

    %it's not straightforward to plot hires stack along with lores using
    %vis_tif as it is written above (because their z resolutions are
    %different) it's more readable to just pass it separately, here,
    % to read, save, and plot the hires stack by itself

    [ST, ~] = dbstack();
    if length(cell2mat( strfind( {ST(:).name}, 'vis_tif' ) ) ) == 1 %since this is called recursively, make sure you're not in an infinite loop, use_hires_new==0 is meant to prevent as well)
        
        %it's okay to overwrite these since none are output from this function
        use_hires = 0;
        md = md.md_hires;
        pth_use_mat_hires = {''};
        pth_stacks_prefix = {pth_hires_prefix};
        plotinds_t = [1];
        plotinds_z = [];
        smooth_window_temporal = [];

        %no need to call with output, purpose is just to read hires tif,
        %save as mat, and optionally plot . . . hires will be loaded later in
        %load_hires_stack.m
        vis_tif(md, pth_use_mat_hires, pth_stacks_prefix, ...
            pth_fldr, recid, use_hires, pth_hires_prefix, nan_numlines, ...
            rescale_each_subplot, rescalefac_wholeplot, ...
            plotinds_t, plotinds_z, ...
            swapdim, smooth_window_temporal, ...
            plot_stack_stats, plot_stack_order, plot_stack_gif, ncolgif);


    end
end

