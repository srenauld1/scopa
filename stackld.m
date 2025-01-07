
%% input

% load a single image stack (pthstack) output by scopa 'pre' pipeline, or the raw stack output by scanimage
% if mat doesn't exist, will read tif and save as mat (reading large tif uses TIFFStack library, in scopa/dependencies)
% can also plot (but not output) multiple stacks output by different stages in the scopa preprocessing pipeline (suffixplt)
% stack plots create temporary variables for stacks (subset according to user yxztc index inputs) one at a time, in a loop, then plots the accumulated stacks variable, because opening multiple stacks at once could require a lot of memory
% (if you're plotting the whole stack though, this strategy is a disadvantage)

function stack = stackld(pthstack, opt)


arguments
    pthstack  %can just pass pthstack if it's mat; if tif need to also pass sz (or pthmd) to read tif into stack's native shape, or if you don't pass sz it will read tif with tzc collapsed into 3rd dim;
    opt.stackdtype = 'uint16'
    opt.chanuse = 1
    opt.cropfb = 1 %whether to crop flyback frames (only applied to raw tif)
    opt.tcrop = [0,0] %how many frames to crop from [beginning,end] of trial
    opt.savemem = 0 %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)
    opt.zerostack = 0
    opt.clip = []
    opt.smlenpx = [];
    opt.smlensec = []
    opt.smmthd = 'gaussian';
    opt.dostats = 0
    opt.suffixplt = [] %pass nonempty suffixplt (cell of char or string array) and it will plot whichever of those suffixes are in same folder as pth.stack, along with pth.stack
    opt.it = -50;
    opt.iz = []
    opt.dr = [0,1]
    opt.doplt = [] %default empty rather than 0 to distinguish user passing 0 and user passing nothing
end
stackdtype = opt.stackdtype;
chanuse = opt.chanuse;
cropfb = opt.cropfb;
tcrop = opt.tcrop;
savemem = opt.savemem;
zerostack = opt.zerostack;
clip = opt.clip;
smlenpx = opt.smlenpx;
smlensec = opt.smlensec; %smooth the stack in time, 0 to skip
smmthd = opt.smmthd;
dostats = opt.dostats;
suffixplt = opt.suffixplt;
it = opt.it; %t indices to plot, empty for all, negative for that number equidistant from all available, or segmentlength.numsegments
iz = opt.iz; %z indices to plot, empty for all, negative for that number equidistant from all available
dr = opt.dr;
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

id = idmake(pthstack); %also ran this in a2p earlier, but it's fast and let's us not pass this input if we don't have to
suffixstack = id.suffix;
recid = id.recid;
dirstack = id.dirstack;

pthmd = [id.dirstack id.recid '_mdsi_.txt'];
imrate = structfile(pthmd, nm='volrate');

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
    fprintf(newline + "in stackld, suffixplt is empty (either because the user made it empty, or none of the stacks listed in suffixplt were found), so doplt is now set to 0, regardless of how it was set entering stackld" + newline)
    doplt = 0;
end

%%  loop over suffixes, loading and concatenating


stacktmp = cell(numel(suffixplt), 1); %make it cell column so first dim is cat when cell2mat below
stackmntmp = cell(numel(suffixplt), 1); %make it cell column so first dim is cat when cell2mat below


cnt = 0;
for spi = 1:numel(pthstackall)

    if endsWith(pthstackall{spi}, '.mat')
        stack = struct2cell(load(pthstackall{spi})); %make sure loaded stack is named 'stack'
        stack = stack{1};
        chanusetmp = chanuse(chanuse<=size(stack,5)); %only use requested channels that exist, if you request one channel that doesn't exist this will error
        if ~isequal(chanusetmp, 1:size(stack,5))
            stack = stack(:,:,:,:,chanusetmp);
        end
    elseif endsWith(pthstackall{spi}, '.tif')
        stack = tif2mat( pthstackall{spi}, ...
            cropfb=cropfb, ...
            tcrop=tcrop, ...
            savemem=savemem ...
            );
    else
        error("pthstackall must end with tif or mat");
    end


    if dostats
        plot_stack_stats(stack, ...
            mask=[], ...
            iz=1:size(stack,3), ...
            it=round(linspace(1, size(stack,4), 100)), ... %1: size(stack,4)
            pthsv_prefix=pthstackall{spi}(1:end-4))
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
        stack = stacksmooth(stack, method=smmthd, smlenpx=smlenpx, smlensec=smlensec, imrate=imrate);
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



