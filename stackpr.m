

function stack = stackpr(pthstack, opt, doplt)

%{
load (and optionally process and plot) a single image stack (pthstack) created by scopa script pl.sh, or the raw stack output by scanimage
calls stackld to load the stack; in stackld, if mat doesn't exist, will read tif and save as mat
can also plot (but not output) multiple stacks created in different stages of scopa pipeline, in a single figure (saved as gif) for comparison
any processing options are applied after loading from mat, and are applied to all plotted stacks 
stack plots create temporary stacks (subset according to user index inputs) one at a time, in a loop, then plots the accumulated stacks variable, since opening multiple stacks at once could crash ram
if you're plotting multiple stacks in their entirity, this strategy is less efficient, but that seems unlikely
%}

arguments
    pthstack = []
    opt = []
    doplt = []
end

if isempty(pthstack)
    pthstack = glb('pthstack');
    if isempty(pthstack)
        error("you must either pass argument pthstack or set glb('pthstack')")
    end
end
if isempty(opt)
    fprintf("user did not pass options as argument, using all defaults")
    opt = odf('spr', fill=1, unpack=1);
end

optsld = opt.sld;
stackdtype = opt.stackdtype;
zerostack = opt.zerostack;
clip = opt.clip;
smlenpx = opt.smlenpx;
smlensec = opt.smlensec; %smooth the stack in time, 0 to skip
smmthd = opt.smmthd;
dostats = opt.dostats;
suffixplt = opt.suffixplt;
it = opt.sp.it; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
iz = opt.sp.iz; %z indices to plot, empty for all, negative for that number equidistant from all available
dr = opt.sp.dr;

suffixplt = convertStringsToChars(suffixplt);
if ~isempty(suffixplt) && ~iscell(suffixplt)
    suffixplt = {suffixplt};
end

if isempty(doplt)
    doplt = any(strcmp('spr', glb('plt')));
end

if ~doplt
    fprintf("in stackpr, doplt or glb('plt') is set to 0, so any stacks listed in suffixplt will not be plotted" + newline)
    suffixplt = [];
end

id = idmake(pthstack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to
suffixstack = id.suffix;
recid = id.recid;
pthstackdir = id.pthstackdir;

pthmd = [id.pthstackdir id.recid '_mdsi_.txt'];

if ~iscell(suffixstack)
    suffixstack = {suffixstack};
end

if ~iscell(dr)
    dr = {dr};
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
        suffixld = [setxor(suffixstack, suffixplt, 'stable') suffixstack]; % make suffixstack last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackpr without having to hold plot stacks in memory)
    else
        suffixld = [suffixplt suffixstack]; % make suffixstack last to minimize memory (so it can overwrite any plot stacks, after they are subset for plotting, and be output from stackpr without having to hold plot stacks in memory)
    end
end
indsdst = find(strcmp(suffixstack, suffixld));
indstmp = setxor(1:numel(dr), indssrc);
indsnew = [indstmp(1:indsdst-1) indssrc indstmp(indsdst:end)];
dr = dr(indsnew);

cnt = 0;
for spi = numel(suffixld):-1:1 %backwards so we don't have to make new suffixplt, dr, and indsmissing
    pthtmp = stackfind(pthsib=pthstack, suffix=suffixld{spi});
    if ~isempty(pthtmp)
        cnt = cnt+1;
        pthstackall(cnt) = pthtmp;
    else
        if any(strcmp(suffixld{spi}, suffixplt))
            suffixplt(strcmp(suffixld{spi}, suffixplt)) = [];
            dr(spi) = [];
            indsnew(spi) = [];
        end
        suffixld(spi) = [];
    end
end
pthstackall = flip(pthstackall); %since spi was backwards above, and pthstackall was indexed with a loop increment cnt

if isempty(suffixplt) %if it's empty after looking for files, set doplt to 0
    fprintf(newline + "in stackpr, suffixplt is empty (either because the user made it empty, or none of the stacks listed in suffixplt were found), so doplt is now set to 0, regardless of how it was set entering stackpr" + newline)
    doplt = 0;
end

%%  loop over suffixes, loading and concatenating


stacktmp = cell(numel(suffixplt), 1); %make it cell column so first dim is cat when cell2mat below
stackmntmp = cell(numel(suffixplt), 1); %make it cell column so first dim is cat when cell2mat below


cnt = 0;
for spi = 1:numel(pthstackall)

    [stack, chantif{spi}] = stackld(pthstackall{spi}, optsld);

    if dostats
        stackstats(stack, mask=[], iz=1:size(stack,3), it=round(linspace(1, size(stack,4), 100)), pthsv_prefix=pthstackall{spi}(1:end-4))
    end
    if any(clip) && ~isequal(clip, [0,1])
        stack = stackclip(stack, clip=clip);
    end
    if zerostack
        stack = stack - min(stack, [], [1 2 3 4], 'omitmissing'); %subtract min for each channel
    end
    if ~isa(stack, stackdtype)
        stack = stacktype(stack, stackdtype);
    end
    if any(smlenpx) || any(smlensec)
        imrate = structfile(pthmd, nm='volrate');
        stack = stacksm(stack, method=smmthd, smlenpx=smlenpx, smlensec=smlensec, imrate=imrate);
    end

    glb(1, stackmnt=stacktype(mean(stack, 4), class(stack))); %set mean t stack as global since it's used repeatedly, and can be a little slow to compute


    if doplt && any(strcmp(suffixld{spi}, suffixplt))

        cnt = cnt+1;

        if cnt==1
            [iz, izstr] = indsmake(iz, indsall=size(stack,3), label_prefix='z');
            [it, itstr] = indsmake(it, indsall=size(stack,4), label_prefix='t');
        end

        stacktmp{cnt, 1} = stack(:,:,iz,it,:); %make sure it's indexed into first dimension
        stackmntmp{cnt, 1} = single(mean(stack, 4));  %make sure it's indexed into first dimension

        if ~strcmp(pthstack, pthstackall{spi})
            stack = []; %remove unless it's the stack for analysis outside this function
        end

    end
end


%% plot

if doplt

    %make sure stacks for plotting all use the same channel 
    chantif_main_stack = chantif{end};
    for k = 1:numel(stacktmp)
        if ~all(ismember(chantif_main_stack, chantif{k})) 
            error("mismatch in channels taken from tifs for plotting, or channels written to tifs")
        end
        if size(stacktmp{k},5)>numel(chantif_main_stack)
            fprintf("KEEPING ONLY CHANNEL " + num2str(chantif_main_stack) + " IN TEMPORARY PLOTTING STACK WITH SUFFIX " + suffixplt{k} + " TO MATCH CHANNEL PLOTTED IN STACK WITH SUFFIX " + suffixplt{end} + newline)
            stacktmp{k} = stacktmp{k}(:,:,:,:,chantif_main_stack);
            stackmntmp{k} = stackmntmp{k}(:,:,:,:,chantif_main_stack);
        end
    end

    [~, plot_stack_order] = sort(indsnew);

    stacktmp = stacktmp(plot_stack_order);
    dr = dr(plot_stack_order);

    fn_suffix_insert = strjoin(suffixplt, '_AND_');

    figtitle_prefix = [recid '_' fn_suffix_insert];
    filename_prefix = [pthstackdir figtitle_prefix]; % '_' izstr '_' itstr ];

    index_labels = arrayfun(@(x) 1:x(end), size(stacktmp{1}), 'UniformOutput', false); % setup labels for stack that has already been subset;
    index_labels{3} = iz; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it
    index_labels{4} = it; % subset the (possibly) large stacks before stackplt, rather than cat them and make a giant variable then subset in stackplt with ix,iy,iz,it

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



