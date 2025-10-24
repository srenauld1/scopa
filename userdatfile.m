function userdat = userdatfile(field, opt, opt2)

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
    opt2.err (1,1) {mustBeMember(opt2.err,[0,1]), mustBeNonempty} = 0 %1 to error if trying to read field from userdat.txt that has not been set
end
err = opt2.err;

optsin = ~structfun(@isempty, opt);

permission = 'read';
if isempty(field)
    if any(optsin)
        permission = 'write';
    end
else
    if any(optsin)
        error("cannot pass in any name-value arguments if positional first argument is also nonempty")
    end
end


opt.pthpar = pthfldformat(opt.pthpar); %format path to folder
opt.pthparo2 = pthfldformat(opt.pthparo2); %format path to folder

if ~isempty(opt.scopausername) && isempty(regexp(opt.scopausername, '^[a-zA-Z]+$', 'once'))
    error('scopausername (if nonempty) can only contain alphabetic characters')
end
if isempty(opt.gittoken) && isempty(opt.gitusername) && isempty(opt.gitbranch)
    saferun = 0; %if gittoken and gitusername are nonempty, no need to require "saferun" (ie run from command line)
else
    saferun = 1;
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
            "or, on this filesystem, in the command line, run userdatfile with whatever name-value arguments you want to set (anything unset will be empty)" + newline + ...
            "if you run userdatfile in the command line on this filesystem, and do already have userdat.txt on another filesystem, make sure the arguments match those you used on the other filesystem" + newline + ...
            "name-value arguments are: " + newline + tmppr(1:end-1) + newline + ...
            "'scopausername' is required to run much of a2p" + newline + ...
            "'pthpy' is required to run python from matlab" + newline + ...
            "'pthpar' gets set automatically when the code encounters function 'pthparget', and the user is prompted to select pthpar" + newline + ...
            "'pthpar_o2' gets set automatically, although it can be wrong if you haven't given the parent folder of all stacks the same name on o2 and local filesystems" + newline + ...
            "name-value arguments referencing git are required to integrate changes across filesystems (ie for any function where usegit=1)")
    end
    if ~isempty(field)
        if isfield(userdat, field)
            userdat = userdat.(field);
            if isempty(userdat) && err
                error("requested userdat field'" + field + "' has not been set in userdat.txt, and name-value argument err=1, so this error occurred; if you don't want an error, make err=0, or set userdatfile('" + field + "')")
            end
        else
            error("'" + field + "' is not field of userdat struct in userdatfile " + pthuserdat)
        end
    end

else

    callstack = dbstack;

    if saferun && ~( isscalar(callstack) && strcmp(callstack.file, 'userdatfile.m') )
        error("for security, when writing any git information to userdat.txt, you must run userdatfile from command line; if you did run userdatfile from command line, you may have run userdatfile while paused in debugger mode; stop debugger and run from command line");
    else
        if isfile(pthuserdat)
            userdat = structld(pthuserdat);
        else
            userdat = opt;
        end
        fnopt = fieldnames(opt);
        for k = 1:numel(fnopt)
            if ~isempty(opt.(fnopt{k}))
                userdat.(fnopt{k}) = opt.(fnopt{k});
            end
        end
        if ~isfield(userdat, 'pthscopa') || isempty(userdat.pthscopa)
            userdat.pthscopa = pthscopa;  %add this automatically, to avoid accidental mismatch between real location output from pthscopaget, and location set here (if it were user input)
        end

        structsv(userdat, pthuserdat, overwrite=1, readonly=1, dosort=1);
    end

end