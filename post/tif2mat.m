function stack = tif2mat(pth_stack_tif, opt)

% convert tif to mat (yxczt) and save
% set up to take full stack if you pass sz_yxzt, or subset if you pass inds*

arguments
    pth_stack_tif
    opt.sz_yxzt = [] % known size of stack, dim order yxzt
    opt.numslice_withflyback = []
    opt.channel_save = 1 %saved channels
    opt.chanuse = [1 2] %channels to keep in mat file; default to keep all channels, [1 2], since any absent channel will be ignored 
    opt.cropfb = 0; % before saving stack as mat, crop flyback frames if they exist (if raw scanimage data stack)
    opt.tcrop = [0, 0] %num frames to crop from [start, end]
    opt.inds_y_read_from = []
    opt.inds_x_read_from = []
    opt.inds_c_read_from = []
    opt.inds_z_read_from = []
    opt.inds_t_read_from = []
end


numslice_withflyback = opt.numslice_withflyback;
sz_yxzt = opt.sz_yxzt;
channel_save = opt.channel_save;
chanuse = opt.chanuse;
cropfb = opt.cropfb;
tcrop = opt.tcrop;
inds_y_read_from = opt.inds_y_read_from;
inds_x_read_from = opt.inds_x_read_from;
inds_c_read_from = opt.inds_c_read_from;
inds_z_read_from = opt.inds_z_read_from;
inds_t_read_from = opt.inds_t_read_from;

if ~isempty(inds_z_read_from) && ~isempty(cropfb)
    sprintf("WARNING, inds_z_read_from is nonempty AND cropfb is true; ignoring cropfb to give priority to the user-supplied inds_z_read_from, which may or may not crop flyback")
end

[~, filnam, fnext] = fileparts(pth_stack_tif);

pth_stack_mat = [pth_stack_tif(1:end-4) '.mat'];

if isempty(sz_yxzt)
    stack_size_is_known = 0;
else
    stack_size_is_known = 1;
end

if stack_size_is_known

    if contains(filnam, 'trial_') && contains(filnam, '-') || contains(filnam, 'raw') || contains(filnam, 'hires')
        size_read_from = [sz_yxzt(1), sz_yxzt(2), numel(channel_save), numslice_withflyback, sz_yxzt(4)]; %z dimension of size_read_from includes flyback frames for raw and hires stacks
    else
        size_read_from = [sz_yxzt(1), sz_yxzt(2), numel(channel_save), sz_yxzt(3), sz_yxzt(4)]; %sz_yxzt; %all other stacks do not have flyback frames, so fullsize is same as sz_yxzt
    end

    if isempty(inds_y_read_from)
        inds_y_read_from = 1:size_read_from(1); %can choose any subset of y, can be discontiguous;
    end
    if isempty(inds_x_read_from)
        inds_x_read_from = 1:size_read_from(2); %can choose any subset of x, can be discontiguous;
    end
    if isempty(inds_c_read_from)
        inds_c_read_from = 1:size_read_from(3); %can choose any subset of t, can be discontiguous
    end
    if isempty(inds_z_read_from)
        if cropfb
            inds_z_read_from = 1:sz_yxzt(3); %can crop flyback before reading into memory by passing subset of inds; in general, can choose any subset of z, can be discontiguous; e.g. passing 1:sz_yxzt(3) will skip flyback frames for raw and hires, while 1:size_z_read_from will read flyback frames;
        else
            inds_z_read_from = 1:size_read_from(4); %read all frames of not cropfb
        end
    end
    if isempty(inds_t_read_from)
        inds_t_read_from = 1:size_read_from(5); %can choose any subset of t, can be discontiguous
    end

else
    size_read_from = [];
    if ~isempty(inds_c_read_from) || ~isempty(inds_z_read_from) || ~isempty(inds_t_read_from)
        error("you must know stack size to pass nonempty inds_z_read_from or inds_t_read_from or inds_c_read_from")
    end
end

try
    stack = tifld(pth_stack_tif, ...
        size_read_from = size_read_from, ...
        inds_y_read_from = inds_y_read_from, ...
        inds_x_read_from = inds_x_read_from, ...
        inds_c_read_from = inds_c_read_from, ...
        inds_z_read_from = inds_z_read_from, ...
        inds_t_read_from = inds_t_read_from);
catch ME
    if strcmp(ME.message, '*** TIFFStack: Index exceeds stack dimensions.')
        if ~( contains(filnam, 'trial_') && contains(filnam, '-') ) && ~contains(filnam, 'raw') && ~contains(filnam, 'hires')
            fprintf("you may have discarded a channel in creating " + filnam + fnext + " trying to load again, this time as single channel" + newline)
            size_read_from(3) = 1;
            inds_c_read_from = 1;
            chanuse = 1;
            stack = tifld(pth_stack_tif, ...
                size_read_from = size_read_from, ...
                inds_y_read_from = inds_y_read_from, ...
                inds_x_read_from = inds_x_read_from, ...
                inds_c_read_from = inds_c_read_from, ...
                inds_z_read_from = inds_z_read_from, ...
                inds_t_read_from = inds_t_read_from);
        end
    else
        rethrow(ME);
    end
end

if ndims(stack)==3
    
    sprintf("WARNING, ignoring tcrop, and chanuse because TIF WAS READ WITHOUT KNOWING STACK SIZE; STACK IS 3D BUT MAY HAVE COLLAPSED non-singtleton c, z, or t into 3rd dimension")

else

    keepinds_t = tcrop(1)+1:sz_yxzt(4)-tcrop(2);
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

save(pth_stack_mat, 'stack', '-v7.3', '-mat')

