function pthparent = pathparentget(opt)

%{
find path holding all stacks, if no input, user prompted to select path
if you only pass in loc, but you are on o2, output pthparent will be correct for o2 as long as the parent folder has the same name locally and on o2
or set both inputs, loc and o2, and regardless of the parent folder name, the parent path on the current filesystem is found
%}

arguments
    opt.loc = [] %path holding all stacks on loc filesystem  
    opt.o2 = [] %path holding all stacks on o2
end
loc = opt.loc;
o2 = opt.o2;

if isempty(loc)
    if isempty(o2)
        fprintf("YOU HAVE NOT SET loc, OR pthparo2, SO YOU WILL NOW BE PROMPTED TO CHOOSE DIRECTORY" + newline + "THE DIRECTORY YOU CHOOSE WILL BE THE ROOT DIRECTORY FOR STACK SEARCH" + newline)
        pause(2)
        loc = uigetdir(pathscopaget, 'choose directory to search for stacks');
    else
        fprintf("you have set pthparo2 but not loc, assuming it is intentional and treating pthparo2 as your 'loc'" + newline)
        loc = o2;
    end
end
if startsWith(loc, ['~' filesep])
    hm = [getenv('HOME') filesep];
    loc = regexprep(loc, ['^~' filesep], hm);
end
loc = strrep(loc, '/', filesep);
loc = strrep(loc, '\', filesep);
if endsWith(loc, filesep)
    loc = loc(1:end-1);
end
[~, pthstackdir, ~] = fileparts(loc);

envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    if isempty(o2)
        fprintf("O2 parent path not specified, using default path based on parent folder name" + newline)
        pthscopa = pathscopaget();
        spl = strsplit(pthscopa, filesep);
        username = cell2mat(spl(find(contains(spl, 'home'))+1));
        if isempty(username)
            error("scopa may not be in your O2 home folder, make sure to git clone scopa into your O2 home folder")
        end
        pthparent = fullfile('/', 'n', 'scratch', 'users', username(1), username, pthstackdir);
    else
        if endsWith(o2, filesep)
            pthparent = o2(1:end-1);
        end
    end
else
    pthparent = loc;
end

pthparent = [pthparent filesep];
if ~isfolder(pthparent)
    error(sprintf("pthparent '" + pthparent + "' DOES NOT EXIST"))
end


end
