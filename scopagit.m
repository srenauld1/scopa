function scopagit(operation)

%basic git control for scopa

arguments
    operation
end

userdat = scopauser('read');

pthscopa = getpathscopa();
cd(pthscopa)
rp = gitrepo;
if ~strcmp(rp.CurrentBranch.Name, userdat.gitbranch)
    switchBranch(rp, userdat.gitbranch)
    % error("you are on the wrong branch")
end
if strcmpi(operation, 'pull')
    fprintf("pulling from remote branch" + newline)
    pull(rp, username=userdat.gitusername, token=userdat.gittoken)
elseif strcmpi(operation, 'push') || strcmpi(operation, 'sync')
    if strcmpi(operation, 'sync')
        fprintf("pulling from remote branch" + newline)
        pull(rp, username=userdat.gitusername, token=userdat.gittoken)
    end
    if isempty(rp.ModifiedFiles) && isempty(rp.UntrackedFiles)
        fprintf("no local changes to commit/push" + newline)
    else
        if ~isempty(rp.UntrackedFiles)
            fprintf("adding new files" + newline)
            newfiles = rp.UntrackedFiles;
            add(rp, newfiles)
        end
        fprintf("committing local changes" + newline)
        commit(rp, Message='scopagitcall')
        fprintf("pushing to remote branch" + newline)
        push(rp, username=userdat.gitusername, token=userdat.gittoken)
    end
elseif strcmpi(operation, 'discard')
    if isempty(rp.ModifiedFiles) && isempty(rp.UntrackedFiles)
        fprintf("no local changes to discard" + newline)
    else
        if ~isempty(rp.UntrackedFiles)
            fprintf("removing new files" + newline)
            newfiles = rp.UntrackedFiles;
            rm(rp, newfiles)
        end
        if ~isempty(rp.ModifiedFiles)
            fprintf("discarding local changes" + newline)
            discardChanges(rp, rp.ModifiedFiles);
        end
    end
else
    error("operation must be push, pull, sync, or discard")
end

end
