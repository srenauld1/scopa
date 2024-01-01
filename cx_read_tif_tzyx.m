function out = cx_read_tif_tzyx(filename_tif, ...
    out_datatype, size_read_to, ...
    size_z_read_from, size_t_read_from, ...
    inds_z_read_from, inds_t_read_from)

%scanimage writes as tzyx,
% and so does scopa python pipeline
% (registration,denoising, roi extraction)
%so read it like this, then permute output afterwards
%option to just read a subset of z and t indices to save time
%size_z_read_from and size_t_read_from must match z and t dimensions of tif
%inds_z_read_from and size_t_read_from can be used to only read those z and t indices
%out_datatype defines output data type,
% if allow_data_type_conversion==1 the tif datatype can be converted to
% out_datatype, but this is a work in progress so it's 0 by default
%if tif is 3d (one z slice) then size_z_read_from==1 and it works fine

tsStack = TIFFStack(filename_tif); % Construct a TIFF stack associated with a file

inds_t_read_from_all = [];
for ti = 1:length(inds_t_read_from)
    inds_t_read_from_all = cat(2, inds_t_read_from_all, repmat(inds_t_read_from(ti), [1 length(inds_z_read_from)]));
end
inds_z_read_from_all = repmat(inds_z_read_from, [1 length(inds_t_read_from)]);

keepinds = sub2ind([size_z_read_from, size_t_read_from], inds_z_read_from_all, inds_t_read_from_all);

out = tsStack(:,:,keepinds);
out = reshape(out, size_read_to(3), size_read_to(4), size_read_to(2), size_read_to(1) );

