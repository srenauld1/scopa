function userdat = userdatfile(field, opt)

% read/write user-specific data to/from txt file that is saved to scopa, but not version-controlled (listed in .gitignore)

arguments
    field = []
    opt.scopausername = []
    opt.gittoken = []
    opt.gitbranch = []
    opt.gitusername = []
end

numfields = numel(fieldnames(opt));
optsin = ~structfun(@isempty, opt);

permission = 'read';
if isempty(field)
    if any(optsin)
        if isequal(sum(optsin), numfields)
            permission = 'write';
        else
            error("must pass in all, or no, name-value arguments")
        end
    end
else
    if any(optsin)
        error("cannot pass in any nonempty name-value arguments if positional first argument is also nonempty")
    end
end

pthscopa = getpathscopa();
pthuserdat = [pthscopa 'userdat.txt'];

if strcmpi(permission, 'read')

    if isfile(pthuserdat)
        userdat = structld(pthuserdat);
    else
        error(sprintf(pthuserdat + " does not exist, in the command line, run userdatfile with all name-value arguments, and nothing else, like this (but fill in the blank value for each name-value argument): " + newline + "userdatfile(scopausername=, gittoken=, gitbranch=, gitusername=)"))
    end
    if ~isempty(field)
        userdat = userdat.(field);
    end

else

    tmp = dbstack;
    if isscalar(tmp) && strcmp(tmp.file, 'userdatfile.m')
        if isfile(pthuserdat)
            error(sprintf(pthuserdat + " already exists, delete it and run userdatfile again"))
        else
            userdat = opt;
            structsv(userdat, pthuserdat, readonly=1, dosort=1);
        end
    else
        error("for security, you must run userdatfile with first argument 'w' from command line")
    end

end