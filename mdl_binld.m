function [out, vclass] = mdl_binld(pth)

spl = strsplit(pth, '_');
read_size = [str2double(spl{end-3}) str2double(spl{end-2})];
vclass = spl{end-4};
fid = fopen(pth, 'r');
out = fread(fid, read_size, [vclass '=>' vclass]); %read depv then crop, to prevent broadcasting in parfor loop below
fclose(fid);

