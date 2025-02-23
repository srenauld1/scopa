function pthparent = pthparentfind(pthparent_local, pthparent_o2)

pthparent_local = strrep(pthparent_local, '/', filesep);
pthparent_local = strrep(pthparent_local, '\', filesep);
if endsWith(pthparent_local, filesep)
    pthparent_local = pthparent_local(1:end-1);
end
[~, pthstackdir, ~] = fileparts(pthparent_local);

envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    if isempty(pthparent_o2)
        fprintf("O2 parent path not specified, using default path based on parent folder name" + newline)
        pthscopa = getpathscopa();
        spl = strsplit(pthscopa, filesep);
        username = cell2mat(spl(find(contains(spl, 'home'))+1));
        if isempty(username)
            error("scopa may not be in your O2 home folder, make sure to git clone scopa into your O2 home folder")
        end
        pthparent = fullfile('/', 'n', 'scratch', 'users', username(1), username, pthstackdir);
    else
        if endsWith(pthparent_o2, filesep)
            pthparent = pthparent_o2(1:end-1);
        end
    end
else
    pthparent = pthparent_local;
end

pthparent = [pthparent filesep];
if ~isfolder(pthparent)
    error(sprintf("pthparent '" + pthparent + "' DOES NOT EXIST"))
end


end
