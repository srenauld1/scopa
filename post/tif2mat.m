function stack = tif2mat(pth_stack_tif, opt)

% convert tif to mat (yxczt) and save
% set up to take full stack if you pass sz_yxzt, or subset if you pass inds*

arguments
    pth_stack_tif
    opt.sz_yxzt = [] % known size of stack, dim order yxzt
    opt.numslice_withflyback = []
    opt.channel_save = 1
    opt.channel_use = 1
    opt.crop_flyback = 0; % before saving stack as mat, crop flyback frames if they exist (if raw scanimage data stack)
    opt.zero_stack = 1 %subtract min to make min zero
    opt.output_datatype = 'uint16'
    opt.tcropfront = 0 %num frames to crop from beginning
    opt.tcropback = 0 %num frames to crop from end
    opt.inds_y_read_from = []
    opt.inds_x_read_from = []
    opt.inds_c_read_from = []
    opt.inds_z_read_from = []
    opt.inds_t_read_from = []
end


numslice_withflyback = opt.numslice_withflyback;
sz_yxzt = opt.sz_yxzt;
channel_save = opt.channel_save;
channel_use = opt.channel_use;
crop_flyback = opt.crop_flyback;
zero_stack = opt.zero_stack;
output_datatype = opt.output_datatype;
tcropfront = opt.tcropfront;
tcropback = opt.tcropback;
inds_y_read_from = opt.inds_y_read_from;
inds_x_read_from = opt.inds_x_read_from;
inds_c_read_from = opt.inds_c_read_from;
inds_z_read_from = opt.inds_z_read_from;
inds_t_read_from = opt.inds_t_read_from;

if ~isempty(inds_z_read_from) && ~isempty(crop_flyback)
    sprintf("WARNING, inds_z_read_from is nonempty AND crop_flyback is true; ignoring crop_flyback to give priority to the user-supplied inds_z_read_from, which may or may not crop flyback")
end

[~, filnam, ~] = fileparts(pth_stack_tif);

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
        if crop_flyback
            inds_z_read_from = 1:sz_yxzt(3); %can crop flyback before reading into memory by passing subset of inds; in general, can choose any subset of z, can be discontiguous; e.g. passing 1:sz_yxzt(3) will skip flyback frames for raw and hires, while 1:size_z_read_from will read flyback frames;
        else
            inds_z_read_from = 1:size_read_from(4); %read all frames of not crop_flyback
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


stack = tifld(pth_stack_tif, ...
    size_read_from = size_read_from, ...
    inds_y_read_from = inds_y_read_from, ...
    inds_x_read_from = inds_x_read_from, ...
    inds_c_read_from = inds_c_read_from, ...
    inds_z_read_from = inds_z_read_from, ...
    inds_t_read_from = inds_t_read_from);

if ndims(stack)==3
    
    sprintf("WARNING, ignoring tcropback, tcropfront, and channel_use because TIF WAS READ WITHOUT KNOWING STACK SIZE; STACK IS 3D BUT MAY HAVE COLLAPSED non-singtleton c, z, or t into 3rd dimension")

else

    keepinds_t = tcropfront+1:sz_yxzt(4)-tcropback;
    if ~isequal(keepinds_t, 1:size(stack,4)) && ~isempty(keepinds_t)
        stack = stack(:,:,:,:,keepinds_t);
    end

    channel_use = intersect(channel_save, channel_use); %ignore requested channels that don't exist
    stack = stack(:,:,channel_use,:,:);

end

stackmin = min(stack(:));

if zero_stack==0 && stackmin<0 && ( strcmp(output_datatype, 'uint16') || strcmp(output_datatype, 'uint32') || strcmp(output_datatype, 'uint64') )
    sprintf("WARNING, zero_stack==0, but stack min is less than zero, and output_datatype is " + output_datatype + "; forcing zero_stack to be true to prevent lower clipping of unsigned integer output datatype")
    zero_stack = 1;
end

if zero_stack
    stack = stack - stackmin;
end

stack = stacktype_change(stack, output_datatype);

if ndims(stack)~=3 %do this after type conversion in case stack is large
    stack = permute(stack, [1 2 4 5 3]);
end

save(pth_stack_mat, 'stack', '-v7.3', '-mat')

