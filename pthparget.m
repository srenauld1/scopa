function pthpar = pthparget()

%{

find path holding all stacks on the current filesystem, using paths input to userdat.txt
if pthpar and pthparo2 have not been set in userdat.txt, user prompted to select path
if you have only set pthpar in userdat.txt, but you are currently on o2, output pthpar is automatically derived, and will be correct for o2 as long as the parent folder has the same name in pthpar as on o2
if pthpar and pthparo2 have both been set in userdat.txt, pthpar is whichever one is on the current filesystem

%}

write_to_userdat = 0;
try
    loc = userdatfile('pthpar');
    o2 = userdatfile('pthparo2');
catch
    loc = [];
    o2 = [];
    write_to_userdat = 1;
end

pthscopa = pthscopaget();

envname = getenv('HOSTNAME');
if isempty(regexp( envname, 'compute-', 'once' ))
    on_o2 = 0;
else
    on_o2 = 1;
end

if isempty(loc)
    if isempty(o2)
        fprintf("YOU HAVE NOT SET userdatfile('pthpar'), OR userdatfile('pthparo2'), SO YOU WILL NOW BE PROMPTED TO CHOOSE DIRECTORY" + newline + "THE DIRECTORY YOU CHOOSE WILL BE THE ROOT DIRECTORY FOR STACK SEARCH" + newline)
        pause(2)
        loc = uigetdir(pthscopa, 'choose directory to search for stacks');
    else
        if on_o2
            fprintf("you have set userdatfile('pthparo2') but not userdatfile('pthpar'), assuming you are on o2" + newline)
            loc = o2;
        else
            fprintf("YOU HAVE SET userdatfile('pthparo2') BUT NOT userdatfile('pthpar'), AND YOU ARE NOT ON O2, SO YOU WILL NOW BE PROMPTED TO CHOOSE DIRECTORY" + newline + "THE DIRECTORY YOU CHOOSE WILL BE THE ROOT DIRECTORY FOR STACK SEARCH" + newline)
            pause(2)
            loc = uigetdir(pthscopa, 'choose directory to search for stacks');
        end
    end
end
loc = pthfldformat(loc); %format path to folder
if endsWith(loc, filesep)
    loc = loc(1:end-1);
end
[~, fldpar, ~] = fileparts(loc);

if on_o2
    if isempty(o2)
        fprintf("pthparo2 (parent path to all stacks on O2) was not specified" + newline + ...
            "deriving default pthparo2 based on pthpar (parent path to all stacks on your local machine)" + newline + ...
            "for this to work pthpar and pthparo2 must end with the same folder name (e.g., 'stacks')" + newline)
        spl = strsplit(pthscopa, filesep);
        username_o2 = cell2mat(spl(find(contains(spl, 'home'))+1));
        if isempty(username_o2)
            error("scopa may not be in your O2 home folder; to automatically derive pthparo2, scopa must be in your O2 home folder")
        end
        pthpar = fullfile('/', 'n', 'scratch', 'users', username_o2(1), username_o2, fldpar);
    else
        if endsWith(o2, filesep)
            pthpar = o2(1:end-1);
        end
    end
else
    pthpar = loc;
end

pthpar = [pthpar filesep];
if ~isfolder(pthpar)
    error("ON THIS FILESYSTEM, '" + pthpar + "' DOES NOT EXIST OR IS NOT A FOLDER")
end

if write_to_userdat
    fprintf("writing pthpar to userdat.txt, but no other fields will be written now" + newline)
    if on_o2
        userdat.pthparo2 = pthpar;
    else
        userdat.pthpar = pthpar;
    end
    prs = struct2pairs(userdat);
    userdatfile(prs{:})
end



end
