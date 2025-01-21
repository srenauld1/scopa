function stack = stackld(pthstack, opt)

%{

read stack from that was written to tif as tzcyx; array is read as yxczt (??)
stack size saved to mat is yxztc (possible singleton trailing dimensions)
scanimage, and scopa 'pre' pipeline (everything output by pl.py) write stacks as 3d tifs,
with dim order tzcyx, where t and z and c dimensions are collapsed into one
matlab file exchange functions tifreadfast (renamed from read_patterned_tifdata) and TIFFStack read these tifs as 3d with dim order yxczt (even if they were written as >3d, at least with imwrite from tifffile.tifffile)

for TIFFStack, stack cannot be reshaped until it has been assigned to a variable
stack=stack does not read stack into memory, you must use indexing
this function creates indexes (even for the entire stack by default)

TIFFStack seems to fail reading floats

option to just read a subset of z and t indices to save memory/time (iz, it)
sz(4) and sz(5) must match z and t dimensions of tif
tifs from scopa can be 3d or 4d and can be read here without issue

cannot reshape stack from its 3d form and then subset with inds*
must subset stack first, which reads it into memory, then you can subset
so if you know size, you can subset when reading into memory to save memory
if you don't, you read the whole stack then can subset using inds*,
as long as they are not out of bounds

%}

arguments
    pthstack
    opt.fbrm = 0; % before saving stack as mat, crop flyback frames if they exist (if raw scanimage data stack)
    opt.trm = [] %num frames to crop from [start, end]; [] to skip
    opt.savemem = 0 %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)
    opt.iy = []
    opt.ix = []
    opt.ic = []
    opt.iz = []
    opt.it = []
end
fbrm = opt.fbrm;
trm = opt.trm;
savemem = opt.savemem;
iy = opt.iy;
ix = opt.ix;
ic = opt.ic;
iz = opt.iz;
it = opt.it;

try
    md = mdsild(pthstack);
    numslice_withflyback = md.numslice_withflyback;
    channel_save = md.channel_save;
    ypix = md.ypix;
    xpix = md.xpix;
    numslice = md.numslice;
    numvol = md.numvol_o;
    stack_size_is_known = 1;
catch
    stack_size_is_known = 0;
end

if ~isempty(iz) && ~isempty(fbrm)
    error("iz is nonempty AND fbrm is true; use one or the other")
end
if ~isempty(it) && ~isempty(trm)
    error("it AND trm are nonempty; use one or the other")
end


doconvert = 1;
if endsWith(pthstack, '.mat')
    try
        load(pthstack, 'mmd')
        if ~isequal(mmd.fbrm, fbrm) || ~isequal(mmd.trm, trm) || ~isequal(mmd.iy, iy) || ~isequal(mmd.ix, ix) || ~isequal(mmd.ic, ic) || ~isequal(mmd.iz, iz) || ~isequal(mmd.it, it)
            error("YOU REQUESTED A DIFFERENT SET OF OPTIONS THAN THOSE YOU ORIGINALLY USED TO CONVERT STACK FROM TIF TO MAT; YOU HAVE A MAT FILE ALREADY THAT USE A DIFFERENT SET OF OPTIONS; DELETE THAT MAT FILE OR USE THE SAME OPTIONS LISTED IN mmd IN FILE: " + pthstack)
        end
        load(pthstack, 'stack')
        doconvert = 0;
    catch ME
        fprintf("cannot load mat file stack and/or tif conversion metadata (mmd); error message is: " + ME.message + newline)
        fprintf("trying to convert tif to mat now" + newline)
    end
end

if doconvert

    pthstack = regexprep(pthstack, '.mat', '.tif'); %in case mat existed but errored above

    if ~endsWith(pthstack, '.tif')
        error("pthstack must end with tif or mat")
    end

    [~, fn, ext] = fileparts(pthstack);
    pthmat = regexprep(pthstack, '.tif', '.mat');

    if contains(fn, 'trial_') && contains(fn, '-') || contains(fn, 'raw')
        rawstack = 1;
    else
        rawstack = 0;
    end

    %%%% SET THE STACK SIZE USING METADATA (IF METADATA EXISTS) %%%%

    if stack_size_is_known
        if rawstack
            sz = [ypix, xpix, numel(channel_save), numslice_withflyback, numvol]; %z dimension of sz includes flyback frames for raw stack
        else
            sz = [ypix, xpix, numel(channel_save), numslice, numvol]; %yxzt; %all other stacks do not have flyback frames, so fullsize is same as yxzt
        end
    end

    %%%% MAKE SURE savemem MAKES SENSE (if savemem=1) %%%%

    if savemem
        if stack_size_is_known
            if isequal(iy, 1:sz(1)) && isequal(ix, 1:sz(2)) && isequal(iz, 1:sz(3)) && isequal(ic, 1:sz(4)) && isequal(it, 1:sz(5))
                fprintf("savemem is true but all inds_*_read_from are equal to their corresponding sz, so you are reading in the entire stack and will not save memory with memmap, so changing savemem to false and using faster tif reader" + newline)
                savemem = 0;
            end
        else
            fprintf("savemem=1 but stack_size_is_known=0; this means you don't have metadata file mdsi_.txt yet, so you must obtain it with tifreadfast, which is the alternative to savemem; using it will defeat the purpose of savemem, so setting savemem to 0 now")
            savemem = 0;
        end
        if isempty(iy) && isempty(ix) && isempty(ic) && isempty(iz) && isempty(it)
            fprintf("savemem is true but all inds_*_read_from are empty, so you are reading in the entire stack and will not save memory with memmap, so changing savemem to false and using faster tif reader" + newline)
            savemem = 0;
        end
    end


    %%%% READ THE STACK WITH TIFFStack (if savemem=1) %%%%

    tiffstack_already_failed = 0;
    if savemem %try with tiffstack
        try_tifreadfast = 0;
        try
            fprintf("savemem is true, trying to read stack with TIFFStack first to save memory (since you are reading a subset of the stack)" + newline)
            stack = TIFFStack(pthstack); %stack is memmapped tif stack, this doesn't read the stack into memory yet
        catch
            tiffstack_already_failed = 1;
            fprintf("savemem tiffstack failed, using tifreadfast" + newline)
            try_tifreadfast = 1;
        end
    else
        try_tifreadfast = 1;
    end


    %%%% READ THE STACK WITH tifreadfast (if savemem=0 or if savemem was 1 but TIFFStack failed) %%%%

    if try_tifreadfast %try with tifreadfast; compared with tiffstack, tifreadfast is faster and more compatible across operating systems, versions, platforms (because it doens't use mex code); but, tifreadfast can fail for tiffs with varying size per frame, so tiffstack remains in the catch block below (i haven't done the work to make tiffstack work everywhere, which would requyire using different compiled code after system check)
        try
            fprintf("trying to read stack with tifreadfast" + newline)
            stack = tifreadfast(pthstack); %here, stack is read into memory (is not memmapped)
            if stack_size_is_known %if you have metadata already
                if ~isequal(prod(sz), numel(stack))
                    if rawstack
                        error("prod(sz), which is likely derived from tif metadata using mdsisv.py, does not match numel(stack) output from tifreadfast; using tiffStack to read tif instead; mismatch can occur if you're reading a tiff written by tiffile imwrite, but there should be no mismatch when reading scanimage output files")
                    else
                        if prod(sz)>numel(stack)
                            error("tifreadfast returned stack that has fewer elements than your metadata reports")
                        else
                            waittime = 20;
                            fprintf(newline + "tifreadfast returned stack with more elements than your metadata reports" + newline + "this can occur with stacks not written by scanimage" + newline + "if you do not halt execution within " + num2str(waittime) + " seconds, " + newline + "the code will assume your metadata is correct " + newline + " and crop the stack (at the end of each overlong dimension) to match metadata" + newline)
                            pause(waittime)
                        end
                    end
                end
            else %e.g. if you don't have metadata
                md = mdsisv_mat(pthstack);
                if ~isempty(md)
                    numslice_withflyback = md.numslice_withflyback;
                    channel_save = md.channel_save;
                    ypix = md.ypix;
                    xpix = md.xpix;
                    numslice = md.numslice;
                    numvol = md.numvol;
                    if rawstack
                        sz = [ypix, xpix, numel(channel_save), numslice_withflyback, numvol]; %z dimension of sz includes flyback frames for raw stack
                    else
                        sz = [ypix, xpix, numel(channel_save), numslice, numvol]; %yxzt; %all other stacks do not have flyback frames, so fullsize is same as yxzt
                    end
                    stack_size_is_known = 1;
                else
                    stack_size_is_known = 0;
                    error("did not pass metadata into stackld, so tried to parse metadata from tif metadata (derived here, from 2nd output from tifreadfast), but stack size according to metadata does not match stack; using tiffStack to read tif instead, but cannot reshape czt or index into czt")
                end
            end
        catch
            if tiffstack_already_failed
                error("tifreadfast failed and tiffreadstack also failed previously; cannot read stack" + newline)
            else
                fprintf("tifreadfast failed, using tiffstack" + newline)
            end
            stack = []; %clear a potentially large variable, in case stack got read by tifreadfast but something caused error afterwards
            stack = TIFFStack(pthstack); %here, stack is memmapped tif stack, this doesn't read the stack into memory yet
        end
    end

    mmd.fbrm = fbrm;
    mmd.trm = trm;
    mmd.iy = iy;
    mmd.ix = ix;
    mmd.iz = ic;
    mmd.ic = iz;
    mmd.it = it;


    %%%% CHECK ANY INDICES FOR PROBLEMS %%%%

    if stack_size_is_known
        if isempty(iy)
            iy = 1:sz(1); %can choose any subset of y, can be discontiguous;
        end
        if ~all(iy >= 1 & iy <= sz(1))
            error("REQUESTED iy are not subset of available stack")
        end
        if isempty(ix)
            ix = 1:sz(2); %can choose any subset of x, can be discontiguous;
        end
        if ~all(ix >= 1 & ix <= sz(2))
            error("REQUESTED ix are not subset of available stack")
        end
        if isempty(ic)
            ic = 1:sz(3); %can choose any subset of t, can be discontiguous
        end
        if ~all(ic >= 1 & ic <= sz(3))
            error("REQUESTED ic are not subset of available stack")
        end
        if isempty(iz)
            if fbrm
                iz = 1:numslice; %can crop flyback before reading into memory by passing subset of inds; in general, can choose any subset of z, can be discontiguous; e.g. passing 1:numslice will skip flyback frames for raw, while 1:size_z_read_from will read flyback frames;
            else
                iz = 1:sz(4); %read all frames of not fbrm
            end
        end
        if ~all(iz >= 1 & iz <= sz(4))
            error("REQUESTED iz are not subset of available stack")
        end
        if isempty(it)
            it = 1:sz(5); %can choose any subset of t, can be discontiguous
            if ~isempty(trm)
                it = trm(1)+1:it(4)-trm(2);
            end
        end
        if ~all(it >= 1 & it <= sz(5))
            error("REQUESTED it are not subset of available stack")
        end
    else
        if ~isempty(ic) || ~isempty(iz) || ~isempty(it)
            error("you must know stack size to pass nonempty iz or it or ic")
        end
    end

    %%%% RESHAPE THE STACK AND APPLY INDICES %%%%

    if stack_size_is_known

        inds_t_read_from_all = repelem(it,numel(ic)*numel(iz));
        inds_z_read_from_all = repmat(repelem(iz,numel(ic)), [1 numel(it)]);
        inds_c_read_from_all = repmat(ic, [1 numel(iz)*numel(it)]);
        inds_czt_read_from = sub2ind([sz(3), sz(4), sz(5)], inds_c_read_from_all, inds_z_read_from_all, inds_t_read_from_all); %define 1d inds_zt_read_from for z and t

        stack = stack(iy, ix, inds_czt_read_from); %if using tiffstack, this reads into memory; stack = stack just copies the stack object so cant do that
        stack = reshape(stack, numel(iy), numel(ix), numel(ic), numel(iz), numel(it) );

        stack = permute(stack, [1 2 4 5 3]);
        save(pthmat, 'stack', 'mmd', '-v7.3', '-mat')

    else

        if isempty(iy)
            iy = 1:size(stack,1); %this default can be assigned even if stack_size_is_known==0; if stack_size_is_known and iy is empty, default uses known stack size instead of read stack size
        end
        if isempty(ix)
            ix = 1:size(stack,2); %this default can be assigned even if stack_size_is_known==0;  if stack_size_is_known and ix is empty, default uses known stack size instead of read stack size
        end
        stack = stack(iy, ix, :); %if using tiffstack, this reads into memory; if you don't know stack size, you can't subset z or t in stack;  stack = stack just copies the stack object so cant do that
        fprintf("WARNING, sz was not passed as argument, or was empty (you did not read metadata before entering this function), or there was a problem reading raw tif metadata; output tif is 3d, and may have collapsed czt dimensions; not saving as mat file" + newline)

    end


end