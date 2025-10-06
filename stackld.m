function s = stackld(optin, pthstack, opt2)

%{

read stack that was written (with tifffile.imwrite) to tif as tzcyx (with possible singleton dimensions)
stack is read into matlab, here, as 3d array yxczt (where czt is collapsed into 3rd dimension, possibly singleton)
stack is permuted into order specified by dmstack (with possible singleton trailing dimensions) and placed in struct s (fieldname 'stack'), along with associated data/metadata, then saved to mat file 
struct s is also output 

scanimage and scopa write stacks to tif
matlab file exchange functions tifreadfast (renamed from read_patterned_tifdata) and TIFFStack read these tifs as 3d with dim order yxczt (even if they were written as >3d, at least with imwrite from tifffile.tifffile)

option to just read a subset of the stack to save memory (when savemem=1, and any of iy, ix, iz, it, or ic options are nonempty); nonempty i* options will only save memory if savemem=1 (savemem=1 uses tiffstack, which uses memmapping, rather than tiffreadfast)
but tiffreadfast is default because it is faster, and works well on more platforms (it just makes assumption that stack shape does not change across time, which i think is a safe assumption for all our data) 

for TIFFStack, stack cannot be reshaped until it has been assigned to a variable
stack=stack does not read stack into memory, you must use indexing (stackld creates these indices, even for reading in the entire stack, like if user uses default empty indices)

TIFFStack seems to fail reading floats, so tifs to be read here are written as ints elsehwere

%}

arguments
    optin = []
    pthstack = []
    opt2.dmstack = 'yxztc'; %dimension order of stack that is saved to .mat file and output from this function
    opt2.dmstacktif = 'tzcyx'; %dimension order of stack when written to tif in python with tifffile imwrite (for example, in registration or denoising); keep 'c', 'z', or 't' characters, even if that dimension is singleton
    opt2.savemem = 0 %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)
    opt2.doplt = []
end
savemem = opt2.savemem;
doplt = opt2.doplt;
dmstack = opt2.dmstack;
dmstacktif = opt2.dmstacktif;

[optin, doplt, pthstack] = fset('sld', optin, doplt, pthstack);

fbrm = optin.fbrm; % before saving stack as mat, crop flyback frames if they exist (if using scopa, flyback frames only exist in original scanimage stack)
trm = optin.trm; %num frames to crop from [start, end]; [] to skip
iy = optin.iy; %y indices to keep and save to mat
ix = optin.ix; %x indices to keep and save to mat
ic = optin.ic; %c indices to keep and save to mat
iz = optin.iz; %z indices to keep and save to mat
it = optin.it; %t indices to keep and save to mat
stackdtype = optin.stackdtype;
zerostack = optin.zerostack;
clip = optin.clip;
smlenpx = optin.smlenpx;
smlensec = optin.smlensec; %smooth the stack in time, 0 to skip
smmthd = optin.smmthd;

try_tiffstack_backup = 1; %this will run tiffstack if tifreadfast fails, as long as you didn't already try tiffstack first (if savemem=1)

if ~isfile(pthstack) %in case pthstack includes wildcard *
    pthstack = stackfind(pth=pthstack);
    if isempty(pthstack)
        error("pthstack input to stackld did not return any stacks")
    elseif iscell(pthstack) && ~isscalar(pthstack)
        error("pthstack input to stackld returned multiple stacks; try changing how you used wildcard to restrict results to a single file")
    end
end

[~, fn, ~] = fileparts(pthstack);
if endsWith(fn, 'o_') || ( contains(fn, 'trial_') && contains(fn, '-') )  %scopa or flyg raw stack pattern
    rawstack = 1;
else
    rawstack = 0;
end

if rawstack && ~isempty(iz) && ~isempty(fbrm)
    error("stack is raw and iz is nonempty AND fbrm is true; use one or the other for raw stack (for other stacks, fbrm is ignored because they don't have flyback frames, since they were removed in first preprocessing step (registration)")
end
if ~isempty(it) && ~isempty(trm)
    error("it and trm are both nonempty; use one or the other")
end


%%%% LOAD MAT VERSION OF STACK IF IT EXISTS, AND IF YOU ARE REQUESTING THE SAME SETTINGS USED WHEN IT WAS ORIGINALLY CREATED %%%%

if endsWith(pthstack, '.mat')
    try
        load(pthstack, 'opt', 'pth', 'sz', 'chan') %first just load a few fields of saved struct 's', to make sure we have the right file (since loading whole struct can be slow because it contains the stack)
        if opt_mismatch(pthstack, optin, opt, pth, sz, chan)
            error("YOU REQUESTED A DIFFERENT SET OF OPTIONS THAN THOSE YOU ORIGINALLY USED TO CONVERT STACK FROM TIF TO MAT (ie YOU HAVE A MAT FILE ALREADY SAVED THAT USE A DIFFERENT SET OF OPTIONS); DELETE OR RENAME THAT MAT FILE, OR LOAD THAT FILE BY USING THE SAME OPTIONS LISTED IN s.opt IN FILE: " + pthstack)
        end
        fprintf("loading mat file containing stack" + newline)
        s = load(pthstack); % now you can load entire struct
        return
    catch ME
        fprintf("cannot load mat file stack and/or tif conversion metadata; error message is: " + ME.message + newline)
        fprintf("trying to convert tif to mat now" + newline)
    end
end


%%%% LOAD STACK FROM TIF IF MAT DOESN'T EXIST OR FAILED OR YOU REQUESTED NEW STACK SETTINGS  %%%%

overflow = [];
md = [];

try
    md = mdsild(pthstack);
catch
    fprintf("first attempt to read metadata failed" + newline)
end

opt = optin; %update opt in case optin doesn't match saved opt above (or in case there was no saved opt)

pthstack = regexprep(pthstack, '.mat', '.tif'); %in case mat existed but errored above

if ~endsWith(pthstack, '.tif')
    error("pthstack must end with tif or mat")
end

%%%% SET THE STACK SIZE USING METADATA (IF METADATA EXISTS) %%%%

if ~isempty(md)
    [sz, chan] = stacksize(md, ic, rawstack, pthstack);
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
        [md, sz, chan, overflow] = stackcheck(md, sz, chan, stack, pthstack, ic, rawstack);
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
        % [~, mdtif] = tifreadfast(pthstack, []);
        if isempty(md)
            error("attempt to read metadata must have failed earlier; try to run mdsild on this stack and see wehat happens")
        end
        [md, sz, chan, overflow] = stackcheck(md, sz, chan, stack, pthstack, ic, rawstack);
    catch
        if tiffstack_already_failed
            error("tifreadfast failed and tiffreadstack also failed previously; cannot read stack" + newline)
        else
            if try_tiffstack_backup
                fprintf("tifreadfast failed, using tiffstack as backup; it is slower and only works on some platforms but does not read extra blank frames in tifs not written by scanimage" + newline)
                stack = []; %clear a potentially large variable, in case stack got read by tifreadfast but something caused error afterwards
                stack = TIFFStack(pthstack); %here, stack is memmapped tif stack, this doesn't read the stack into memory yet
                [md, sz, chan, overflow] = stackcheck(md, sz, chan, stack, pthstack, ic, rawstack);
            else
                error("tifreadfast failed, and try_tiffstack_backup is set to 0; you could set it to 1 and try again" + newline)
            end
        end
    end
end


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
        ic_adjust = 1:sz(3);
    else
        ic_adjust = find(chan==ic); %ic_adjust adjusts input ic for any discarded channels
    end
    if ~all(ic_adjust >= 1 & ic_adjust <= sz(3))
        error("REQUESTED ic are not subset of available stack")
    end
    if isempty(iz)
        if rawstack && fbrm
            iz = 1:md.numslice; %numslice is different from sz(4) for original; if you're removing flyback, use numslice; if you're not, use sz(4)
        else
            iz = 1:sz(4);
        end
    end
    if ~all(iz >= 1 & iz <= sz(4))
        error("REQUESTED iz are not subset of available stack")
    end
    if isempty(it)
        it = 1:sz(5);
    end
    if ~all(it >= 1 & it <= sz(5))
        error("REQUESTED it are not subset of available stack")
    end
    if ~isempty(trm)
        it2 = trm(1)+1:sz(5)-trm(2);
        it = intersect(it, it2); %combine whatever t indices you requested and whatever t remove you requested
    end
else
    if ~isempty(ic) || ~isempty(iz) || ~isempty(it)
        error("you must know stack size to pass in nonempty iz or it or ic")
    end
end

%%%% APPLY INDICES AND RESHAPE STACK %%%%

if ~isempty(md)

    if overflow

        inds_t_read_from_all = repelem(1:sz(5),sz(3)*sz(4)); %max possible to find overflow frames, not necessarily the same as below, hence suffix _all
        inds_z_read_from_all = repmat(repelem(1:sz(4),sz(3)), [1 sz(5)]); %max possible to find overflow frames, not necessarily the same as below, hence suffix _all
        inds_c_read_from_all = repmat(1:sz(3), [1 sz(4)*sz(5)]); %max possible to find overflow frames, not necessarily the same as below, hence suffix _all
        inds_czt_read_from_all = sub2ind([sz(3), sz(4), sz(5)], inds_c_read_from_all, inds_z_read_from_all, inds_t_read_from_all); %max possible to find overflow frames, not necessarily the same as below, hence suffix _all

        overflowinds = setdiff(1:size(stack,3), inds_czt_read_from_all); %overflowstack = stack(:, :, overflowinds);
        overflow_meanframe = sum(stack(:,:,overflowinds),3)/numel(overflowinds);
        overflow_firstframe = stack(:,:,overflowinds(1));
        overflow_remainder = overflow_meanframe-double(overflow_firstframe);
        if ~any(sum(overflow_remainder)==0)
            % error("THERE ARE NO COLUMNS THAT ARE STATIC ACROSS ALL OVERFLOW FRAMES; ASSUMING THERE IS REAL SIGNAL IN THE OVERFLOW FRAMES AND THROWING AN ERROR; BUT IT'S ALSO POSSIBLE THE OVERFLOW FRAMES JUST DON'T ALWAYS FOLLOW THIS PATTERN; INSPECT THEM")
        else
            fprintf("overflow frames do not appear to have any data" + newline)
        end
    end
    inds_t_read_from = repelem(it,numel(ic_adjust)*numel(iz));
    inds_z_read_from = repmat(repelem(iz,numel(ic_adjust)), [1 numel(it)]);
    inds_c_read_from = repmat(ic_adjust, [1 numel(iz)*numel(it)]);
    inds_czt_read_from = sub2ind([sz(3), sz(4), sz(5)], inds_c_read_from, inds_z_read_from, inds_t_read_from); %define 1d inds_zt_read_from for z and t

    stack = stack(iy, ix, inds_czt_read_from); %if using tiffstack, this reads into memory; stack = stack just copies the stack object so cant do that
    stack = reshape(stack, numel(iy), numel(ix), numel(ic_adjust), numel(iz), numel(it) );

    dmtif_read = [dmstacktif(end-1) dmstacktif(end) flip(dmstacktif(1:numel(dmstacktif)-2))]; %dmtif_read means the dimension order of the tif when read into matlab; not the same as dimension order when tif was written in python with tifffile imwrite; specifically, imwrite puts pages (czt) as first dimension, while when read here, pages are last dimension, and the pages dimensions are themselves reversed into tzc); so if dmstacktif='tzcyx', dmtif_read='yxczt';
    dmperm = zeros(1, numel(dmstack));
    for k = 1:numel(dmstack)
        dmperm(k) = strfind(dmtif_read, dmstack(k));
    end

    stack = permute(stack, dmperm);


    if doplt
        error("stackstats function needs to be updated, leave doplt false for now")
        stackstats(stack, mask=[], iz=1:size(stack,3), it=round(linspace(1, size(stack,4), 100)), pthsv_prefix=pthstack)
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
        stack = stacksm(stack, method=smmthd, smlenpx=smlenpx, smlensec=smlensec, imrate=md.volrate);
    end

    pthstackmat = regexprep(pthstack, '.tif', '.mat');

    s.pth = pthstackmat;
    s.stack = stack;
    s.md = md;
    s.sz = sz;
    s.chan = chan;
    s.opt = opt;
    s.maketime_optfile_sld = glb('maketime_sld');
    fprintf("saving stack as mat file, after permuting, and optional indexing" + newline)
    save(pthstackmat, '-struct', 's', '-v7.3', '-mat')
    fprintf("stack saved as mat" + newline)

else

    if isempty(iy)
        iy = 1:size(stack,1); %this default can be assigned even if md is empty; if md is not empty and iy is empty, default uses known stack size instead of read stack size
    end
    if isempty(ix)
        ix = 1:size(stack,2); %this default can be assigned even if md is empty; if md is not empty and ix is empty, default uses known stack size instead of read stack size
    end
    stack = stack(iy, ix, :); %if using tiffstack, this reads into memory; if you don't know stack size, you can't subset z or t in stack;  stack = stack just copies the stack object so cant do that

    s.stack = stack;
    s.md = [];
    s.sz = [];
    s.chan = [];
    s.opt = opt;
    s.maketime_optfile_sld = glb('maketime_sld');
    fprintf("WARNING, there was a problem parsing metadata; output s.stack is 3d, and may have collapsed czt dimensions, and may have overflow frames; output s.md, s.sz, and s.chan are all empty; not saving s to mat file" + newline)

end



end


function [sz, chan] = stacksize(md, ic, rawstack, pthstack)

chan = stackchan(pthstack);

if ~isempty(ic) && ~all(ismember(ic, chan))
    error("ic is not a subset of channels in this stack (after accounting for possible chanrm)")
end

sz = [md.ypix, md.xpix, numel(chan), md.numslice, md.numvol]; %yxczt;
if rawstack
    sz(4) = md.numslice_withflyback;
end

end


function [md, sz, chan, overflow] = stackcheck(md, sz, chan, stack, pthstack, ic, rawstack)

errmsg = [];
overflow = [];

if ~isempty(md) %if you have metadata already
    if ~isequal(prod(sz), numel(stack))
        if rawstack
            errmsg = "prod(sz), which is likely derived from tif metadata using mdsisv.py, does not match numel(stack) output from tifreadfast; using tiffStack to read tif instead; mismatch can occur if you're reading a tif written by tifffile imwrite, but there should be no mismatch when reading scanimage output files";
        else
            if prod(sz)>numel(stack)
                errmsg = "tifreadfast returned stack that has fewer elements than your metadata reports, even after accounting for discarded channels";
            else
                overflow = 1;
                fprintf("tifreadfast returned stack with more elements than your metadata reports" + newline + "this can occur with stacks not written by scanimage; will check that the extra frames do not have data" + newline)
            end
        end
    end
else %if you don't have metadata, get it here
    md = mdsild(pthstack);
    if ~isempty(md)
        [sz, chan] = stacksize(md, ic, rawstack, pthstack);
    else
        errmsg = "did not pass in metadata into stackld, so tried to parse metadata from tif metadata (derived here, from 2nd output from tifreadfast), but stack size according to metadata does not match stack; using tiffStack to read tif instead, but cannot reshape czt or index into czt";
    end
end

if ~isempty(errmsg)
    fprintf(errmsg + newline)
    error("error")
end

end

function mismatch = opt_mismatch(pthstack, optnew, optold, pth, sz, chan)

% if mat already exists, error if current options do not match (and are not functionally equivalent to) options previously used to convert tif to mat; 
% comparing options individually, rather than simply ~isequal(optnew, optold),  because some options can change after input, and also some don't matter functionally; also make sure path matches

mismatch = 0;
if ~isequal(pth, pthstack) ...
        || ~isequal(optold.fbrm, optnew.fbrm) ...
        || ~isequal(optold.trm, optnew.trm) ...
        || ~isequal(optold.stackdtype, optnew.stackdtype) ...
        || ~isequal(optold.zerostack, optnew.zerostack) ...
        || ~isequal(optold.clip, optnew.clip) ...
        || ~isequal(optold.smlenpx, optnew.smlenpx) ...
        || ~isequal(optold.smlensec, optnew.smlensec) ...
        || ~isequal(optold.smmthd, optnew.smmthd) ...
        || ( ~isequal(optold.iy, optnew.iy) && ~isequal(1:sz(1), optnew.iy) ) ...
        || ( ~isequal(optold.ix, optnew.ix) && ~isequal(1:sz(2), optnew.ix) ) ...
        || ( ~isequal(optold.ic, optnew.ic) && ~isequal(chan, optnew.ic) ) ...
        || ( ~isequal(optold.iz, optnew.iz) && ~isequal(1:sz(4), optnew.iz) ) ...
        || ( ~isequal(optold.it, optnew.it) && ~isequal(1:sz(5), optnew.it) )

    mismatch = 1;

end

end
