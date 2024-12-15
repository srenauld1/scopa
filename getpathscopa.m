function pth = getpathscopa()

pthenv = getpathenv();
spl = strsplit(pthenv, filesep);
pth = [strjoin(spl(1:find(~cellfun(@isempty, strfind(spl, 'scopa')))), filesep) filesep];

end
