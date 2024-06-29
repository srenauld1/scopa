function stack = tif2mat(pth_stack_tif, numslice_withflyback, sz, crop_flyback, zero_stack, keepinds_t)

[~, filnam, ~] = fileparts(pth_stack_tif);

pth_stack_mat = [pth_stack_tif(1:end-4) '.mat'];

if crop_flyback && ( ~isempty(regexp(filnam, 'raw')) || ~isempty(regexp(filnam, 'hires')) )
    size_z_read_from = numslice_withflyback; %raw and hires includes flyback
else
    size_z_read_from = sz(3);
end
size_t_read_from = sz(4);
inds_z_read_from = 1:sz(3); %can choose any subset of z (e.g. passing 1:sz(3) will skip flyback frames for raw and hires, for example, do 1:size_z_read_from to read fluback frames), does not have to be contiguous
inds_t_read_from = 1:size_t_read_from; %can choose any subset of t, does not have to be contiguous
size_read_to = [numel(inds_t_read_from), numel(inds_z_read_from) sz(1) sz(2)]; %read the way it was written for speed, permute within read_tif_tzyx

stack = read_tif_tzyx(pth_stack_tif, ...
    size_read_to, size_z_read_from, size_t_read_from, ...
    inds_z_read_from, inds_t_read_from);

if zero_stack
    datmin = min(stack(:));
    datmax = max(stack(:));
    if ~isa(stack, 'uint16')
        stack = single(stack);
    end
    stack = stack - double(datmin);
    if ~isa(stack, 'uint16')
        if datmax > 2^16-1
            error("ERROR, CLIPPING REQUIRED, CHANGE OUTPUT TYPE")
        end
        stack = uint16(stack);
    end
end

if ~isequal(keepinds_t, 1:size(stack,4))
    stack = stack(:,:,:,keepinds_t);
end

save(pth_stack_mat, 'stack', '-v7.3', '-mat')

