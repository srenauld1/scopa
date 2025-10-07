function userdat = userdatfile(field, opt)

%{

read/write user-specific data to/from file 'userdat.txt'
userdat.txt is saved to scopa but not version-controlled (userdat.txt is in .gitignore)
note pthscopa is automatically added below (does not rely on user input) to prevent accidental mismatch

%}

arguments
    field = []
    opt.pthpar = [] %path to folder containing all stacks
    opt.pthparo2 = [] %path to folder containing all stacks on o2 
    opt.pthpy = [] %path to python executable (for running python from matlab)
    opt.scopausername = [] %your scopa username (to enter your oset_* files)
    opt.gittoken = [] %your git token (for push/pull etc)
    opt.gitbranch = [] %your scopa git branch (for push/pull etc)
    opt.gitusername = [] %your git username (for push/pull etc)
end

optsin = ~structfun(@isempty, opt);

permission = 'read';
if isempty(field)
    if any(optsin)
        permission = 'write';
    end
else
    if any(optsin)
        error("cannot pass in any nonempty name-value arguments if positional first argument is also nonempty")
    end
end

if ~isempty(opt.pthpar)
    opt.pthpar = pthfldformat(opt.pthpar); %format path to folder 
end
if ~isempty(opt.pthparo2)
    opt.pthparo2 = pthfldformat(opt.pthparo2); %format path to folder 
end

pthscopa = pthscopaget();

pthuserdat = [pthscopa 'userdat.txt'];

if strcmpi(permission, 'read')

    if isfile(pthuserdat)
        userdat = structld(pthuserdat);
    else
        fno = fieldnames(opt);
        tmppr = sprintf('%s\n', fno{:});
        error(pthuserdat + " does not exist on this filesystem" + newline + ...
            "if you have userdat.txt on another filesystem, copy it to this filesystem" + newline + ...
            "or, on this filesystem, in the command line, run userdatfile with all name-value arguments set, even if you have to set them to empty" + newline + ...
            "if you run userdatfile in the command line on this filesystem, and do already have userdat.txt on another filesystem, make sure the arguments match those you used on the other filesystem" + newline + ...
            "name-value arguments are: " + newline + tmppr(1:end-1))
    end
    if ~isempty(field)
        if isfield(userdat, field)
            userdat = userdat.(field);
        else
            error("'" + field + "' is not field of userdat struct in userdatfile " + pthuserdat)
        end
    end

else

    tmp = dbstack;
    if isscalar(tmp) && strcmp(tmp.file, 'userdatfile.m')
        if isfile(pthuserdat)
            userdat = structld(pthuserdat);
        end
        fnopt = fieldnames(opt);
        for k = 1:numel(fnopt)
            userdat.(fnopt{k}) = opt.(fnopt{k});
        end
        userdat.pthscopa = pthscopa;  %add this automatically, to avoid accidental mismatch between real location output from pthscopaget, and location set here (if it were user input)
        structsv(userdat, pthuserdat, overwrite=1, readonly=1, dosort=1);
    else
        error("for security, when writing to userdat.txt, you must run userdatfile from command line")
    end

end