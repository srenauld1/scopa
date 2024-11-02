function d = structtxtld(pth, opt)

arguments
    pth %path to txt file containing struct 
    opt.vectype = 'row'; %empty, row, or column; transpose any vector in read struct that is not vectype; skip if empty; default is row to ensure consistency across read/write
    opt.nocells = 0; %convert char in cell to singleton char, convert char cell array to string array (to dismbiguate cell (which designates options for expansion) and string arrays, which get mixed up in jsonencode and jsondecode) 
end

d = fileread(pth);
d = jsondecode(d);
d = structord(d, vectype=opt.vectype, nocells=opt.nocells);

end
