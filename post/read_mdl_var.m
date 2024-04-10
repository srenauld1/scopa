function [mdlvar, read_class] = read_mdl_var(pth_bin)

spl = strsplit(pth_bin, '_');
read_size = [str2double(spl{end-3}) str2double(spl{end-2})];
read_class = spl{end-4};
fid = fopen(pth_bin, 'r');
mdlvar = fread(fid, read_size, [read_class '=>' read_class]); %read depv then crop, to prevent broadcasting in parfor loop below
fclose(fid);

