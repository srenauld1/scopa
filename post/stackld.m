
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
    opt.suffixplt = []
    opt.sz = []
    opt.stackdtype = 'uint16'
    opt.numslice_withflyback = []
    opt.channel_save = []
    opt.chanuse = 1
    opt.tcrop = [0 0]
    opt.cropfb = 0
    opt.zerostack = 0
    opt.clip = []
    opt.it = -50;
    opt.iz = []
    opt.smlenpx
    opt.smlensec = []
    opt.dostats = 0
    opt.dr = []
    opt.imrate = []
    opt.doplt = []
end

suffixplt = opt.suffixplt;
sz = opt.sz;
stackdtype = opt.stackdtype;
numslice_withflyback = opt.numslice_withflyback;
channel_save = opt.channel_save;
chanuse = opt.chanuse;
tcrop = opt.tcrop;
cropfb = opt.cropfb;
zerostack = opt.zerostack;
clip = opt.clip;
it = opt.it; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
iz = opt.iz; %z indices to plot, empty for all, negative for that number equidistant from all available
smlenpx = opt.smlenpx;
smlensec = opt.smlensec; %smooth the stack in time, 0 to skip
dostats = opt.dostats;
dr = opt.dr;
imrate = opt.imrate;
doplt = opt.doplt;

suffixplt = convertStringsToChars(suffixplt);
if ~isempty(suffixplt) && ~iscell(suffixplt)
    suffixplt = {suffixplt};
end

if isempty(doplt)
    doplt = any(strcmp('sld', glb('plt')));
end

if ~doplt
    fprintf("in stackld, doplt or glb('plt') is set to 0, so any stacks listed in suffixplt will not be plotted" + newline)
    suffixplt = [];
end


id = idmake(pth_stack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to
suffixstack = id.suffix;
recid = id.recid;
dirstack = id.dirstack;

if ~iscell(suffixstack)
    suffixstack = {suffixstack};
end

if ~isempty(suffixplt)
    if numel(dr)>numel(suffixplt)
        fprintf("dr is longer than suffixplt; using first " + num2str(numel(suffixplt)) + " elements from dr" + newline)
        dr = dr(1:numel(suffixplt));
    elseif numel(dr)<numel(suffixplt)
        if numel(dr)==1
            dr = repelem(dr, numel(suffixplt));
        else
            error("dr is shorter than suffixplt, but is not length 1; you must supply " + num2str(numel(suffixplt)) + " elements in dr, or one elements to apply to all suffixplt")
        end
    end
end
if ~isempty(suffixplt) && ~ismember(suffixstack, suffixplt)
    fprintf("note: suffixplt DOES NOT CONTAIN suffixstack" + newline)
end
if numel(suffixplt)~=numel(unique(suffixplt)) %make sure there aren't accidental repeats
    error("you have at least one repeated suffixplt; there cannot be any repeated suffixplt")
end

indssrc = find(strcmp(suffixstack, suffixplt));
if isempty(suffixplt)
    dr = dr(1);
    suffixld = suffixstack;
else
    if any(strcmp(suffixstack, suffixplt))
        suffixld = [setxor(suffixstack, suffixplt, 'stable') suffixstack]; % make suffixstack last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackld without having to hold plot stacks in memory)
    else
        suffixld = [suffixplt suffixstack]; % make suffixstack last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackld without having to hold plot stacks in memory)
    end
end
indsdst = find(strcmp(suffixstack, suffixld));
indstmp = setxor(1:numel(dr), indssrc);
indsnew = [indstmp(1:indsdst-1) indssrc indstmp(indsdst:end)];
dr = dr(indsnew);

cnt = 0;
for spi = numel(suffixld):-1:1 %backwards so we don't have to make new suffixplt, dr, and indsmissing
    pthtmp = stackfind(pthsib=pth_stack, suffix=suffixld{spi});
    if ~isempty(pthtmp)
        cnt = cnt+1;
        pth_stacks(cnt) = pthtmp;
    else
        if any(strcmp(suffixld{spi}, suffixplt))
            suffixplt(strcmp(suffixld{spi}, suffixplt)) = [];
            dr(spi) = [];
            indsnew(spi) = [];
        end
        suffixld(spi) = [];
    end
end
pth_stacks = flip(pth_stacks); %since spi was backwards above, and pth_stacks was indexed with a loop increment cnt

if isempty(suffixplt) %if it's empty after looking for files, set doplt to 0
    fprintf(newline + "in stackld, suffixplt is empty (either because the user made it empty, or none of the stacks listed in suffixplt were found), so doplt is now set to 0, regardless of how it was set entering stackld" + newline)
    doplt = 0;
end

%%  loop over suffixes, loading and concatenating


stacktmp = cell(numel(suffixplt), 1); %make it cell column so first dim is cat when cell2mat below
stackmntmp = cell(numel(suffixplt), 1); %make it cell column so first dim is cat when cell2mat below


cnt = 0;
for spi = 1:numel(pth_stacks)

    if endsWith(pth_stacks{spi}, '.mat')
        stack = struct2cell(load(pth_stacks{spi})); %make sure loaded stack is named 'stack'
        stack = stack{1};
        chanusetmp = chanuse(chanuse<=size(stack,5)); %only use requested channels that exist, if you request one channel that doesn't exist this will error
        stack = stack(:,:,:,:,chanusetmp);
    elseif endsWith(pth_stacks{spi}, '.tif')
        stack = tif2mat(pth_stacks{spi}, ...
            sz_yxzt=sz, ...
            numslice_withflyback=numslice_withflyback, ...
            channel_save=channel_save,...
            cropfb=cropfb, ...
            tcrop=tcrop);
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

    if any(clip)
        stack = stackclip(stack, clip=clip);
    end
    if zerostack
        stack = stack - min(stack, [], [1 2 3 4], 'omitmissing'); %subtract min for each channel
    end
    if ~isa(stack, stackdtype)
        stack = stacktype(stack, stackdtype);
    end
    if any(smlenpx) || any(smlensec)
        stack = stacksmooth(stack, method={'gaussian', 'movmedian'}, smlenpx=smlenpx, smlensec=smlensec, imrate=imrate);
    end


    if doplt && any(strcmp(suffixld{spi}, suffixplt))

        cnt = cnt+1;

        if cnt==1
            [iz, izstr] = indsmake(iz, indsall=size(stack,3), label_prefix='z');
            [it, itstr] = indsmake(it, indsall=size(stack,4), label_prefix='t');
        end

        stacktmp{cnt, 1} = stack(:,:,iz,it,:); %make sure it's indexed into first dimension
        stackmntmp{cnt, 1} = mean(stack, 4, 'native');  %make sure it's indexed into first dimension

        if ~strcmp(pth_stack, pth_stacks{spi})
            stack = []; %remove unless it's the stack for analysis outside this function
        end

    end
end


%% plot

if doplt

    [~, plot_stack_order] = sort(indsnew);

    stacktmp = stacktmp(plot_stack_order);
    dr = dr(plot_stack_order);

    fn_suffix_insert = strjoin(suffixplt, '_AND_');

    figtitle_prefix = [recid '_' fn_suffix_insert];
    filename_prefix = [dirstack figtitle_prefix]; % '_' izstr '_' itstr ];

    index_labels = arrayfun(@(x) 1:x(end), size(stacktmp{1}), 'UniformOutput', false); % setup labels for stack that has already been subset;
    index_labels{3} = iz; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it
    index_labels{4} = it; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it

    numchan = cellfun(@(x) size(x,5), stacktmp);
    if numel(unique(numchan))~=1
        if numchan(strcmp(suffixplt, 'raw'))==2 && any(numchan(~strcmp(suffixplt, 'raw'))==1)
            fprintf("you may have discarded a channel in creating some stacks besides raw, removing channel 2 from the temporary raw plotting stack so it can be plotted with any single-channel stack" + newline)
            stacktmp{strcmp(suffixplt, 'raw')} = stacktmp{strcmp(suffixplt, 'raw')}(:,:,:,:,1);
        else
            error("all stacks must have same number of channels")
        end
    end

    if exist('shifts', 'var')
        shifts_yxz = shifts;
        shifts_yxz(:,1) = shifts(:,2);
        shifts_yxz(:,2) = shifts(:,1);
        figtitle_suffix = shifts_yxz;
    else
        figtitle_suffix = [];
    end

    stackplt( ...
        stacktmp, ...
        pthgif=[filename_prefix '_.gif'], ...
        dr=dr, ...
        title_prefix=figtitle_prefix, ...
        title_suffix=figtitle_suffix, ...
        index_labels=index_labels ...
        )

    stackplt( ...
        stackmntmp, ...
        pthgif=[filename_prefix '_meant_.gif'], ...
        dr=dr, ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels([1:ndims(stackmntmp{1})]) ...
        )

end



