function structsv(s, pth, opt)


arguments
    s %struct to save
    pth %save path
    opt.dosort = 0; %alphabetically dosort struct (natural dosort)
    opt.vectype = 'row'; %empty, row, or column; transpose any vector in read struct that is not vectype; skip if empty; default is row to ensure consistency across read/write
    opt.nocells = 0; %convert char in cell to singleton char, convert char cell array to string array (to dismbiguate cell (which designates options for expansion) and string arrays, which get mixed up in jsonencode and jsondecode)
    opt.flat = 0; %flatten struct
    opt.overwrite = 0; %if 1, overwrite if file exists, or write if file doesn't exist; if 0, error if file exists
    opt.readonly = 0; %make read-only
end


if opt.flat
    s = structflat(s);
end

s = structsort(s, vectype=opt.vectype, nocells=opt.nocells, skipsort= ~opt.dosort);

txt = jsonencode(s, PrettyPrint=true, ConvertInfAndNaN=false);
txt = regexprep(txt,',\s+(?=\d)',','); % , white-spaces digit remove
txt = regexprep(txt,',\s+(?=-)',','); % , white-spaces minussign remove
txt = regexprep(txt,'[\s+(?=\d)','['); % [ white-spaces digit remove
txt = regexprep(txt,'[\s+(?=-)','['); % [ white-spaces minussign remove
txt = regexprep(txt,'(?<=\d)\s+]',']'); % digit white-spaces ] remove

if isfile(pth)
    if opt.overwrite
        fileattrib(pth,'+w')
    else
        error("you're trying to write to a file that already exists, but opt.overwrite is 0; make opt.overwrite 1 or rename file")
    end
end
fid = fopen(pth, 'w');
fprintf(fid,'%s',txt);
if opt.readonly
    fileattrib(pth,'-w','a')
end
fclose(fid);

end

