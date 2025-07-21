function userdat = userdatsv(permission, opt)

%write user-specific info to txt file that is saved to scopa, but not version-controlled (listed in .gitignore)

arguments
    permission %'read' or 'write'
    opt.field = []
    opt.scopausername = []
    opt.gittoken = []
    opt.gitbranch = []
    opt.gitusername = []
end

field = opt.field;

userdat.scopausername = opt.scopausername;
userdat.gittoken = opt.gittoken;
userdat.gitbranch = opt.gitbranch;
userdat.gitusername = opt.gitusername;


pthscopa = getpathscopa();
pthuserdat = [pthscopa 'userdat.txt'];

if strcmpi(permission, 'read')
    
    if ~isempty(userdat.scopausername) || ~isempty(userdat.gittoken) || ~isempty(userdat.gitbranch) || ~isempty(userdat.gitusername)
        error("for first argument 'read', cannot pass in the following name-value arguments: scopausername, gittoken, gitbranch, and gitusername")
    end
    if isfile(pthuserdat)
        userdat = structld(pthuserdat);
    else
        error(sprintf(pthuserdat + " does not exist, in the command line, run userdatsv with first argument 'write' and all required name-value arguments, like this (but fill in the blanks): " + newline + "userdatsv('write', scopausername=, gittoken=, gitbranch=, gitusername=)"))
    end
    if ~isempty(field)
        userdat = userdat.(field);
    end

elseif strcmpi(permission, 'write')

    if isempty(userdat.scopausername) || isempty(userdat.gittoken) || isempty(userdat.gitbranch) || isempty(userdat.gitusername)
        error("for first argument 'write', must pass in the following name-value arguments: scopausername, gittoken, gitbranch, and gitusername")
    end
    if ~isempty(field)
        error("for first argument 'write', cannot pass in the following name-value argument: field")
    end

    tmp = dbstack;
    if isscalar(tmp) && strcmp(tmp.file, 'userdatsv.m')
        if isfile(pthuserdat)
            error(sprintf(pthuserdat + " already exists, delete it and run userdatsv again"))
        else
            structsv(userdat, pthuserdat, readonly=1, dosort=1);
        end
    else
        error("for security, you must run userdatsv with first argument 'write' from command line")
    end

else

    error("first argument (permission) must be 'read' or 'write'")

end