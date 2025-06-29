function userdat = scopauser(permission, opt)

%write user-specific info to txt file that is saved to scopa, but not version-controlled (listed in .gitignore)

arguments
    permission %'read' or 'write'
    opt.scopauserid = []
    opt.gittoken = []
    opt.gitbranch = []
    opt.gitusername = []
end
userdat.scopauserid = opt.scopauserid;
userdat.gittoken = opt.gittoken;
userdat.gitbranch = opt.gitbranch;
userdat.gitusername = opt.gitusername;


pthscopa = getpathscopa();
pthuserdat = [pthscopa 'userdat.txt'];

if strcmpi(permission, 'read')
    
    if ~isempty(userdat.scopauserid) || ~isempty(userdat.gittoken) || ~isempty(userdat.gitbranch) || ~isempty(userdat.gitusername)
        error("for first argument 'read', cannot pass in any following name-value arguments")
    end
    userdat = structld(pthuserdat);

elseif strcmpi(permission, 'write')

    if isempty(userdat.scopauserid) || isempty(userdat.gittoken) || isempty(userdat.gitbranch) || isempty(userdat.gitusername)
        error("for first argument 'write', must pass in the following name-value arguments: scopauser, gittoken, gitbranch, and gitusername")
    end

    tmp = dbstack;
    if isscalar(tmp) && strcmp(tmp.file, 'scopauser.m')
        % glb(1, scopauserid = userdat.scopauserid);
        % glb(1, gittoken = userdat.gittoken);
        % glb(1, gitbranch = userdat.gitbranch);
        % glb(1, gitusername = userdat.gitusername);
        if isfile(pthuserdat)
            error(sprintf(pthuserdat + " already exists, delete it and run scopauser again"))
        else
            structsv(userdat, pthuserdat, readonly=1);
        end
    else
        error("for security, you must run scopauser with first argument 'write' from command line")
    end

else

    error("first argument (permission) must be 'read' or 'write'")

end