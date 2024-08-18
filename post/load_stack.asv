
%% input

% load stacks output by scopa 'pre' pipeline, and raw stack output by scanimage
% if mat doesn't exist, will read tif and save as mat (reading large tif requires TIFFStack library)
% will plot all stacks as a single movie, concatenated along first dim, and
% save as gif (user can choose z and t indices)
% converts raw scanimage tif from int16 to uint16
% all scopa output stacks should be uint16, but if not they are converted to uint16


function stack = load_stack(sz, numslice_withflyback, pth, opts, recid)

pth_fldr = pth.fldr;
pth_stack_analysis = pth.stack_analysis;
pth_stacks_prefix = pth.stacks_prefix;

plot_stack_gif = opts.gif.plot_stack_gif;
plotinds.t = opts.gif.plotinds.t; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
plotinds.z = opts.gif.plotinds.z; %z indices to plot, empty for all, negative for that number equidistant from all available
display_range = opts.gif.display_range; %combined plot rescale arguments, [lower, upper]
smooth_window_temporal = opts.gif.smooth_window_temporal; %smooth the stack in time, 0 to skip
plot_stack_stats = opts.plot_stack_stats;

max_num_inds_to_print = 20;

if ~isfield(opts.gif, 'plot_stack_order')
    plot_stack_order = 1;
else
    plot_stack_order = opts.gif.plot_stack_order;
end

keepinds_t = opts.numsamp_crop_t_front+1:sz(4)-opts.numsamp_crop_t_back; %same as all t inds (1:sz(4)) if numsamp_crop_t_front and numsamp_crop_t_back are both 0

label_prefix = 't';
[plotinds.t, plotinds.t_str] = make_plot_inds(keepinds_t, plotinds.t, label_prefix, max_num_inds_to_print);

label_prefix = 'z';
[plotinds.z, plotinds.z_str] = make_plot_inds(sz(3), plotinds.z, label_prefix, max_num_inds_to_print);

dr_str = vec(cellfun(@num2str, display_range, 'UniformOutput', false))';
dr_str = cellfun(@(x,y,z) regexprep(x,y,z), dr_str, repelem({' +'}, numel(dr_str)), repelem({'to'}, numel(dr_str)), 'UniformOutput', false);
dr_str = cellfun(@(x,y,z) strrep(x,y,z), dr_str, repelem({'.'}, numel(dr_str)), repelem({'p'}, numel(dr_str)), 'UniformOutput', false);
dr_str = ['DR_' strjoin(dr_str, '_AND_')];


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
            stack = tif2mat(pth_stack_tif, numslice_withflyback, sz, opts.crop_flyback, opts.zero_stack, keepinds_t);
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

            stacktmp = single(stacktmp(:,:,plotinds.z, plotinds.t));

            if ~strcmp(pth_stack_mat, pth_stack_analysis) %if it's the stack for analysis outside this function
                stack = [];
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

    figtitle_prefix = [recid '_' fn_suffix_insert dr_str];
    filename_prefix = [pth_fldr figtitle_prefix '_' plotinds.z_str '_' plotinds.t_str ];

    % testing RGB arguments to stack2fig
    % for spp = 1:size(stackplot{1}, 3)
    %     for sppp = 1:size(stackplot{1}, 4)
    %         stackplotnew(:,:,spp,sppp,:) = ind2rgb(stackplot{1}(:,:,spp,sppp), gray(256));
    %     end
    % end
    % stackplot{1} = stackplotnew;
    % stackplot{2} = stackplotnew;


    % for spi = 1:numel(stackplot)
    %     [histdt, histx] = hist(stackplot_mn{spi}(:), 1000);
    %     thrbin_tri = triangle_threshold(histdt, 'R', 1);
    %     thr_tri = histx(thrbin_tri);
    %     bdsb = find(stackplot_mn{spi}<thr_tri);
    %     mntmp = min(stackplot_mn{spi}(:));
    %     stdtmp = zeros(size(stackplot{spi}, 4), numel(bdsb), 'uint16');
    %     for fr = 1:size(stackplot{spi}, 4)
    %         tmpfr = stackplot{spi}(:,:,:,fr);
    %         stdtmp(fr,:) = tmpfr(bdsb);
    %         tmpfr(bdsb) = mntmp;
    %         stackplot{spi}(:,:,:,fr) = tmpfr;
    %     end
    %     stdtmp = mean(std(single(stdtmp))); %std over time of "unlabeled" pixels 
    % end

    fngif = [filename_prefix '.gif'];
    cmap = gray(256);
    framenumdims = 3;
    dimorder = [1,2,3,4];
    figsidelen = 0.75;
    index_labels = arrayfun(@(x) 1:x(end), size(stackplot{1}), 'UniformOutput', false);
    index_labels{3} = plotinds.z;
    index_labels{4} = plotinds.t;
    gif_visibility = 'on';
    stack2fig(stackplot, fngif, gif_visibility, [], [], [], [], cmap, display_range, framenumdims, dimorder, figtitle_prefix, index_labels, figsidelen)

    fngif = [filename_prefix 'meant_.gif'];
    framenumdims = 2;
    dimorder = [1,2,3];
    index_labels = index_labels(1:3);
    stack2fig(stackplot_mn, fngif, gif_visibility, [], [], [], [], cmap, display_range, framenumdims, dimorder, figtitle_prefix, index_labels, figsidelen)

    

end


if ndims(stack)~=4
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stack TO BE 4D (xyzt), EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON"))
end


