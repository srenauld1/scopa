function osave(o)

if numel(o)>1
    error("o must be scalar struct at this point (although it can contain nonscalar substructs)")
end

[pthpar, ~, ~] = fileparts(o.id.pth);
fnopt = [o.id.recid '_options_.txt'];
pthopt = fullfile(pthpar, fnopt);

fid = fopen(pthopt, 'w');
txt = jsonencode(o, PrettyPrint=true);

% remove white-spaces inside vectors and matrices
txt = regexprep(txt,',\s+(?=\d)',','); % , white-spaces digit
txt = regexprep(txt,',\s+(?=-)',','); % , white-spaces minussign
txt = regexprep(txt,'[\s+(?=\d)','['); % [ white-spaces digit
txt = regexprep(txt,'[\s+(?=-)','['); % [ white-spaces minussign
txt = regexprep(txt,'(?<=\d)\s+]',']'); % digit white-spaces ]

fprintf(fid,'%s',txt);
fclose(fid);


end
