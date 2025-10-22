function pth = pthscopaget()

%get path to repository 'scopa' as path to folder running this file

cs = dbstack('-completenames');
pth = fileparts(cs(1).file);
if endsWith(pth, [filesep 'scopa'])
    pth = pthfldformat(pth);
else
    error("pthscopaget is not in a folder named scopa")
end

end
