function pth = pthfldformat(pth)

%format path to folder with correct file separators and trailing file separator 

if ~isempty(pth)
    if startsWith(pth, '~')
        hm = getenv('HOME');
        if endsWith(hm, filesep)
            hm = hm(1:end-1);
        end
        pth = regexprep(pth, '^~', hm);
    end
    pth = strrep(pth, '/', filesep);
    pth = strrep(pth, '\', filesep);
    if ~endsWith(pth, filesep)
        pth = [pth filesep];
    end
end

end