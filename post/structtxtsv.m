function structtxtsv(s, pth, opt)


arguments
    s %struct to save
    pth %save path
    opt.vectype = 'row'; %empty, row, or column; transpose any vector in read struct that is not vectype; skip if empty; default is row to ensure consistency across read/write
end

s = structord(s, vectype=opt.vectype);

txt = jsonencode(s, PrettyPrint=true);
txt = regexprep(txt,',\s+(?=\d)',','); % , white-spaces digit remove
txt = regexprep(txt,',\s+(?=-)',','); % , white-spaces minussign remove
txt = regexprep(txt,'[\s+(?=\d)','['); % [ white-spaces digit remove
txt = regexprep(txt,'[\s+(?=-)','['); % [ white-spaces minussign remove
txt = regexprep(txt,'(?<=\d)\s+]',']'); % digit white-spaces ] remove

fid = fopen(pth, 'w');
fprintf(fid,'%s',txt);
fclose(fid);

end