function [sout, nmout] = structfile(pth, opt)

%{

write variable to and/or read variable from txt file (pth), depending on input: 
    s=[], nm=nonempty, nm in file: sout=variable in file named nm, nmout=nm, nothing written to file pth
    s=[], nm=nonempty, nm not in file: sout=[], nmout=[], nothing written to file pth
    s=nonempty, nm=[], s in file: sout=s, nmout=name of match in file, nothing written to file pth
    s=nonempty, nm=[], s not in file: sout=s, nmout=default pattern name, s written with name nmout to file pth
    s=nonempty, nm=nonempty, s in file with name nm: sout=s, nmout=nm, nothing written to file pth
    s=nonempty, nm=nonempty, s not in file with name nm: sout=s, nmout=nm, s written with name nmout to file pth

when pth is first created, metadata is written to struct 'md' with the following fields:
    autonm: 1 if default name was assigned when writing input to file; this only occurs if input nm is empty 
    nmprefix: the letter used as the first character in default naming pattern; must be the same for all variables written to file (except in 'withoutgit' mode) 
    maketime: time file was created

if s=nonempty and nm=[] and s is not in file, s is written to file with default name
    pattern for default name is ['^' nmprefix '[1-9]+[0-9]*$']
    that is, nmprefix followed by 1 or more consecutive integers, starting with 1 (not 0)
    if default name is used when pth is created, it must always be used 
    nmprefix must be the same for all variables written to file

%}

arguments
    pth %path to file containing variables;
    opt.s = [] %variable to write to file, or get from file
    opt.nm = [] %empty chooses name for variable automatically, otherwise nm is the name of the variable
    opt.usegit = 1 %use git to sync scopa across filesystems (to prevent conflicting changes to same file)
    opt.dupe = 0 %allow duplicate s with different names
    opt.getonly = 0; %get variable or name from file only, not allowed to write or create new
    opt.update = 0; %update the variable if nm matches but s does not
end
s = opt.s;
nm = opt.nm;
usegit = opt.usegit;
dupe = opt.dupe;
getonly = opt.getonly;
update = opt.update;

%%%%% CHECK AND SET SOME INPUTS %%%%%

wcpat = '*';
nmprefix_withgit = 'a';
nmprefix_withoutgit = 'z';

if isstruct(s) && isempty(fieldnames(s))
    s = []; %make sure user didn't try to make s empty by passing s=struct, which will not be considered empty for isempty(s)
end
if isempty(s) || getonly
    usegit = 0; %don't bother with automatic git sync if s is empty, since you will not be writing anything to file (just reading); if you do need to pull from remote in this circumstance, just do it manually
end

if startsWith(pth, ['~' filesep])
    error("input pth starts with tilde, use the full path to home directory rather than tilde" + newline)
end
if isempty(s) && isempty(nm)
    error("s and nm cannot both be empty")
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


if usegit
    scopagit('pull') %make sure matches remote
end

[~, flnm, ~] = fileparts(pth);

if isfile(pth)

    %%%%% SET VARIABLE NAME %%%%%

    sfile = structld(pth, nocells=1); %load from file

    autonm_infile = sfile.md.autonm;
    if usegit
        nmprefix_infile = sfile.md.nmprefix_withgit;
    else
        nmprefix_infile = sfile.md.nmprefix_withoutgit;
    end
    maketime_infile = sfile.md.maketime;
    sfile = rmfield(sfile, 'md');

    nm_infile = fieldnames(sfile);

    if autonm_infile==1
        autonm = 1;
        nmnumstr = cellflat(regexp(nm_infile,'\d+','match'));
        nmnums = cellfun(@str2double, nmnumstr);
        prefix_derived = erase(nm_infile, nmnumstr);
        if usegit
            kp = cellfun(@(x) isequal(x, nmprefix_withgit), prefix_derived);
        else
            kp = cellfun(@(x) isequal(x, nmprefix_withoutgit), prefix_derived);
        end
        prefix_derived = prefix_derived(kp);
        nmnums = nmnums(kp);
        nm_infile = nm_infile(kp);
        prefix_derived = cell2mat(unique(prefix_derived));
        if ~isempty(prefix_derived) && ~isscalar(prefix_derived)
            error("default pattern can only use one nmprefix")
        end
        if (~isempty(prefix_derived) && ~isequal(nmprefix, prefix_derived, nmprefix_infile) ) || (isempty(prefix_derived) && ~isequal(nmprefix, nmprefix_infile) ) %make sure input nmprefix matches sfile.md.nmprefix and prefixes in each variable name in file
            error("nmprefix must match prefix found in variable names in file, and the nmprefix field saved to file")
        end
        if ~isempty(nm_infile) && (numel(nmnums)~=numel(nm_infile) || ~isequal(nmnums, 1:numel(nmnums)))
            error("default name is nmprefix followed by an integer; integers in names should increase sequentially from 1 to numel(variables); you may have used an invalid name")
        end
        nmpat = ['^' nmprefix '[1-9]+[0-9]*$']; %previously was '^[a-z]{1}[1-9]+[0-9]*$' single lowercase letter followed by 1 or more consecutive integers, not starting with 0, but got rid of nmprefix being inseparable from default nm
        fnmatches = cellflat(regexp(nm_infile, nmpat, 'match'));
        if numel(fnmatches)~=numel(nm_infile) %if all vars in file follow default naming pattern (nmprefix with consecutive numbers)
            error("all vars in file must follow default naming pattern since autonm=1")
        end
    end


    %%%%% GET MATCHED VARIABLE FROM FILE, OR WRITE UNMATCHED VARIABLE TO FILE %%%%%

    dotranspose = 0;
    matchind = zeros(1, numel(nm_infile), 'logical');
    for k = 1:numel(nm_infile)
        if isempty(s)
            if isequal(nm, nm_infile{k}) %if name matches when no variable was provided
                matchind(k) = 1;
            end
        else
            smatched = 0;
            if part
                [spart, sfilepart] = partmake(s, sfile.(nm_infile{k}), wcpat);
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

            if smatched %if variable matches . . .
                if isempty(nm) || strcmp(nm, nm_infile{k}) %and nm is empty (whether autonm is true or not) or nm matches nm in file
                    matchind(k) = 1;
                else %if variable matches but name doesn't
                    if ~dupe %if duplicates are not allowed, error
                        error("s and nm are nonempty, so you are trying to write s with name '" + nm + "' to file " + pth + newline + "but s already exists in that file with name " + nm_infile{k} + newline + "set dupe=1 if you want to allow same s with different nm")
                    end
                end
            else
                if strcmp(nm, nm_infile{k}) %if variable doesn't match but name does
                    if ~update %error if update is false
                        error("s and nm are nonempty, and variable with name '" + nm + "' already exists in file " + pth + newline + "but it does not match your input s, and argument update=0; make update=1 to change the value of variable " + nm)
                    end
                end
            end
        end
    end
    matchind = find(matchind);

    if isempty(matchind) %after looping through all variables in file, if input variable doens't match any in file, append to variables in file
        if getonly
            fprintf("no matches to input s were found, but getonly is true, so will not create file or new name" + newline + newline)
            nmout = [];
            sout = [];
            sfilenew = [];
        else
            if autonm
                if isempty(nmnums) %if nmnums is empty it means the file exists, but only has without git prefix, until now,
                    nmout = [nmprefix '1'];
                else
                    nmout = [nmprefix num2str(max(nmnums)+1)];
                end
                sout = s;
                sfilenew = s;
            else
                if isempty(s)
                    fprintf("no variable with name '" + nm + "' in file " + pth + newline + newline)
                    nmout = []; %you must have passed in nm if autonm is false and s is empty, and if nm does not match any variables in file, and s is empty, nmout is empty
                    sout = [];
                    sfilenew = [];
                else
                    if isempty(nm)
                        fprintf("nm is empty, autonm=0, and no variable matching s found in file " + pth + newline + newline)
                        nmout = []; %if nm is empty and s is nonempty but doesn't match anything, and autonm false, nothing output or written
                        sout = [];
                        sfilenew = [];
                    else
                        nmout = nm; %if nm does not match any variables in file, and s is nonempty, nmout=nm because nm will be written to file
                        sout = s;
                        sfilenew = s;
                    end
                end
            end
        end
    else % if input variable does match a variable in file . . .
        nmout = cell(numel(matchind), 1);
        sout = cell(numel(matchind), 1);
        for k = 1:numel(matchind)
            nmout{k} = nm_infile{matchind(k)};
            sout{k} = sfile.(nm_infile{matchind(k)}); %if input variable matches a variable in file, give variable the name it has in file
            if dotranspose %isequal(size(spart), flip(size(sout{k})))
                sout{k} = transpose(sout{k});
            end
        end
        sfilenew = [];
        if isscalar(matchind)
            nmout = cell2mat(nmout);
            sout = cell2mat(sout);
        else
            if ~dupe && ~part
                error("found multiple matches in file, but dupe is false, and there are no wildcard fields in input s" + newline + "name-value argument dupe=1 allows duplicate variables" + newline + "wildcard fields in input s allow duplicate variables because only partial matches are required")
            end
        end
    end

else      %%%%% WRITE STRUCT TO NEW FILE SINCE FILE DOES NOT EXIST %%%%%

    fprintf("the following file does not exist: " + pth + newline + newline)

    sfile = struct;
    maketime_infile = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));

    if getonly
        fprintf("pth des not exist, but getonly is true, so will not create file or output new name" + newline + newline)
        nmout = [];
        sout = [];
        sfilenew = [];
    else
        if autonm
            nmout = [nmprefix '1'];
        else
            nmout = nm;
        end
        sout = s;
        sfilenew = s;
    end

end


%%%%% SET GLOBALS %%%%%

flnmsplit = strsplit(flnm, '_');
if numel(flnmsplit)>1
    if ismember(flnmsplit{2}, {'roi', 'mdl', 'bmp', 'sld', 'fmf', 'daq', 'rg', 'var'}) %glb('ided_vbin') and rg and var
        vbin = flnmsplit{2};
        if isempty(glb(['maketime_' vbin]))
            glb(['maketime_' vbin], maketime_infile); % previously tried to set globals as struct, but currently won't allow updating fields within maketime_infile struct in glb (and maybe it shouldn't anyway), so only one field ends up being saved to globals; this is what i tried --> maketime_glb.(vbin) = maketime_infile; glb(maketime_infile=maketime_glb)
        end
    end
end


%%%%% WRITE TO FILE (IF ANYTHING NEW) %%%%%

if isempty(sfilenew)

    fprintf("not writing anything to file " + pth + newline + newline)

else

    fprintf("writing input variable to file " + pth + newline + newline)

    if getonly
        error("should not be here if getonly is true")
    end

    sfile.md.nmprefix_withgit = nmprefix_withgit; %written prefix remains prefix with git
    sfile.md.nmprefix_withoutgit = nmprefix_withoutgit; %written prefix remains prefix with git
    sfile.md.autonm = autonm;
    sfile.md.maketime = maketime_infile;

    sfile.(nmout) = sfilenew;

    structsv(sfile, pth, overwrite=1, readonly=1); %write variables to file, possibly updated with (possibly renamed) s

    if usegit
        try
            scopagit('push', files=pth)
        catch
            scopagit('discard', files=pth)
        end
    end

end

end


function [s, sfile] = partmake(s, sfile, wcpat)

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

