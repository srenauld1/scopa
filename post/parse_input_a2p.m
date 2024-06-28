function filespec_in = parse_input_a2p(pth_tif_read_all)

[~, fnin, ~] = fileparts(pth_tif_read_all);
spl = strsplit(fnin, '_');
filespec_in.recdate = spl{1}; %can use wildcards
filespec_in.fly = spl{2}; %can use wildcards
filespec_in.trial = spl{3}; %can use wildcards
tmp = strjoin(spl(4:end), '_');
if strcmp(tmp(end), '_')
    tmp = tmp(1:end-1);
end
filespec_in.suffix_analysis = tmp;

end