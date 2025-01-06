
function md = mdsi_parse(pth_md)
%parses mdsi, deprecated because jsondecode(readfile(()) does it better
str = fileread(pth_md);
if startsWith(str, '{') && endsWith(str, '}')
    str = str(2:end-1);
    if endsWith(str, '}')
        str = str(1:end-1);
        if endsWith(str, '}')
            error("only written for one nested dict/struct, which is for md_hires; if you want more nesting need to repeat above for each layer")
        end
        str = strsplit(str, '{');
    else
        str = {str};
    end
end
for m = 1:numel(str)
    ts = str{m};
    ts = strsplit(ts, ', "');
    ts = erase(ts, {'{', '}', '"', ':'});
    tsn = regexp(ts, '[+-]?\d+\.?\d*', 'match');
    tss = regexp(ts, '[A-Z_a-z]*', 'match');
    for k = 1:numel(tss)
        if m==1
            md.(tss{k}{1}) = str2double(tsn{k});
        elseif m==2
            md.md_hires.(tss{k}{1}) = str2double(tsn{k});
        end
    end
end
end