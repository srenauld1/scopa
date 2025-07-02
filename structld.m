function s = structld(pth, opt)

% load json-encoded struct from file 
% warning: when reading struct from file, jsencode (called below) will insert an 'x' at the beginning of any fieldname that doesn't begin with a letter (an invalid fieldname); if a file was written with structsv, it will not contain invalid fieldnames because structsv only writes valid structs) 

arguments
    pth %path to txt file containing struct
    opt.sort = 1; %alphabetically sort struct (natural sort)
    opt.vectype = 'row'; %empty, row, or column; transpose any vector in read struct that is not vectype; skip if empty; default is row to ensure consistency across read/write
    opt.nocells = 0; %convert char in cell to singleton char, convert char cell array to string array (to dismbiguate cell (which designates options for expansion) and string arrays, which get mixed up in jsonencode and jsondecode)
    opt.flat = 0; %flatten struct 
end


s = fileread(pth);
s = jsondecode(s);
if opt.flat
    s = structflat(s);
end
if opt.sort
    s = structsort(s, vectype=opt.vectype, nocells=opt.nocells);
else
    if ~strcmp(opt.vectype, 'row')
        error(sprintf("nondefault value for name-value option vectype only has effect if name-value option sort is true, but sort is false"))
    end
    if opt.nocells~=0
        error(sprintf("name-value option nocells=1 only has effect if name-value option sort is true, but sort is false"))
    end
end

end
