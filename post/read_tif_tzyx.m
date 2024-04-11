function out = read_tif_tzyx(filename_tif, ...
    size_read_to, ...
    size_z_read_from, size_t_read_from, ...
    inds_z_read_from, inds_t_read_from)

%scanimage writes as tzyx, and so does scopa python pipeline
%custom function TIFFStack (not mine) can read this dim order
%option to just read a subset of z and t indices to save time (inds_z_read_from, inds_t_read_from)
%size_z_read_from and size_t_read_from must match z and t dimensions of tif
%tifs from scopa can be 3d or 4d and can be read here without issue 

tsStack = TIFFStack(filename_tif); % Construct a TIFF stack associated with a file, this doesn't read the stack into memory

inds_t_read_from_all = [];
for i = 1:length(inds_t_read_from)
    inds_t_read_from_all = cat(2, inds_t_read_from_all, repmat(inds_t_read_from(i), [1 length(inds_z_read_from)]));
end
inds_z_read_from_all = repmat(inds_z_read_from, [1 length(inds_t_read_from)]);

keepinds_zt = sub2ind([size_z_read_from, size_t_read_from], inds_z_read_from_all, inds_t_read_from_all); %define 1d keepinds_zt for z and t 

out = tsStack(:,:,keepinds_zt); %this reads the stack (or subset) into memory
out = reshape(out, size_read_to(3), size_read_to(4), size_read_to(2), size_read_to(1) );

