function stack = stackld(pthtif, opt)

% tzcyx --> yxczt
% read tif that was written as tzcyx; array is read as yxczt

% scanimage, and scopa 'pre' pipeline (everything output by pl.py) write stacks as 3d tifs,
% with dim order tzcyx, where t and z and c dimensions are collapsed into one
% matlab file exchange functions tifreadfast (renamed from read_patterned_tifdata) and TIFFStack read these tifs as 3d with dim order yxczt (even if they were written as >3d, at least with imwrite from tifffile.tifffile)

% for TIFFStack, stack cannot be reshaped until it has been assigned to a variable
% stack=stack does not read stack into memory, you must use indexing
% this function creates indexes (even for the entire stack by default)

%TIFFStack seems to fail reading floats

%option to just read a subset of z and t indices to save memory/time (iz, it)
%sz(4) and sz(5) must match z and t dimensions of tif
%tifs from scopa can be 3d or 4d and can be read here without issue

%cannot reshape stack from its 3d form and then subset with inds*
%must subset stack first, which reads it into memory, then you can subset
%so if you know size, you can subset when reading into memory to save memory
%if you don't, you read the whole stack then can subset using inds*,
% as long as they are not out of bounds

arguments
    pthtif
    opt.sz = []
    opt.iy = []
    opt.ix = []
    opt.ic = []
    opt.iz = []
    opt.it = []
    opt.savemem = 0 %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)
end
savemem = opt.savemem;
sz = opt.sz;
iy = opt.iy;
ix = opt.ix;
ic = opt.ic;
iz = opt.iz;
it = opt.it;

if isempty(sz)
    stack_size_is_known = 0;
else
    stack_size_is_known = 1;
end

if savemem
    if stack_size_is_known
        if isequal(iy, 1:sz(1)) && isequal(ix, 1:sz(2)) && isequal(iz, 1:sz(3)) && isequal(ic, 1:sz(4)) && isequal(it, 1:sz(5))
            fprintf("savemem is true but all inds_*_read_from are equal to their corresponding sz, so you are reading in the entire stack and will not save memory with memmap, so changing savemem to false and using faster tif reader" + newline)
            savemem = 0;
        end
    end
    if isempty(iy) && isempty(ix) && isempty(ic) && isempty(iz) && isempty(it)
        fprintf("savemem is true but all inds_*_read_from are empty, so you are reading in the entire stack and will not save memory with memmap, so changing savemem to false and using faster tif reader" + newline)
        savemem = 0;
    end
end

if stack_size_is_known
    if ~all(iy >= 1 & iy <= sz(1))
        error("REQUESTED iy are not subset of available stack")
    end
    if ~all(ix >= 1 & ix <= sz(2))
        error("REQUESTED ix are not subset of available stack")
    end
    if ~all(ic >= 1 & ic <= sz(3))
        error("REQUESTED ic are not subset of available stack")
    end
    if ~all(iz >= 1 & iz <= sz(4))
        error("REQUESTED iz are not subset of available stack")
    end
    if ~all(it >= 1 & it <= sz(5))
        error("REQUESTED it are not subset of available stack")
    end
else
    if ~isempty(ic) || ~isempty(iz) || ~isempty(it)
        error("you must know stack size to pass nonempty iz or it or ic")
    end
end

if savemem %try with tiffstack
    do_tifreadfast = 0;
    try
        fprintf("savemem is true, trying TIFFStack first to save memory (since you are reading a subset of the stack)" + newline)
        stack = TIFFStack(pthtif); %stack is memmapped tif stack, this doesn't read the stack into memory yet
    catch
        fprintf("savemem tiffstack failed, using tifreadfast" + newline)
        do_tifreadfast = 1;
    end
else
    do_tifreadfast = 1;
end

if do_tifreadfast %try with tifreadfast; compared with tiffstack, tifreadfast is faster and more compatible across operating systems, versions, platforms (because it doens't use mex code); but, tifreadfast can fail for tiffs with varying size per frame, so tiffstack remains in the catch block below (i haven't done the work to make tiffstack work everywhere, which would requyire using different compiled code after system check)
    try
        [stack, mdtif] = tifreadfast(pthtif); %here, stack is read into memory (is not memmapped)
        ny = size(stack, 1);
        nx = size(stack, 2);
        if stack_size_is_known %if you have access to metadata before entering this function
            if ~isequal(prod(sz), numel(stack))
                error("prod(sz), which is likely derived from tif metadata using mdsisv.py, does not match numel(stack) output from tifreadfast; using tiffStack to read tif instead; mismatch can occur if you're reading a tiff written by tiffile imwrite, but there should be no mismatch when reading scanimage output files")
            end
        else %e.g. if you don't have metadata
            if isfield(mdtif.tifinfo, 'Software') && contains(mdtif.tifinfo.Software, 'hChannels.channelSave')
                sistr = mdtif.tifinfo.Software;
            elseif isfield(mdtif, 'ImageDescription') && contains(mdtif.tifinfo.ImageDescription, 'hChannels.channelSave')
                sistr = mdtif.tifinfo.ImageDescription;
            end
            if exist('sistr', 'var') %hack to not put a try catch block within the larer more important try catch (and not repeat several lines of code)
                nc = numel(sistrparse(sistr, 'channelSave'));
                nz = sistrparse(sistr, 'numFramesPerVolumeWithFlyback');
                nt = sistrparse(sistr, 'actualNumVolumes');
                sztmp = [ny, nx, nc, nz, nt];
                if isequal(prod(sztmp), numel(stack))
                    sz = sztmp;
                    stack_size_is_known = 1;
                else
                    error("did not pass metadata into stackld, so tried to parse metadata from tif metadata (derived here, from mdtif output from tifreadfast), but metadata does not match stack; using tiffStack to read tif instead, but cannot reshape czt or index into czt")
                end
            else
                sistr = mdtif.tifinfo.ImageDescription;
                tok = regexp(sistr, '{"shape": (.*)}$', 'tokens');
                tcz_y_x = str2double(regexp(tok{1}{1}, '\d*[\.]?\d*', 'match'));
                ntcz = tcz_y_x(1);
                sztmp = [ny, nx, ntcz];
                if isequal(prod(sztmp), numel(stack))
                    fprintf("size inferred from metadata matches in number elements but size of all dimensions cannot be determined, so stack_size_is_known will not be set to true, and output will be 3d with possible collapsed czt dimensions")
                else
                    error("did not pass metadata into stackld, so tried to parse metadata from tif metadata (derived here, from mdtif output from tifreadfast), but stack size according to metadata does not match stack; using tiffStack to read tif instead, but cannot reshape czt or index into czt")
                end
            end
            fclose(mdtif.fid);
        end
    catch
        stack = []; %clear a potentially large variable
        stack = TIFFStack(pthtif); %here, stack is memmapped tif stack, this doesn't read the stack into memory yet
    end
end

if isempty(iy)
    iy = 1:size(stack,1); %this default can be assigned even if stack_size_is_known==0
end
if isempty(ix)
    ix = 1:size(stack,2); %this default can be assigned even if stack_size_is_known==0
end

if stack_size_is_known

    if isempty(ic)
        ic = 1:sz(3); %this default can only be assigned if stack_size_is_known==1
    end
    if isempty(iz)
        iz = 1:sz(4); %this default can only be assigned if stack_size_is_known==1
    end
    if isempty(it)
        it = 1:sz(5); %this default can only be assigned if stack_size_is_known==1
    end

    inds_t_read_from_all = repelem(it,numel(ic)*numel(iz));
    inds_z_read_from_all = repmat(repelem(iz,numel(ic)), [1 numel(it)]);
    inds_c_read_from_all = repmat(ic, [1 numel(iz)*numel(it)]);
    inds_czt_read_from = sub2ind([sz(3), sz(4), sz(5)], inds_c_read_from_all, inds_z_read_from_all, inds_t_read_from_all); %define 1d inds_zt_read_from for z and t

    stack = stack(iy, ix, inds_czt_read_from); %if using tiffstack, this reads into memory; stack = stack just copies the stack object so cant do that
    stack = reshape(stack, numel(iy), numel(ix), numel(ic), numel(iz), numel(it) );

else

    stack = stack(iy, ix, :); %if using tiffstack, this reads into memory; if you don't know stack size, you can't subset z or t in stack;  stack = stack just copies the stack object so cant do that

    sprintf("WARNING, sz was not passed as argument, or was empty (you did not read metadata before entering this function), or there was a problem reading raw tif metadata; output tif is 3d, and may have collapsed czt dimensions")

end


