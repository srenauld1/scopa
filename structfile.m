function [sout, nmout, souts] = structfile(pth, opt)

%{

depending on input, write struct to and/or read struct from txt file (pth): 

    s=[], nm=nonempty:
        nm in file:
                        sout=struct in file named nm, nmout=nm, nothing written to file pth
        nm not in file: 
                        sout=[], nmout=[], nothing written to file pth

    s=nonempty, nm=[]: 
        s in file: 
            autonm=0
                        sout=s, nmout=name of match in file, nothing written to file pth
            autonm=1
                dupe=0: 
                        sout=s, nmout=name of match in file, nothing written to file pth
                dupe=1: 
                        sout=s and matches, nmout=default pattern name and nm matches, s written with name nmout to file pth (this is the only case where matches and input are combined into output and written to file
        s not in file: 
            autonm=0
                        sout=[], nmout=[], nothing written to file pth
            autonm=1
                        sout=s, nmout=default pattern name, s written with name nmout to file pth
    
    s=nonempty, nm=nonempty:
        s in file:
            nm matches name of matching struct in file: 
                        sout=s, nmout=nm, nothing written to file pth
            nm does not match name of matching struct in file: 
                dupe=0: 
                        sout=[], nmout=[], nothing written to file pth
                dupe=1: 
                        sout=s, nmout=nm, s written to file pth
        s not in file:
            nm matches name of struct in file: 
                update=0:
                    sout=[], nmout=[], nothing written to file pth
                update=1: 
                    sout=s, nmout=nm, struct with name nm is updated to match s and changes are written to file pth
            nm does not match any struct names in file:
                autonm=0:
                    sout=[], nmout=[], s written with name nmout to file pth
                autonm=1:
                    error: cannot input nonempty nm that doesn't match any name in file if autonm is true


output souts is struct version of output sout, where sout is in substruct(s) with name(s) nmout
    we use substructs rather than nonscalar struct in case sout have different fields

if one match is found, output sout is a struct, and nmout is a char vector 
if multiple matches are found, output sout and nmout are each a (n,1) cell, where n is number of matches

when pth is first created, metadata is written to struct 'md' with the following fields:
    autonm: 1 if default name was assigned when writing input to file; this only occurs if input nm is empty; 0 otherwise 
    maketime: time file was created
    nmprefix_withgit: the letter used as the first character in default naming pattern when usegit=1; must be the same for all variables written to file when usegit=1; default is 'a'
    nmprefix_withoutgit: the letter used as the first character in default naming pattern when usegit=0; must be the same for all variables written to file when usegit=0; default is 'z'

if s=nonempty and nm=[] and s is not in file, s is written to file with default name
    default name pattern is ['^' nmprefix_withgit '[1-9]+[0-9]*$'] or ['^' nmprefix_withoutgit '[1-9]+[0-9]*$']
    that is, nmprefix_withgit or nmprefix_withoutgit, followed by 1 or more consecutive integers, starting with 1 (not 0)
    if default name is used when pth is created, it must always be used 

for clarity, all arguments except file path (pth) are name-value arguments 

note: struct sorting does not affect test of equality
note: empty structs are not preserved by structfile; that is, struct([]) becomes [] after read/write with jsonencode/jsondecode 

TODO: add name-value argument 'renm' for renaming structs in file (modeled after renm argument in daqld)

%}

arguments
    pth % path to file containing structs
    opt.s = [] % struct to write to file, or get from file
    opt.nm = [] % name of struct to write to file, or get from file; empty chooses name for writing struct automatically (or finds name if s already exists in file); if nonempty, nm is the name of the struct to be written to file or retrieved from file
    opt.dupe = 1 % 1 to write struct s to file even though it already exists in file with different name (whether name is automatically or manually set); 0 to not allow duplicate structs in file with different names
    opt.update = 0 % 1 to change struct in file named nm to match struct s (ie when nm matches but s does not)
    opt.getonly = 0 % read from file only, skip writing
    opt.usegit {mustBeMember(opt.usegit,[0,1])} = [] % use git to sync file pth across filesystems (to prevent conflicting changes); default here in arguments block is empty because we use optorglb below
    opt.dosort = 0 % 1 to sort struct alphabetically when writing to file (natural sort); note sorting does not affect equality here when looking for structs in file matching input struct s
    opt.cellout = 0 %1 will force sout and nmout into cells, even when scalar (unless they are empty); 0 will only put them in cells when nonscalar
end
s = opt.s;
nm = opt.nm;
dupe = opt.dupe;
update = opt.update;
getonly = opt.getonly;
usegit = opt.usegit;
dosort = opt.dosort;
cellout = opt.cellout;

%%%%% CHECK AND SET SOME INPUTS %%%%%

usegit = optorglb(usegit, 0);
if ~ismember(usegit, [0,1])
    error("usegit must be 0 or 1")
end

wcpat = '*'; % wildcard character; when searching for structs in file matching s, fields with value wcpat are skipped
nmprefix_withgit = 'a'; % prefix used when assigning default name to struct if usegit=1
nmprefix_withoutgit = 'z'; % prefix used when assigning default name to struct if usegit=0

if isstruct(s) && isempty(fieldnames(s))
    s = []; %make sure user didn't try to make s empty by passing s=struct, which will not be considered empty for isempty(s)
end
if isempty(s)
    fprintf("NOTE: setting usegit to false because s is empty (meaning nothing will be written to file), so syncing filesystems with git is not necessary" + newline)
    usegit = 0; %don't bother with automatic git sync if s is empty, since you will not be writing anything to file (just reading); if you do need to pull from remote in this circumstance, just do it manually
end
if dupe && update
    fprintf("NOTE: you have set 'dupe' and 'update' to true, but their use cases never overlap, so only one will have effect, depending on your other inputs" + newline)
end
if getonly && dupe
    fprintf("NOTE: you have set 'getonly' and 'dupe' to true, but their use cases never overlap, so only one will have effect, depending on your other inputs" + newline)
end
if getonly && update
    fprintf("NOTE: you have set 'dupe' and 'update' to true, but their use cases never overlap, so only one will have effect, depending on your other inputs" + newline)
end
if startsWith(pth, '~')
    error("input pth starts with tilde, use the full path to home directory rather than tilde" + newline)
end
if ~isempty(s) && ~isstruct(s)
    error("s must be struct if it is nonempty (for now)")
end
if isstruct(s) && ~isscalar(s) && ~isvector(s)
    error("s must be scalar or one-dimensional nonscalar struct for now")
end
if ~endsWith(pth, '.txt')
    error('pth must be .txt file (for now)')
end


if usegit
    nmprefix = nmprefix_withgit; %default auto-name prefix if using git
else
    nmprefix = nmprefix_withoutgit; %default auto-name prefix if not using git
end
nmprefix = convertStringsToChars(nmprefix); %just in case

autonm = 0; %only true if nm is empty and pth does not exist yet, or if pth exists and previously used autonm
if isempty(nm)
    if ~isfile(pth)
        autonm = 1;
    end
else
    nm = convertStringsToChars(nm);  %just in case . . . if already char, this doesn't do anything
    if ~isletter(nm(1))
        error("first character of nm must be letter (to be valid fieldname)");
    end
    if strcmp(nm, 'md')
        error("cannot name input struct 'md' because that name is reserved for file metedata")
    end
end


if ~isempty(nmprefix) && ~isletter(nmprefix(1))
    error("nmprefix must be letter (since it can become first character of struct fieldname")
end
if ~isequal(nmprefix, nmprefix_withgit) && ~isequal(nmprefix, nmprefix_withoutgit) && ~isempty(nmprefix)
    error("autonm prefix must be either " + nmprefix_withgit + " or " + nmprefix_withgit + " or empty")
end

part = 0; %don't allow partial matches
if ~isempty(s)
    sflat = structflat(s, Prefix='s');  %use Prefix in case struct s is nonscalar, it won't affect anything here
    if any(structfun(@(x) any(strcmp(x, wcpat)),sflat))
        part = 1; %do allow partial matches
    end
end

if usegit && ~isfile(pth)
    try
        scopagit('pull') %you have to pull if the file doesn't exist, in case it exists elsewhere
    catch
        error("attempt to git sync with remote repository failed")
    end
end

doaddon = 0;
if isfile(pth)

    [autonm_infile, nmprefix_withgit_infile, nmprefix_withoutgit_infile, maketime_infile, sfile, nm_infile, nmnums, autonm] = structfile_read(pth, s, nm, usegit, nmprefix_withgit, nmprefix_withoutgit, nmprefix, dosort);

    %%%%% GET MATCHED STRUCT FROM FILE, OR WRITE UNMATCHED VARIABLE TO FILE %%%%%

    dotranspose = 0;
    matchind = zeros(1, numel(nm_infile), 'logical');
    for k = 1:numel(nm_infile)
        if isempty(s)
            if isempty(nm) || isequal(nm, nm_infile{k}) %if name matches when no struct was provided
                matchind(k) = 1;
            end
        else
            smatched = 0;
            if part
                [spart, sfilepart] = structfile_partmake(s, sfile.(nm_infile{k}), wcpat);
                if isequal(spart, sfilepart) || ~isscalar(spart) && isequal(transpose(spart), sfilepart)
                    smatched = 1;
                    if ~isscalar(spart) && isequal(transpose(spart), sfilepart)
                        dotranspose = 1;
                    end
                end
            else
                if isequal(s, sfile.(nm_infile{k})) || ~isscalar(s) && isequal(transpose(s), sfile.(nm_infile{k}))
                    smatched = 1;
                    if ~isscalar(s) && isequal(transpose(s), sfile.(nm_infile{k}))
                        dotranspose = 1;
                    end
                end
            end

            if smatched %if struct matches . . .
                if isempty(nm) % and nm is empty (whether autonm is true or not) . . .
                    if dupe && autonm && ~getonly  %and duplicates can be written, and autonm is true
                        doaddon = 1;
                    end
                    matchind(k) = 1; %return the s in file that matches input s, and return its name
                else
                    if strcmp(nm, nm_infile{k}) % and nm matches nm in file
                        matchind(k) = 1; %return the s in file that matches input s, and return its name
                    else % and name doesn't match any nm in file
                        if ~dupe %if duplicates are not allowed, error, otherwise proceed
                            error("s and nm are nonempty, so you are trying to write (or, less likely, read) s with name '" + nm + "' to (or from) file " + pth + newline + "but s already exists in that file with name " + nm_infile{k} + newline + "set dupe=1 if you want to write same s with different nm")
                        end
                    end
                end
            else
                if strcmp(nm, nm_infile{k}) %if struct doesn't match but name does
                    if ~update %error if update is false
                        error("s and nm are nonempty, and struct with name '" + nm + "' already exists in file " + pth + newline + "but it does not match your input s, and argument update=0; make update=1 to change the value of struct " + nm)
                    end
                end
            end
        end
    end
    matchind = find(matchind);

    if isempty(matchind) || doaddon %after looping through all variables in file, if input struct doens't match any in file, append to variables in file
        if getonly
            fprintf("no matches to input s were found, but getonly is true, so will not create file or new name" + newline + newline)
            nmout2 = [];
            sout2 = [];
            sfilenew2 = [];
        else
            if autonm
                if usegit %run scopagit and structfile_read again if input s needs to be added (to be sure it's given the correct name, etc)
                    scopagit('pull')
                    [autonm_infile2, nmprefix_withgit_infile2, nmprefix_withoutgit_infile2, maketime_infile2, sfile, nm_infile, nmnums] = structfile_read(pth, s, nm, usegit, nmprefix_withgit, nmprefix_withoutgit, nmprefix, dosort);
                    if ~isequal(autonm_infile, autonm_infile2) || ~isequal(nmprefix_withgit_infile, nmprefix_withgit_infile2) || ~isequal(nmprefix_withoutgit_infile, nmprefix_withoutgit_infile2) || ~isequal(maketime_infile, maketime_infile2) 
                        error("at least one metadata field changed after pulling remote version of file " + pth )
                    end
                end
                if isempty(nmnums) %if nmnums is empty it means the file exists, but only has with or without git prefix, until now, where reverse is true
                    nmout2 = [nmprefix '1'];
                else
                    nmout2 = [nmprefix num2str(max(nmnums)+1)];
                end
                sout2 = s;
                sfilenew2 = s;
            else
                if isempty(s)
                    fprintf("no struct with name '" + nm + "' in file " + pth + newline + newline)
                    nmout2 = []; %you must have passed in nm if autonm is false and s is empty, and if nm does not match any variables in file, and s is empty, nmout is empty
                    sout2 = [];
                    sfilenew2 = [];
                else
                    if isempty(nm)
                        fprintf("nm is empty, autonm=0, and no struct matching s found in file " + pth + newline + newline)
                        nmout2 = []; %if nm is empty and s is nonempty but doesn't match anything, and autonm false, nothing output or written
                        sout2 = [];
                        sfilenew2 = [];
                    else
                        nmout2 = nm; %if nm does not match any variables in file, and s is nonempty, nmout=nm because nm will be written to file
                        sout2 = s;
                        sfilenew2 = s;
                    end
                end
            end
        end
    end

    if isempty(matchind) % if input struct does not match a struct in file . . . (separate from if isempty(matchind) above because of || doaddon
        nmout = {nmout2};
        sout = {sout2};
        sfilenew = sfilenew2;
    else %if input struct does match a struct in file . . . (separate from if isempty(matchind) above because of || doaddon
        nmout = cell(numel(matchind), 1);
        sout = cell(numel(matchind), 1);
        for k = 1:numel(matchind)
            nmout{k} = nm_infile{matchind(k)};
            sout{k} = sfile.(nm_infile{matchind(k)}); %if input struct matches a struct in file, give struct the name it has in file
            if dotranspose %isequal(size(spart), flip(size(sout{k})))
                sout{k} = transpose(sout{k});
            end
        end
        if doaddon %append new to end of matches
            nmout = cat(1, nmout, {nmout2});
            sout = cat(1, sout, {sout2});
            sfilenew = sfilenew2;
        else
            sfilenew = [];
        end
    end


else      %%%%% WRITE STRUCT TO NEW FILE SINCE FILE DOES NOT EXIST %%%%%

    fprintf("the following file does not exist: " + pth + newline + newline)

    sfile = struct;
    autonm_infile = autonm;
    if autonm
        nmprefix_withgit_infile = nmprefix_withgit;
        nmprefix_withoutgit_infile = nmprefix_withoutgit;
    else
        nmprefix_withgit_infile = '';
        nmprefix_withoutgit_infile = '';
    end
    maketime_infile = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));

    if getonly
        fprintf("pth des not exist, but getonly is true, so will not create file or output new name" + newline + newline)
        nmout = [];
        sout = [];
        sfilenew = [];
    else
        if autonm
            if isempty(s) %we only arrive here if user passed in empty s and empty nm and pth that doesn't exist
                nmout = [];
            else
                nmout = {[nmprefix '1']};
            end
        else
            nmout = {nm};
        end
        sout = {s};
        sfilenew = s;
    end

end


%%%%% SET MAKETIME %%%%%

[~, flnm, ~] = fileparts(pth);
flnmsplit = strsplit(flnm, '_');
if numel(flnmsplit)>1
    if ismember(flnmsplit{2}, {'roi', 'mdl', 'bmp', 'sld', 'fmf', 'daq', 'rg', 'var'}) 
        mos = flnmsplit{2};
        if isempty(glb(['maketime_' mos]))
            glb(['maketime_' mos], maketime_infile); % previously tried to set globals as struct, but currently won't allow updating fields within maketime_infile struct in glb (and maybe it shouldn't anyway), so only one field ends up being saved to globals; this is what i tried --> maketime_glb.(mos) = maketime_infile; glb(maketime_infile=maketime_glb)
        end
    end
end


%%%%% WRITE TO FILE (IF ANYTHING NEW) %%%%%

if isempty(sfilenew)

    fprintf("not writing anything to file " + pth + newline + newline)

else

    if getonly
        error("should not be here if getonly is true")
    end
    
    fprintf("writing input struct to file " + pth + newline + newline)

    if doaddon
        sfile.(nmout2) = sfilenew;
    else
        sfile.(cell2mat(nmout)) = sfilenew;
    end
    
    sfile.md.nmprefix_withgit = nmprefix_withgit_infile;
    sfile.md.nmprefix_withoutgit = nmprefix_withoutgit_infile;
    sfile.md.autonm = autonm_infile;
    sfile.md.maketime = maketime_infile;

    structsv(sfile, pth, overwrite=1, readonly=1, dosort=dosort); %write variables to file, possibly updated with (possibly renamed) s

    if usegit
        try
            scopagit('push', files=pth)
        catch
            scopagit('discard', files=pth)
            error("attempt to git sync with remote repository failed")
        end
    end

end


souts = [];
for k = 1:numel(nmout)
    souts.(nmout{k}) = sout{k};
end

if isscalar(nmout) && ~cellout
    nmout = cell2mat(nmout);
    sout = cell2mat(sout);
end

end


function [autonm_infile, nmprefix_withgit_infile, nmprefix_withoutgit_infile, maketime_infile, sfile, nm_infile, nmnums, autonm] = structfile_read(pth, s, nm, usegit, nmprefix_withgit, nmprefix_withoutgit, nmprefix, dosort)

%%%%% SET struct NAME %%%%%

sfile = structld(pth, nocells=1, dosort=dosort); %load from file

autonm_infile = sfile.md.autonm;
nmprefix_withgit_infile = sfile.md.nmprefix_withgit;
nmprefix_withoutgit_infile = sfile.md.nmprefix_withoutgit;
maketime_infile = sfile.md.maketime;
sfile = rmfield(sfile, 'md');

nm_infile = fieldnames(sfile);

if isempty(nm) && isempty(s)
    fprintf("s and nm are empty, so returning everything in file " + pth + newline + newline)
end

autonm = 0;
nmnums = [];
if autonm_infile==1
    if isempty(nm) && ~isempty(s)
        autonm = 1;
        nmnumstr = cellflat(regexp(nm_infile,'\d+','match'));
        nmnums = cellfun(@str2double, nmnumstr);
        prefix_derived = nm_infile;
        for k = 1:numel(nmnumstr)
            prefix_derived{k} = erase(nm_infile{k}, nmnumstr{k}); %doesn't work like this (without loop) --> erase(nm_infile, nmnumstr)
        end
        if usegit
            rm = cellfun(@(x) isequal(x, nmprefix_withoutgit), prefix_derived);
            nmprefix_infile_current = nmprefix_withgit_infile;
        else
            rm = cellfun(@(x) isequal(x, nmprefix_withgit), prefix_derived);
            nmprefix_infile_current = nmprefix_withoutgit_infile;
        end
        prefix_derived(rm) = [];
        nmnums(rm) = [];
        nm_infile(rm) = [];
        prefix_derived = unique(prefix_derived);
        if isscalar(prefix_derived) || isempty(prefix_derived)
            prefix_derived = cell2mat(prefix_derived);
        else
            error("default pattern can only use two nmprefix (one when usegit=1 and one when usegit=0")
        end
        if (~isempty(prefix_derived) && ~isequal(nmprefix, prefix_derived, nmprefix_infile_current) ) || (isempty(prefix_derived) && ~isequal(nmprefix, nmprefix_infile_current) ) %make sure input nmprefix matches sfile.md.nmprefix and prefixes in each struct name in file
            error("nmprefix must match prefix found in struct names in file, and the nmprefix field saved to file")
        end
        if ~isempty(nm_infile) && (numel(nmnums)~=numel(nm_infile) || ~isequal(nmnums, 1:numel(nmnums)))
            error("default name is nmprefix followed by an integer; integers in names should increase sequentially from 1 to numel(variables); you may have used an invalid name")
        end
        nmpat = ['^' nmprefix '[1-9]+[0-9]*$']; %previously was '^[a-z]{1}[1-9]+[0-9]*$' single lowercase letter followed by 1 or more consecutive integers, not starting with 0, but got rid of nmprefix being inseparable from default nm
        fnmatches = cellflat(regexp(nm_infile, nmpat, 'match'));
        if numel(fnmatches)~=numel(nm_infile) %if all vars in file follow default naming pattern (nmprefix with consecutive numbers)
            error("all vars in file must follow default naming pattern since autonm=1")
        end
    else
        if ~isempty(s)
            if ~any(strcmp(nm, nm_infile))
                error("you input nonempty s and nm, but autonm=1 in file and nm doens't match any struct names in file " + pth + newline + "so for this file you can only make s and nm nonempty for struct s that is already in file (to confirm it exists in file)" + newline + "or for struct s that is not in file but name nm that is in file (to update struct contents for name nm, in which case name-value argument 'update' must be true)" + newline + "if you wish to add struct s with a name that is not in file, you must must make nm empty, and if s is already in file, you must allow writing of duplicate structs with dupe=1")
            end
        end
    end
end


end


function [s, sfile] = structfile_partmake(s, sfile, wcpat)

sfile_save = sfile; %in case s is all wild and becomes all empty
s = structflat(s, Prefix='s'); %use Prefix in case nonscalar, it won't affect this function
sfile = structflat(sfile, Prefix='s');  %use Prefix in case nonscalar, it won't affect this function
fnf = fieldnames(s);
for k = 1:numel(fnf)
    if isequal(s.(fnf{k}), wcpat)
        s = rmfield(s, fnf{k});
        if isfield(sfile, fnf{k}) %sfile may not have wildcard field because it's been reduced; but if it does, remove it
            sfile = rmfield(sfile, fnf{k});
        end
    end
end

fnf = fieldnames(sfile);
for k = 1:numel(fnf)
    if isstruct(sfile.(fnf{k})) && isempty(fieldnames(sfile.(fnf{k}))) %remove empty structs, they only exist when switch for them is off
        sfile = rmfield(sfile, fnf{k});
    end
end

if isempty(fieldnames(s))
    s = sfile_save;
    sfile = sfile_save;
else
    s = structunflat(s);
    s = s.s; %get rid of the Prefix assigned above in call to structflat
    sfile = structunflat(sfile);
    sfile = sfile.s; %get rid of the Prefix assigned above in call to structflat
end

end

