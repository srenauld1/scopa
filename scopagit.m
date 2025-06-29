function scopagit(operation, opt)

%basic git control for scopa ff

arguments
    operation
    opt.files = [];
end
files = opt.files;

if ~iscell(files)
    files = {files};
end

userdat = scopauser('read');

pthscopa = getpathscopa();
cd(pthscopa)
rp = gitrepo;

if ~strcmp(rp.CurrentBranch.Name, userdat.gitbranch)
    switchBranch(rp, userdat.gitbranch)
end

newfiles = [];
modfiles = [];
if ~isempty(rp.UntrackedFiles)
    newfiles = gitfilematch(rp.UntrackedFiles, files);
end
if ~isempty(rp.ModifiedFiles)
    modfiles = gitfilematch(rp.ModifiedFiles, files);
end

if strcmpi(operation, 'pull')
    fprintf("pulling from remote branch" + newline)
    pull(rp, username=userdat.gitusername, token=userdat.gittoken)
elseif strcmpi(operation, 'push') || strcmpi(operation, 'sync')
    if strcmpi(operation, 'sync')
        fprintf("pulling from remote branch" + newline)
        pull(rp, username=userdat.gitusername, token=userdat.gittoken)
    end
    if isempty(modfiles) && isempty(newfiles)
        fprintf("no local changes to commit/push" + newline)
    else
        if ~isempty(newfiles)
            fprintf("adding new files" + newline)
            add(rp, newfiles)
        end
        if ~isempty(modfiles)
            fprintf("committing local changes" + newline)
            commit(rp, Message='scopagitcall', Files=modfiles)
            fprintf("pushing to remote branch" + newline)
            push(rp, username=userdat.gitusername, token=userdat.gittoken)
        end
    end
elseif strcmpi(operation, 'discard')
    if isempty(modfiles) && isempty(newfiles)
        fprintf("no local changes to discard" + newline)
    else
        if ~isempty(newfiles)
            fprintf("removing new files" + newline)
            rm(rp, newfiles)
        end
        if ~isempty(modfiles)
            fprintf("discarding local changes" + newline)
            discardChanges(rp, modfiles);
        end
    end
else
    error("operation must be push, pull, sync, or discard")
end

end


function gitfiles = gitfilematch(gitfiles, filepat)

[~, gitfiles, ext] = fileparts(gitfiles);
gitfiles = convertStringsToChars(strcat(gitfiles, ext));
if ~all(cellfun(@isempty, filepat))
    filecat = strcat(filepat, '|'); %doesn't matter if ends with pipe, treated as "or nothing"
    gitfiles = gitfiles(~cellfun(@isempty, regexp(gitfiles, [filecat{:}], 'match')));
end

end