function [stack, chantif] = stackld(pthstack, opt)

%{

read stack that was written to tif as tzcyx
stack is read here as 3d array yxczt (where czt is collapsed into one dimension, the 3rd dimension)
stack is perumted and saved to mat is yxztc (possible singleton trailing dimensions)

scanimage and scopa write stacks to tif
matlab file exchange functions tifreadfast (renamed from read_patterned_tifdata) and TIFFStack read these tifs as 3d with dim order yxczt (even if they were written as >3d, at least with imwrite from tifffile.tifffile)

option to just read a subset of the stack to save memory; this will only save memory if savemem=1 (savemem=1 uses tiffstack rather than tiffreadfast)

for TIFFStack, stack cannot be reshaped until it has been assigned to a variable
stack=stack does not read stack into memory, you must use indexing
stackld creates indexes (even for the entire stack, if user uses default indices)

TIFFStack seems to fail reading floats

%}

arguments
    pthstack
    opt
end
fbrm = opt.fbrm; % before saving stack as mat, crop flyback frames if they exist (if using scopa, flyback frames only exist in raw scanimage stack)
trm = opt.trm; %num frames to crop from [start, end]; [] to skip
iy = opt.iy; %y indices to keep and save to mat
ix = opt.ix; %x indices to keep and save to mat
ic = opt.ic; %c indices to keep and save to mat
iz = opt.iz; %z indices to keep and save to mat
it = opt.it; %t indices to keep and save to mat 
savemem = opt.savemem; %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)

try_tiffstack_backup = 1; %this will run tiffstack if tifreadfast fails, as long as you didn't already try tiffstack first (if savemem=1)


md = [];
sz = [];
chantif = [];
overflow = [];

id = idmake(pthstack);

try
    md = mdsild(pthstack);
catch
    fprintf("first attempt to read metadata failed" + newline)
end

if ~isempty(iz) && ~isempty(fbrm)
    error("iz is nonempty AND fbrm is true; use one or the other")
end
if ~isempty(it) && ~isempty(trm)
    error("it AND trm are nonempty; use one or the other")
end


%%%% LOAD MAT VERSION OF STACK IF IT EXISTS, AND IF YOU ARE REQUESTING THE SAME SETTINGS USED WHEN IT WAS ORIGINALLY CREATED %%%%

doconvert = 1;
if endsWith(pthstack, '.mat')
    try
        load(pthstack, 'mmd')
        if ~isequal(mmd.fbrm, fbrm) ... %if mat already exists, error if current settings do not match (and are not functionally equivalent to) settings previously used to convert tif to mat
                || ~isequal(mmd.trm, trm) ...
                || ( ~isequal(mmd.iy, iy) && ~isequal(1:mmd.sz(1), ix) ) ...
                || ( ~isequal(mmd.ix, ix) && ~isequal(1:mmd.sz(2), ix) ) ...
                || ( ~isequal(mmd.ic, ic) && ~isequal(mmd.chantif, ic) ) ...
                || ( ~isequal(mmd.iz, iz) && ~isequal(1:mmd.sz(4), ix) ) ...
                || ( ~isequal(mmd.it, it) && ~isequal(1:mmd.sz(5), ix) )
            error("YOU REQUESTED A DIFFERENT SET OF OPTIONS THAN THOSE YOU ORIGINALLY USED TO CONVERT STACK FROM TIF TO MAT; YOU HAVE A MAT FILE ALREADY THAT USE A DIFFERENT SET OF OPTIONS; DELETE THAT MAT FILE OR USE THE SAME OPTIONS LISTED IN mmd IN FILE: " + pthstack)
        end
        load(pthstack, 'stack')
        chantif = mmd.chantif;
        doconvert = 0;
    catch ME
        fprintf("cannot load mat file stack and/or tif conversion metadata (mmd); error message is: " + ME.message + newline)
        fprintf("trying to convert tif to mat now" + newline)
    end
end

%%%% LOAD STACK FROM TIF IF MAT DOESN'T EXIST OR FAILED OR YOU REQUESTED NEW STACK SETTINGS  %%%%

if doconvert

    pthstack = regexprep(pthstack, '.mat', '.tif'); %in case mat existed but errored above

    if ~endsWith(pthstack, '.tif')
        error("pthstack must end with tif or mat")
    end

    [~, fn, ~] = fileparts(pthstack);
    pthmat = regexprep(pthstack, '.tif', '.mat');

    if contains(fn, 'trial_') && contains(fn, '-') || contains(fn, 'raw')
        rawstack = 1;
    else
        rawstack = 0;
    end

    %%%% SET THE STACK SIZE USING METADATA (IF METADATA EXISTS) %%%%

    if ~isempty(md)
        [sz, chantif] = stacksize(md, id, ic, rawstack, pthstack);
    end

    %%%% MAKE SURE savemem MAKES SENSE (if savemem=1) %%%%

    if savemem
        if ~isempty(md)
            if isequal(iy, 1:sz(1)) && isequal(ix, 1:sz(2)) && isequal(iz, 1:sz(3)) && isequal(ic, 1:sz(4)) && isequal(it, 1:sz(5))
                fprintf("savemem is true but all inds_*_read_from are equal to their corresponding sz, so you are reading in the entire stack and will not save memory with memmap, so changing savemem to false and using faster tif reader" + newline)
                savemem = 0;
            end
        else
            fprintf("savemem=1 but md is empty; this means you don't have metadata file mdsi_.txt yet, so you must obtain it with tifreadfast, which is the alternative to savemem; using it will defeat the purpose of savemem, so setting savemem to 0 now")
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
            [md, sz, chantif, overflow] = stackcheck(md, sz, chantif, stack, pthstack, id, ic, rawstack);
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
            [md, sz, chantif, overflow] = stackcheck(md, sz, chantif, stack, pthstack, id, ic, rawstack);
        catch
            if tiffstack_already_failed
                error("tifreadfast failed and tiffreadstack also failed previously; cannot read stack" + newline)
            else
                if try_tiffstack_backup
                    fprintf("tifreadfast failed, using tiffstack as backup; it is slower and only works on some platforms but does not read extra blank frames in tifs not written by scanimage" + newline)
                    stack = []; %clear a potentially large variable, in case stack got read by tifreadfast but something caused error afterwards
                    stack = TIFFStack(pthstack); %here, stack is memmapped tif stack, this doesn't read the stack into memory yet
                    [md, sz, chantif, overflow] = stackcheck(md, sz, chantif, stack, pthstack, id, ic, rawstack);
                else
                    error("tifreadfast failed, and try_tiffstack_backup is set to 0; you could set it to 1 and try again" + newline)
                end
            end
        end
    end


    %%%% RECORD SETTINGS FOR CONVERTING TIF TO MAT %%%%

    mmd.fbrm = fbrm;
    mmd.trm = trm;
    mmd.iy = iy;
    mmd.ix = ix;
    mmd.ic = ic;
    mmd.iz = iz;
    mmd.it = it;
    mmd.sz = sz;
    mmd.chantif = chantif;


    %%%% CHECK ANY INDICES FOR PROBLEMS %%%%

    if ~isempty(md)
        if isempty(iy)
            iy = 1:sz(1);
        end
        if ~all(iy >= 1 & iy <= sz(1))
            error("REQUESTED iy are not subset of available stack")
        end
        if isempty(ix)
            ix = 1:sz(2);
        end
        if ~all(ix >= 1 & ix <= sz(2))
            error("REQUESTED ix are not subset of available stack")
        end
        if isempty(ic)
            ic = 1:sz(3);
        end
        if ~all(ic >= 1 & ic <= sz(3))
            error("REQUESTED ic are not subset of available stack")
        end
        if isempty(iz)
            if rawstack && fbrm
                iz = 1:md.numslice; %numslice is different from sz(4) for raw; if you're removing flyback, use numslice; if you're not, use sz(4)
            else
                iz = 1:sz(4);
            end
        end
        if ~all(iz >= 1 & iz <= sz(4))
            error("REQUESTED iz are not subset of available stack")
        end
        if isempty(it)
            it = 1:sz(5);
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

    %%%% APPLY INDICES AND RESHAPE STACK %%%%

    if ~isempty(md)

        inds_t_read_from_all = repelem(it,numel(ic)*numel(iz));
        inds_z_read_from_all = repmat(repelem(iz,numel(ic)), [1 numel(it)]);
        inds_c_read_from_all = repmat(ic, [1 numel(iz)*numel(it)]);
        inds_czt_read_from = sub2ind([sz(3), sz(4), sz(5)], inds_c_read_from_all, inds_z_read_from_all, inds_t_read_from_all); %define 1d inds_zt_read_from for z and t

        if overflow
            overflowinds = setxor(inds_czt_read_from, 1:size(stack,3)); %overflowstack = stack(:, :, overflowinds); 
            overflow_meanframe = sum(stack(:,:,overflowinds),3)/numel(overflowinds);
            overflow_firstframe = stack(:,:,overflowinds(1));
            overflow_remainder = overflow_meanframe-double(overflow_firstframe);
            if ~any(sum(overflow_remainder)==0)
                error("THERE ARE NO COLUMNS THAT ARE STATIC ACROSS ALL OVERFLOW FRAMES; ASSUMING THERE IS REAL SIGNAL IN THE OVERFLOW FRAMES AND THROWING AN ERROR")
            end
        end
        stack = stack(iy, ix, inds_czt_read_from); %if using tiffstack, this reads into memory; stack = stack just copies the stack object so cant do that
        stack = reshape(stack, numel(iy), numel(ix), numel(ic), numel(iz), numel(it) );

        stack = permute(stack, [1 2 4 5 3]);
        save(pthmat, 'stack', 'mmd', '-v7.3', '-mat')

    else

        if isempty(iy)
            iy = 1:size(stack,1); %this default can be assigned even if md is empty; if md is not empty and iy is empty, default uses known stack size instead of read stack size
        end
        if isempty(ix)
            ix = 1:size(stack,2); %this default can be assigned even if md is empty; if md is not empty and ix is empty, default uses known stack size instead of read stack size
        end
        stack = stack(iy, ix, :); %if using tiffstack, this reads into memory; if you don't know stack size, you can't subset z or t in stack;  stack = stack just copies the stack object so cant do that
        fprintf("WARNING, there was a problem parsing metadata; output tif is 3d, and may have collapsed czt dimensions; and may have overflow frames; not saving as mat file" + newline)

    end


end


end


function [sz, chantif] = stacksize(md, id, ic, rawstack, pthstack)

if isfield(md, ['chanrm_' id.suffix])
    chanrm = md.(['chanrm_' id.suffix]);
else
    if rawstack
        chanrm = [];
    else
        error("chanrm_" + id.suffix + " is not a field in mdsi_.txt; it is required to track discarded channels; you may be using an old mdsi file; rerun the code that created this tif: " + pthstack + " and chanrm_" + id.suffix + " will be added to mdsi")
    end
end
if isempty(chanrm)
    chantif = 1:numel(md.channel_save);
else
    chantif = setxor(chanrm, 1:numel(md.channel_save));
end
if ~isempty(ic) && ~all(ismember(ic, chantif))
    error("ic is not a subset of channels in this stack (after accounting for possible chanrm)")
end

sz = [md.ypix, md.xpix, numel(chantif), md.numslice, md.numvol]; %yxczt;
if rawstack
    sz(4) = md.numslice_withflyback;
end

end


function [md, sz, chantif, overflow] = stackcheck(md, sz, chantif, stack, pthstack, id, ic, rawstack)

errmsg = [];
overflow = [];

if ~isempty(md) %if you have metadata already
    if ~isequal(prod(sz), numel(stack))
        if rawstack
            errmsg = "prod(sz), which is likely derived from tif metadata using mdsisv.py, does not match numel(stack) output from tifreadfast; using tiffStack to read tif instead; mismatch can occur if you're reading a tiff written by tiffile imwrite, but there should be no mismatch when reading scanimage output files";
        else
            if prod(sz)>numel(stack)
                errmsg = "tifreadfast returned stack that has fewer elements than your metadata reports, even after accounting for discarded channels";
            else
                overflow = 1;
                fprintf("tifreadfast returned stack with more elements than your metadata reports" + newline + "this can occur with stacks not written by scanimage; will check that the extra frames are blank" + newline)
            end
        end
    end
else %if you don't have metadata, get it here
    md = mdsild(pthstack);
    if ~isempty(md)
        [sz, chantif] = stacksize(md, id, ic, rawstack, pthstack);
    else
        errmsg = "did not pass metadata into stackld, so tried to parse metadata from tif metadata (derived here, from 2nd output from tifreadfast), but stack size according to metadata does not match stack; using tiffStack to read tif instead, but cannot reshape czt or index into czt";
    end
end

if ~isempty(errmsg)
    fprintf(errmsg + newline)
    error("error")
end

end