
%% input

% load stacks output by scopa pipeline, and raw stack output by scan image

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


function stack = load_stack(md, pth, opts, recid)

pth_fldr = pth.fldr;
pth_stack_analysis = pth.stack_analysis;
pth_stacks_prefix = pth.stacks_prefix;

plot_stack_gif = opts.gif.plot_stack_gif;
plotinds_t = opts.gif.plotinds_t; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
plotinds_z = opts.gif.plotinds_z; %z indices to plot, empty for all, negative for that number equidistant from all available
rescale_each_stack = opts.gif.rescale_each_stack; %rescale each subplot to same range 0-1 before combining
display_range = opts.gif.display_range; %combined plot rescale arguments, [lower, upper]
smooth_window_temporal = opts.gif.smooth_window_temporal; %smooth the stack in time, 0 to skip
plot_stack_stats = opts.plot_stack_stats;

max_num_inds_to_print = 20;

if ~isfield(opts.gif, 'plot_stack_order')
    plot_stack_order = 1;
else
    plot_stack_order = opts.gif.plot_stack_order;
end

sz = md.sz_o;

label_prefix = 'z';
[plotinds_z, plotinds_z_str] = make_plot_inds(sz(3), plotinds_z, label_prefix, max_num_inds_to_print);

if md.croptimeinds
    keepinds_t = md.croptimeinds(1)+1:sz(4)-md.croptimeinds(2);
else
    keepinds_t = 1:sz(4);
end

label_prefix = 't';
[plotinds_t, plotinds_t_str] = make_plot_inds(keepinds_t, plotinds_t, label_prefix, max_num_inds_to_print);

if isequal(display_range, [0 1])
    dr_str = 'DRfull';
else
    dr_str = ['DR' num2str(display_range(1)) 'to' num2str(display_range(2))];
end

if rescale_each_stack
    rs_str = 'RSeach';
else
    rs_str = 'RSnone';
end

stackplot = cell(numel(pth_stacks_prefix), 1); %make it cell column so first dim is cat when cell2mat below
stackplot_mn = cell(numel(pth_stacks_prefix), 1); %make it cell column so first dim is cat when cell2mat below


%%  loop over suffixes, loading and concatenating


for spi = 1:numel(pth_stacks_prefix)

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
            size_read_to = [numel(inds_t_read_from), numel(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed, permute within read_tif_tzyx

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


        if plot_stack_stats
            sindz = 1:size(stack, 3);
            tindz = 1:numel(keepinds_t);
            numframes_subset_statsplots = 100;
            tindz_sub = round(linspace(1, numel(keepinds_t), numframes_subset_statsplots));
            plots_imdata(single(stack(:,:,:,tindz)), [], sindz, tindz, tindz_sub, size(stack), pth_stack_mat)
        end

        if plot_stack_gif

            stacktmp_mn = single(mean(stack, 4));

            if smooth_window_temporal
                stacktmp = single(smoothdata(stack, 4, 'gaussian', smooth_window_temporal)); %smoothdata will output double so that could be huge and slow
            else
                stacktmp = stack; %this does not double RAM usage
            end

            stacktmp = single(stacktmp(:,:,plotinds_z, plotinds_t));

            if ~strcmp(pth_stack_mat, pth_stack_analysis) %if it's the stack for analysis outside this function
                stack = [];
            end

            if rescale_each_stack
                stacktmp = rescale(stacktmp);
                stacktmp_mn = rescale(stacktmp_mn);
            end

            stackplot{spi} = stacktmp;
            stackplot_mn{spi} = stacktmp_mn;

            clear stacktmp*
            fn_suffix_insert{spi} = erase(filnam, recid);
        end
    end
end


%% plot

if plot_stack_gif

    stackplot = stackplot(plot_stack_order);
    stackplot = stackplot(~cellfun( @isempty, stackplot ));
    stackplot_mn = stackplot_mn(plot_stack_order);
    stackplot_mn = stackplot_mn(~cellfun( @isempty, stackplot_mn ));

    fn_suffix_insert = strjoin(fn_suffix_insert(~cellfun( @isempty, fn_suffix_insert )), '_AND_');

    figtitle_prefix = [recid '_' fn_suffix_insert rs_str dr_str];
    filename_prefix = [pth_fldr figtitle_prefix '_' plotinds_z_str '_' plotinds_t_str ];

    % testing RGB arguments to stack2fig 
    % for spp = 1:size(stackplot{1}, 3)
    %     for sppp = 1:size(stackplot{1}, 4)
    %         stackplotnew(:,:,spp,sppp,:) = ind2rgb(stackplot{1}(:,:,spp,sppp), gray(256));
    %     end
    % end
    % stackplot{1} = stackplotnew;
    % stackplot{2} = stackplotnew;

    fngif = [filename_prefix '.gif'];
    cmap = gray(256);
    framenumdims = 3;
    dimorder = [1,2,3,4];
    figsidelen = 0.75;
    index_labels = arrayfun(@(x) 1:x(end), size(stackplot{1}), 'UniformOutput', false);
    index_labels{3} = plotinds_z;
    index_labels{4} = plotinds_t;
    stack2fig(stackplot, fngif, cmap, display_range, framenumdims, dimorder, figtitle_prefix, index_labels, figsidelen)

    fngif = [filename_prefix 'meant_.gif'];
    framenumdims = 2;
    dimorder = [1,2,3];
    index_labels = index_labels(1:3);
    stack2fig(stackplot_mn, fngif, cmap, display_range, framenumdims, dimorder, figtitle_prefix, index_labels, figsidelen)


end


if ndims(stack)~=4
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stack TO BE 4D (xyzt), EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON"))
end


