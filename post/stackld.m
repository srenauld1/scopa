
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
    opt.suffixplt = {}
    opt.sz = []
    opt.stackdtype = 'uint16'
    opt.numslice_withflyback = []
    opt.channel_save = []
    opt.chanuse = 1
    opt.tcropfront = 0
    opt.tcropback = 0
    opt.cropfb = 0
    opt.zerostack = 0
    opt.it = -50;
    opt.iz = []
    opt.smsdspace
    opt.smsdtime = []
    opt.dostats = 0
    opt.dr = []
end

suffixplt = opt.suffixplt;
sz = opt.sz;
stackdtype = opt.stackdtype;
numslice_withflyback = opt.numslice_withflyback;
channel_save = opt.channel_save;
chanuse = opt.chanuse;
tcropfront = opt.tcropfront;
tcropback = opt.tcropback;
cropfb = opt.cropfb;
zerostack = opt.zerostack;
it = opt.it; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
iz = opt.iz; %z indices to plot, empty for all, negative for that number equidistant from all available
smsdspace = opt.smsdspace;
smsdtime = opt.smsdtime; %smooth the stack in time, 0 to skip
dostats = opt.dostats;
dr = opt.dr;

[~,~,~,~,suffixstack,~,~,~,recid,~,pth_fldr] = idmake(pth_stack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to 

if isempty(suffixplt)
    plot_stack_gif = 0;
else
    plot_stack_gif = 1;
end

[~, plot_stack_order] = sort(cellfun(@numel, suffixplt)); %default plot order is shortest to longest suffix (least to most processed, since additional suffixes are added at each stage)
suffixplt = suffixplt(plot_stack_order);
% if ~ismember(suffixstack, suffixplt)
%     sprintf("suffixplt DOES NOT CONTAIN suffixstack, ADDING IT TO suffixplt NOW")
%     suffixplt{end+1} = suffixstack;
% end
suffixplt = unique(suffixplt, 'stable'); %make sure there aren't accidental repeats
if numel(suffixplt)~=1
    suffixplt = cat(1, setxor(suffixstack, suffixplt(:), 'stable'), suffixstack); % make suffixstack last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackld without having to hold plot stacks in memory)
end

cnt = 0;
for spi = 1:numel(suffixplt)
    pthtmp = filefind(fullfile_sibling=pth_stack, suffix=suffixplt{spi});
    if ~isempty(pthtmp)
        cnt = cnt+1;
        pth_stacks(cnt) = pthtmp;
        if isempty(dr)
            display_range_cell{cnt} = [0,1];
        else
            display_range_cell{cnt} = dr.(suffixplt{spi});
        end
        suffixplt_keep{cnt} = suffixplt{spi};
    else
        sprintf("WARNING, NO FILE FOUND WITH SUFFIX: " + suffixplt{spi} + " WITH SAME folder, recdate, fly, and trial as sibling file " + pth_stack +  newline + "SKIPPING IT FOR PLOT")
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
            chanuse=chanuse,...
            cropfb=cropfb, ...
            tcropfront=tcropfront, ...
            tcropback=tcropback, ...
            zerostack=zerostack, ...
            output_datatype=stackdtype);
    else
        error("pth_stacks must end with tif or mat");
    end


    if dostats
        plot_stack_stats(stack, ...
            mask=[], ...
            iz=1:size(stack,3), ...
            it=round(linspace(1, size(stack,4), 100)), ... %1: size(stack,4)
            pthsv_prefix=pth_stacks{spi}(1:end-4))
    end

    if smsdspace 
        for tind = 1:size(stack,4)
            for zind = 1:size(stack,3)
                stack(:,:,zind,tind) = imgaussfilt(stack(:,:,zind,tind), smsdspace);
            end
        end
    end


    if smsdtime
        stacktmp = single(smoothdata(stack, 4, 'gaussian', smsdtime)); %smoothdata will output double so that could be huge and slow
    else
        stacktmp = stack; %this does not require another stack of memory, it just creates a tiny reference to the data
    end

    if plot_stack_gif

        stacktmp_mn = single(mean(stack, 4));

        [iz, izstr] = make_plot_inds(iz, indsall=size(stack,3), label_prefix='z', strdelim='-', printmax=20);
        [it, itstr] = make_plot_inds(it, indsall=size(stack,4), label_prefix='t', strdelim='-', printmax=20);

        stacktmp = single(stacktmp(:,:,iz,it,:));

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

    fn_suffix_insert = strjoin(suffixplt_keep, '_AND_');

    figtitle_prefix = [recid '_' fn_suffix_insert];
    filename_prefix = [pth_fldr figtitle_prefix '_' dr_str '_' izstr '_' itstr ];

    % testing RGB arguments to stackplt
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
    index_labels{3} = iz; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it
    index_labels{4} = it; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it

    if ndims(stackplot{1})==4
        dimorder = [1,2,4,3]; %yxctz    
    else
        dimorder = [1,2,5,4,3]; %yxtz
    end
    stackplt( ...
        stackplot, ...
        pthgif=[filename_prefix '.gif'], ...
        dr=display_range_cell, ...
        fdimnum=3, ...
        dimorder=dimorder, ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels ...
        )
    

    % index_labels{1} = []; %make it empty since you're passing iy 
    % stackplt( ...
    %     stackplot, ...
    %     pthgif=[filename_prefix 'side.gif'], ...
    %     dr=display_range_cell, ...
    %     fdimnum=3, ...
    %     dimorder=[3,2,1,4], ...
    %     iy=round(linspace(1,size(stackplot{1},1), 8)),...
    %     title_prefix=figtitle_prefix, ...
    %     index_labels=index_labels ...
    %     )

    stackplt( ...
        stackplot_mn, ...
        pthgif=[filename_prefix 'meant_.gif'], ...
        dr=display_range_cell, ...
        fdimnum=2, ...
        dimorder=[1:ndims(stackplot_mn{1})], ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels([1:ndims(stackplot_mn{1})]) ...
        )

end



