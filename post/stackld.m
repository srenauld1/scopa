
%% input

% load stacks output by scopa 'pre' pipeline, and raw stack output by scanimage
% if mat doesn't exist, will read tif and save as mat (reading large tif requires TIFFStack library)
% will plot all stacks as a single movie, concatenated along first dim, and
% save as gif (user can choose z and t indices)
% converts raw scanimage tif from int16 to uint16
% all scopa output stacks should be uint16, but if not they are converted to uint16


function stack = stackld(pth_stack, opt)


arguments
    pth_stack
    opt.suffixes_plot = {}
    opt.sz = []
    opt.stack_make_datatype = 'uint16'
    opt.numslice_withflyback = []
    opt.channel_save = []
    opt.channel_use = 1
    opt.tcropfront = 0
    opt.tcropback = 0
    opt.crop_flyback = 0
    opt.zero_stack = 0
    opt.it = -50;
    opt.iz = []
    opt.smsdspace
    opt.smooth_window_temporal = []
    opt.do_plot_stack_stats = 0
    opt.display_range = []
end

suffixes_plot = opt.suffixes_plot;
sz = opt.sz;
stack_make_datatype = opt.stack_make_datatype;
numslice_withflyback = opt.numslice_withflyback;
channel_save = opt.channel_save;
channel_use = opt.channel_use;
tcropfront = opt.tcropfront;
tcropback = opt.tcropback;
crop_flyback = opt.crop_flyback;
zero_stack = opt.zero_stack;
it = opt.it; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
iz = opt.iz; %z indices to plot, empty for all, negative for that number equidistant from all available
smsdspace = opt.smsdspace;
smooth_window_temporal = opt.smooth_window_temporal; %smooth the stack in time, 0 to skip
do_plot_stack_stats = opt.do_plot_stack_stats;
display_range = opt.display_range;

[~,~,~,~,suffix_analysis,~,~,~,recid,~,pth_fldr] = get_ids_a2p(pth_stack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to 

if isempty(suffixes_plot)
    plot_stack_gif = 0;
else
    plot_stack_gif = 1;
end

[~, plot_stack_order] = sort(cellfun(@numel, suffixes_plot)); %default plot order is shortest to longest suffix (least to most processed, since additional suffixes are added at each stage)
suffixes_plot = suffixes_plot(plot_stack_order);
% if ~ismember(suffix_analysis, suffixes_plot)
%     sprintf("suffixes_plot DOES NOT CONTAIN suffix_analysis, ADDING IT TO suffixes_plot NOW")
%     suffixes_plot{end+1} = suffix_analysis;
% end
suffixes_plot = unique(suffixes_plot, 'stable'); %make sure there aren't accidental repeats
if numel(suffixes_plot)~=1
    suffixes_plot = cat(1, setxor(suffix_analysis, suffixes_plot(:), 'stable'), suffix_analysis); % make suffix_analysis last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackld without having to hold plot stacks in memory)
end

cnt = 0;
for spi = 1:numel(suffixes_plot)
    pthtmp = find_preprocessed_files(fullfile_sibling=pth_stack, suffix=suffixes_plot{spi});
    if ~isempty(pthtmp)
        cnt = cnt+1;
        pth_stacks(cnt) = pthtmp;
        if isempty(display_range)
            display_range_cell{cnt} = [0, 1];
        else
            display_range_cell{cnt} = display_range.(suffixes_plot{spi});
        end
        suffixes_plot_keep{cnt} = suffixes_plot{spi};
    else
        sprintf("WARNING, NO FILE FOUND WITH SUFFIX: " + suffixes_plot{spi} + " WITH SAME folder, recdate, fly, and trial as sibling file " + pth_stack +  newline + "SKIPPING IT FOR PLOT")
    end
end

dr_str = vec(cellfun(@num2str, display_range_cell, 'UniformOutput', false))';
dr_str = cellfun(@(x,y,z) regexprep(x,y,z), dr_str, repelem({' +'}, numel(dr_str)), repelem({'to'}, numel(dr_str)), 'UniformOutput', false);
dr_str = cellfun(@(x,y,z) strrep(x,y,z), dr_str, repelem({'.'}, numel(dr_str)), repelem({'p'}, numel(dr_str)), 'UniformOutput', false);
dr_str = ['DR_' strjoin(dr_str, '_AND_')];



%%  loop over suffixes, loading and concatenating


stackplot = cell(numel(pth_stacks), 1); %make it cell column so first dim is cat when cell2mat below
stackplot_mn = cell(numel(pth_stacks), 1); %make it cell column so first dim is cat when cell2mat below


for spi = 1:numel(pth_stacks)

    if endsWith(pth_stacks{spi}, '.mat')
        stack = struct2cell(load(pth_stacks{spi})); %make sure loaded stack is named 'stack'
        stack = stack{1};
    elseif endsWith(pth_stacks{spi}, '.tif')
        stack = tif2mat(pth_stacks{spi}, ...
            sz_yxzt=sz, ...
            numslice_withflyback=numslice_withflyback, ...
            channel_save=channel_save,...
            channel_use=channel_use,...
            crop_flyback=crop_flyback, ...
            tcropfront=tcropfront, ...
            tcropback=tcropback, ...
            zero_stack=zero_stack, ...
            output_datatype=stack_make_datatype);
    else
        error("pth_stacks must end with tif or mat");
    end


    if do_plot_stack_stats
        plot_stack_stats(stack, ...
            mask=[], ...
            iz=1:size(stack,3), ...
            it=round(linspace(1, size(stack,4), 100)), ... %1: size(stack,4)
            pthsv_prefix=pth_stacks{spi}(1:end-4))
    end

    if smsdspace %  && contains(pth_stacks{spi}, {'raw_.', 'cmrg_.'})
        for tind = 1:size(stack,4)
            for zind = 1:size(stack,3)
                stack(:,:,zind,tind) = imgaussfilt(stack(:,:,zind,tind), smsdspace);
            end
        end
    end

    if plot_stack_gif

        stacktmp_mn = single(mean(stack, 4));

        if smooth_window_temporal
            stacktmp = single(smoothdata(stack, 4, 'gaussian', smooth_window_temporal)); %smoothdata will output double so that could be huge and slow
        else
            stacktmp = stack; %this does not require another stack of memory, it just creates a tiny reference to the data
        end

        [iz, izstr] = make_plot_inds(iz, indsall=size(stack,3), label_prefix='z', strdelim='-', printmax=20);
        [it, itstr] = make_plot_inds(it, indsall=size(stack,4), label_prefix='t', strdelim='-', printmax=20);

        stacktmp = single(stacktmp(:,:,iz,it));

        if ~strcmp(pth_stack, pth_stacks{spi}) %if it's the stack for analysis outside this function
            stack = [];
        end

        stackplot{spi} = stacktmp;
        stackplot_mn{spi} = stacktmp_mn;

        clear stacktmp stacktmp_mn

    end
end


%% plot

if plot_stack_gif

    fn_suffix_insert = strjoin(suffixes_plot_keep, '_AND_');

    figtitle_prefix = [recid '_' fn_suffix_insert];
    filename_prefix = [pth_fldr figtitle_prefix '_' dr_str '_' izstr '_' itstr ];

    % testing RGB arguments to stack2fig
    % for spp = 1:size(stackplot{1}, 3)
    %     for sppp = 1:size(stackplot{1}, 4)
    %         stackplotnew(:,:,spp,sppp,:) = ind2rgb(stackplot{1}(:,:,spp,sppp), gray(256));
    %     end
    % end
    % stackplot{1} = stackplotnew;
    % stackplot{2} = stackplotnew;


    %test thresholding stack prior to plot
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

    index_labels = arrayfun(@(x) 1:x(end), size(stackplot{1}), 'UniformOutput', false); % setup labels for stack that has already been subset;
    index_labels{3} = iz; % subset the (possibly) large stacks before stack2fig, rather than cat them and make a giant variable then subset in stack2fig with ix,iy,iz,it
    index_labels{4} = it; % subset the (possibly) large stacks before stack2fig, rather than cat them and make a giant variable then subset in stack2fig with ix,iy,iz,it

    stack2fig( ...
        stackplot, ...
        pthgif=[filename_prefix '.gif'], ...
        display_range=display_range_cell, ...
        fdimnum=3, ...
        dimorder=[1,2,3,4], ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels ...
        )
    

    % index_labels{1} = []; %make it empty since you're passing iy 
    % stack2fig( ...
    %     stackplot, ...
    %     pthgif=[filename_prefix 'side.gif'], ...
    %     display_range=display_range_cell, ...
    %     fdimnum=3, ...
    %     dimorder=[3,2,1,4], ...
    %     iy=round(linspace(1,size(stackplot{1},1), 8)),...
    %     title_prefix=figtitle_prefix, ...
    %     index_labels=index_labels ...
    %     )

    stack2fig( ...
        stackplot_mn, ...
        pthgif=[filename_prefix 'meant_.gif'], ...
        display_range=display_range_cell, ...
        fdimnum=2, ...
        dimorder=[1:ndims(stackplot_mn{1})], ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels([1:ndims(stackplot_mn{1})]) ...
        )

end


if ndims(stack)~=4
    error(sprintf("ERROR, \nTHIS PIPELINE REQUIRES stack TO BE 4D (xyzt), EVEN IF SOME DIM (e.g., 3rd dim z) ARE SINGLETON"))
end


