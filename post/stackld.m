
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
    opt.tcrop = [0 0]
    opt.cropfb = 0
    opt.zerostack = 0
    opt.it = -50;
    opt.iz = []
    opt.smsdspace
    opt.smsdtimesec = []
    opt.dostats = 0
    opt.dr = []
    opt.imrate = []
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
it = opt.it; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
iz = opt.iz; %z indices to plot, empty for all, negative for that number equidistant from all available
smsdspace = opt.smsdspace;
smsdtimesec = opt.smsdtimesec; %smooth the stack in time, 0 to skip
dostats = opt.dostats;
dr = opt.dr;
imrate = opt.imrate;

id = idmake(pth_stack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to
suffixstack = id.suffix;
recid = id.recid;
pth_fldr = id.fldr;

if isempty(suffixplt)
    plot_stack_gif = 0;
else
    plot_stack_gif = 1;
end

if ~iscell(suffixstack)
    suffixstack = {suffixstack};
end

if numel(dr)~=1 && numel(dr)~=numel(suffixplt)
    error("dr must be length 1 or match length of suffixplt")
end
if ~isempty(suffixplt) && ~ismember(suffixstack, suffixplt)
    error("suffixplt DOES NOT CONTAIN suffixstack; you must add it to suffixplt, or make suffixplt empty")
end
if numel(suffixplt)~=numel(unique(suffixplt)) %make sure there aren't accidental repeats
    error("there cannot be any repeated suffixplt")
end

indssrc = find(strcmp(suffixstack, suffixplt));
suffixplt = [setxor(suffixstack, suffixplt(:), 'stable'); suffixstack]; % make suffixstack last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackld without having to hold plot stacks in memory)
indsdst = find(strcmp(suffixstack, suffixplt));
indstmp = setxor(1:numel(dr), indssrc);
indsnew = [indstmp(1:indsdst-1) indssrc indstmp(indsdst:end)];
dr = dr(indsnew);

indsmissing = [];
cnt = 0;
for spi = numel(suffixplt):-1:1 %backwards so we don't have to make new suffixplt, dr, and indsmissing
    pthtmp = filefind(pthsib=pth_stack, suffix=suffixplt{spi});
    if ~isempty(pthtmp)
        cnt = cnt+1;
        pth_stacks(cnt) = pthtmp;
    else
        suffixplt(spi) = [];
        dr(spi) = [];
        indsmissing = [indsmissing spi];
        sprintf("WARNING, NO FILE FOUND WITH SUFFIX: " + suffixplt{spi} + " WITH SAME folder, recdate, fly, and trial as sibling file " + pth_stack +  newline + "SKIPPING IT FOR PLOT")
    end
end
pth_stacks = flip(pth_stacks); %since spi was backwards above

%%  loop over suffixes, loading and concatenating


stacktmp = cell(numel(pth_stacks), 1); %make it cell column so first dim is cat when cell2mat below
stackmntmp = cell(numel(pth_stacks), 1); %make it cell column so first dim is cat when cell2mat below


for spi = 1:numel(pth_stacks)

    if endsWith(pth_stacks{spi}, '.mat')
        stack = struct2cell(load(pth_stacks{spi})); %make sure loaded stack is named 'stack'
        stack = stack{1};
        stack = stack(:,:,:,:,chanuse);
    elseif endsWith(pth_stacks{spi}, '.tif')
        stack = tif2mat(pth_stacks{spi}, ...
            sz_yxzt=sz, ...
            numslice_withflyback=numslice_withflyback, ...
            channel_save=channel_save,...
            cropfb=cropfb, ...
            tcrop=tcrop, ...
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

    if smsdtimesec
        smsdtime = smsdtimesec*imrate;
        smsd = [smsdspace smsdtime];
    else
        smsd = smsdspace;
    end

    for m = 1:numel(smsd)
        if smsd(m)
            %FOR NOW HACKING THIS WITH DTYPE CONVERSION TO UINT16, BUT NEED TO JUST MULTIPLY BY A GAUSSIAN TO DO THIS DTYPE FLEXIBLY
            stack = uint16(smoothdata(stack, m, 'gaussian', smsd(m)));
        end
    end

    if plot_stack_gif

        if spi==1
            [iz, izstr] = indsmake(iz, indsall=size(stack,3), label_prefix='z', strdelim=': ', printmax=20);
            [it, itstr] = indsmake(it, indsall=size(stack,4), label_prefix='t', strdelim=': ', printmax=20);
        end

        stacktmp{spi} = stack(:,:,iz,it,:);
        stackmntmp{spi} = mean(stack, 4, 'native');

        if ~strcmp(pth_stack, pth_stacks{spi})
            stack = []; %remove unless it's the stack for analysis outside this function
        end

    end
end


%% plot

if plot_stack_gif

    indsnew = indsnew(~ismember(indsnew, indsmissing));
    [~, plot_stack_order] = sort(indsnew);

    dr = dr(plot_stack_order);

    fn_suffix_insert = strjoin(suffixplt, '_AND_');

    figtitle_prefix = [recid '_' fn_suffix_insert];
    filename_prefix = [pth_fldr figtitle_prefix]; % '_' izstr '_' itstr ];

    index_labels = arrayfun(@(x) 1:x(end), size(stacktmp{1}), 'UniformOutput', false); % setup labels for stack that has already been subset;
    index_labels{3} = iz; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it
    index_labels{4} = it; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it

    numchan = unique(cellfun(@(x) size(x,5), stacktmp)); %must be the same for each stack, will error if not
    if numel(numchan)==1
        for k = numel(stacktmp):-1:1 %backwards so you don't have to allocate another 
            for m = numchan:-1:1 %backwards so you don't have to allocate another 
                stacktmp{k,m} = stacktmp{k}(:,:,:,:,m);
                stackmntmp{k,m} = stackmntmp{k}(:,:,:,:,m);
            end
        end
    end

    if numchan==2
        if numel(dr)~=numel(stacktmp)
            dr = repelem(dr, 2); %since we separated channels into different cells
        end
    end

    stackplt( ...
        stacktmp, ...
        pthgif=[filename_prefix '_.gif'], ...
        dr=dr, ...
        fdimnum=3, ...
        dimorder=[1:ndims(stacktmp{1})], ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels ...
        )

    stackplt( ...
        stackmntmp, ...
        pthgif=[filename_prefix '_meant_.gif'], ...
        dr=dr, ...
        fdimnum=3, ...
        dimorder=[1:ndims(stackmntmp{1})], ...
        title_prefix=figtitle_prefix, ...
        index_labels=index_labels([1:ndims(stackmntmp{1})]) ...
        )

end



