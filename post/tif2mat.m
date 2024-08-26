function stack = tif2mat(pth_stack_tif, opt)

% convert tif to mat and save mat
% options to 

arguments
    pth_stack_tif
    opt.numslice_withflyback = []
    opt.sz_yxczt = [] % known size of stack, dim order yxzt
    opt.crop_flyback = 0; % before saving stack as mat, crop flyback frames if they exist (if raw scanimage data stack)
    opt.zero_stack = 1 %subtract min to make min zero
    opt.output_datatype = 'uint16'
    opt.tcropfront = 0 %num frames to crop from beginning
    opt.tcropback = 0 %num frames to crop from end
end

numslice_withflyback = opt.numslice_withflyback;
sz_yxczt = opt.sz_yxczt;
crop_flyback = opt.crop_flyback;
zero_stack = opt.zero_stack;
output_datatype = opt.output_datatype;
tcropfront = opt.tcropfront;
tcropback = opt.tcropback;

[~, filnam, ~] = fileparts(pth_stack_tif);

pth_stack_mat = [pth_stack_tif(1:end-4) '.mat'];

if contains(filnam, 'trial_') && contains(filnam, '-') || contains(filnam, 'hires')
    fullsize_read_from = [sz_yxczt(1), sz_yxczt(2), 1, numslice_withflyback, sz_yxczt(4)]; %z dimension of fullsize_read_from includes flyback frames for raw and hires stacks 
else
    fullsize_read_from = [sz_yxczt(1), sz_yxczt(2), 1, sz_yxczt(3), sz_yxczt(4)]; %sz_yxczt; %all other stacks do not have flyback frames, so fullsize is same as sz_yxczt
end

if crop_flyback
    inds_z_read_from = 1:sz_yxczt(3); %can crop flyback before reading into memory by passing subset of inds; in general, can choose any subset of z, can be discontiguous; e.g. passing 1:sz_yxczt(3) will skip flyback frames for raw and hires, while 1:size_z_read_from will read flyback frames;
else
    inds_z_read_from = 1:fullsize_read_from(4); %read all frames of not crop_flyback
end

inds_y_read_from = 1:fullsize_read_from(1); %can choose any subset of y, can be discontiguous;
inds_x_read_from = 1:fullsize_read_from(2); %can choose any subset of x, can be discontiguous;
inds_c_read_from = 1:fullsize_read_from(3); %can choose any subset of t, can be discontiguous
inds_t_read_from = 1:fullsize_read_from(5); %can choose any subset of t, can be discontiguous


stack = read_tif_tzyx(pth_stack_tif, ...
    size_read_to=fullsize_read_from, ...
    inds_y_read_from = inds_y_read_from, ...
    inds_x_read_from = inds_x_read_from, ...
    inds_c_read_from = inds_c_read_from, ...
    inds_z_read_from = inds_z_read_from, ...
    inds_t_read_from = inds_t_read_from);

if isa(stack, 'int8') || isa(stack, 'uint8')
    error("a2p currently does not support int8 or uint8 stacks, although could with a few minor changes")
end


datmin = min(stack(:));

if zero_stack==0 && datmin<0 && ( strcmp(output_datatype, 'uint16') || strcmp(output_datatype, 'uint32') || strcmp(output_datatype, 'uint64') )
    sprintf("WARNING, zero_stack==0, BUT stack min is less than zero, and output_datatype is " + output_datatype + ", forcing zero_stack to be true to prevent lower clipping of unsigned integer output datatype")
    zero_stack = 1;
end

if zero_stack
    sprintf("CONVERTING STACK TO SINGLE PRECISION PRIOR TO SUBTRACTING MIN SINCE MIN IS NEGATIVE AND STACK DATATYPE IS SIGNED INTEGER")
    if datmin<0 && ( isa(stack, 'int16') || isa(stack, 'int32') || isa(stack, 'int64') )
        stack = single(stack); %convert to single before subtracting min since there are negatives
    end
    stack = stack - double(datmin);
end

if ~isa(stack, output_datatype)
    datmax = max(stack(:));
    if datmax > intmax(output_datatype)
        error("ERROR, CONVERTING TO output_datatype " + output_datatype + " WILL CAUSE UPPER CLIPPING, CHANGE output_datatype")
    end
    switch output_datatype
        case 'uint16'
            stack = uint16(stack);
        case 'uint32'
            stack = uint32(stack);
        case 'uint64'
            stack = uint64(stack);
        case 'int16'
            stack = int16(stack);
        case 'int32'
            stack = int32(stack);
        case 'int64'
            stack = int64(stack);
        case 'single'
            stack = single(stack);
        case 'double'
            stack = double(stack);
    end

end

if isempty(tcropfront)
    tcropfront = 0;
end
if isempty(tcropback)
    tcropback = 0;
end

keepinds_t = tcropfront+1:sz_yxczt(4)-tcropback; %same as all t inds (1:sz_yxczt(4)) if tcropfront and tcropback are both 0
if ~isequal(keepinds_t, 1:size(stack,4))
    stack = stack(:,:,:,keepinds_t);
end

save(pth_stack_mat, 'stack', '-v7.3', '-mat')

