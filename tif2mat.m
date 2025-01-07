function stack = tif2mat(pthtif, opt)

%{

convert tif stack yxczt to yxztc, optionally crop  and save
will read entire stack if yxzt is empty
will read subset of stack if any inds_*_read_from are nonempty, but for c, z, and t dimensions, these require yxzt be nonempty
option to crop flyback (cropfb)
option to crop frames (cropt)
option to crop channels (chanuse)
metadata quantities can be read from tif if it's the raw output from scanimage, but other tif stacks output by preprocessing pipeline will not have the metadata, so 

%}

arguments
    pthtif
    opt.chanuse = [1,2] %channels to keep in mat file; default to keep all channels, [1 2], since any absent channel will be ignored 
    opt.cropfb = 0; % before saving stack as mat, crop flyback frames if they exist (if raw scanimage data stack)
    opt.tcrop = [0,0] %num frames to crop from [start, end]
    opt.savemem = 0 %1 will use tiffstack (memmap stack, can save memory if you want to read subset of stack with inds_*_read_from, but usually slower, and also uses mex code that might break on some os/versions/platforms; 0 will use tifreadfast (usually faster, but doens't memmap, reads entire stack into memory initially (or at best a subset of "frames" which are collapsed czt dimensions, so not useful for saving memory if you don't have metadata already to correctly form those indices (maybe a todo)
    opt.iy = [] %y indices to save; empty for all; if savemem, only this subset will get read into memory  
    opt.ix = [] %x indices to save; empty for all; if savemem, only this subset will get read into memory
    opt.ic = [] %c indices to save; empty for all; if savemem, only this subset will get read into memory
    opt.iz = [] %z indices to save; empty for all; if savemem, only this subset will get read into memory
    opt.it = [] %t indices to save; empty for all; if savemem, only this subset will get read into memory
end


chanuse = opt.chanuse;
cropfb = opt.cropfb;
tcrop = opt.tcrop;
savemem = opt.savemem;
iy = opt.iy;
ix = opt.ix;
ic = opt.ic;
iz = opt.iz;
it = opt.it;

id = idmake(pthtif); %just in case id info gets used below
pthmd = [id.dirstack id.recid '_mdsi_.txt'];
numslice_withflyback = structfile(pthmd, nm='numslice_withflyback');

if ~isempty(iz) && ~isempty(cropfb)
    sprintf("WARNING, iz is nonempty AND cropfb is true; ignoring cropfb to give priority to the user-supplied iz, which may or may not crop flyback")
end

[~, fn, ext] = fileparts(pthtif);

pthmat = regexprep(pthtif, '.tif', '.mat');

if isempty(yxzt)
    stack_size_is_known = 0;
else
    stack_size_is_known = 1;
end

if stack_size_is_known

    if contains(fn, 'trial_') && contains(fn, '-') || contains(fn, 'raw')
        sz = [yxzt(1), yxzt(2), numel(channel_save), numslice_withflyback, yxzt(4)]; %z dimension of sz includes flyback frames for raw stack
    else
        sz = [yxzt(1), yxzt(2), numel(channel_save), yxzt(3), yxzt(4)]; %yxzt; %all other stacks do not have flyback frames, so fullsize is same as yxzt
    end

    if isempty(iy)
        iy = 1:sz(1); %can choose any subset of y, can be discontiguous;
    end
    if isempty(ix)
        ix = 1:sz(2); %can choose any subset of x, can be discontiguous;
    end
    if isempty(ic)
        ic = 1:sz(3); %can choose any subset of t, can be discontiguous
    end
    if isempty(iz)
        if cropfb
            iz = 1:yxzt(3); %can crop flyback before reading into memory by passing subset of inds; in general, can choose any subset of z, can be discontiguous; e.g. passing 1:yxzt(3) will skip flyback frames for raw, while 1:size_z_read_from will read flyback frames;
        else
            iz = 1:sz(4); %read all frames of not cropfb
        end
    end
    if isempty(it)
        it = 1:sz(5); %can choose any subset of t, can be discontiguous
    end

else
    sz = [];
    if ~isempty(ic) || ~isempty(iz) || ~isempty(it)
        error("you must know stack size to pass nonempty iz or it or ic")
    end
end

try
    stack = tifld(pthtif, ...
        savemem = savemem, ...
        sz = sz, ...
        iy = iy, ...
        ix = ix, ...
        ic = ic, ...
        iz = iz, ...
        it = it);
catch ME
    if strcmp(ME.message, '*** TIFFStack: Index exceeds stack dimensions.')
        if ~( contains(fn, 'trial_') && contains(fn, '-') ) && ~contains(fn, 'raw')
            fprintf("you may have discarded a channel in creating " + fn + ext + " trying to load again, this time as single channel" + newline)
            sz(3) = 1;
            ic = 1;
            chanuse = 1;
            stack = tifld(pthtif, ...
                sz = sz, ...
                iy = iy, ...
                ix = ix, ...
                ic = ic, ...
                iz = iz, ...
                it = it);
        end
    else
        rethrow(ME);
    end
end

if ndims(stack)==3
    
    sprintf("WARNING, ignoring tcrop, and chanuse because TIF WAS READ WITHOUT KNOWING STACK SIZE; STACK IS 3D BUT MAY HAVE COLLAPSED non-singtleton c, z, or t into 3rd dimension")

else

    keepinds_t = tcrop(1)+1:yxzt(4)-tcrop(2);
    if ~isequal(keepinds_t, 1:size(stack,5)) && ~isempty(keepinds_t)
        stack = stack(:,:,:,:,keepinds_t);
    end

    chanuse = intersect(channel_save, chanuse); %ignore requested channels that don't exist
    if ~isequal(chanuse, 1:size(stack,3))
        stack = stack(:,:,chanuse,:,:);
    end

end

if ndims(stack)~=3 
    stack = permute(stack, [1 2 4 5 3]);
end

save(pthmat, 'stack', '-v7.3', '-mat')

