function pth_bin = write_mdl_var(mdlvar, pth_fitdata_prefix, write_suffix)

write_class = class(mdlvar);
write_size = size(mdlvar);
pth_bin = [pth_fitdata_prefix '_' write_class '_' num2str(write_size(1)) '_' num2str(write_size(2)) '_' write_suffix '_.bin'];
fid = fopen(pth_bin, 'w');
fwrite(fid, mdlvar, write_class); %write full fitin.depv_pre, read/index according to epoch right before parfor to avoid large broadcast var
fclose(fid);
