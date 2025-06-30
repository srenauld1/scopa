function [sout, nmout] = structfile(pth, opt)

%{
write variable to and/or read variable from txt file (pth), depending on input 
    s=[], nm=[], not in file: sout=[]
    s=[], nm=nonempty, in file: sout=matching variable in file
    s=[], nm=nonempty, not in file: sout=[] 
    s=nonempty, nm=[], in file: sout=s given name of found match in file
    s=nonempty, nm=[], not in file: sout=s given name of default pattern, and write s to file
    s=nonempty, nm=nonempty, in file: sout=s unchanged, with warning if flagmatch 0, error if flagmatch 1
    s=nonempty, nm=nonempty, not in file: sout=UNCHANGED s, write s to file with name nm (error if flagpattern 1 and if nm does not follow default pattern but file variables do)
default nm pattern, for autonm, is ['^' autonm_prefix '[1-9]+[0-9]*$'] (autonm_prefix followed by 1 or more consecutive integers, not starting with 0)
if file was created using autonm_prefix, user must always use same autonm_prefix for that file
nm empty means you are using default naming (nm is automatically derived, ie autonm is true)
if file was created using default variable names, autonm is true, and user must always use default names for that file
if using autonm, usegit must be true (since digits are not valid variable names)
%}

arguments
    pth %path to file containing variables;
    opt.s = [] %variable to write to file, or get from file
    opt.nm = [] %empty chooses name for variable automatically, otherwise nm is the name of the variable
    opt.usegit = 1 %use git to sync scopa across filesystems (to prevent conflicting changes to same file)
    opt.dupe = 0 %allow duplicate s with different names
    opt.getonly = 0; %get variable or name from file only, not allowed to write or create new
end
s = opt.s;
nm = opt.nm;
usegit = opt.usegit;
dupe = opt.dupe;
getonly = opt.getonly;

wcpat = '*';

%%%%% CHECK AND SET SOME INPUTS %%%%%

% if isstruct(s) && isempty(fieldnames(s))
%     s = []; %make sure user didn't try to make s empty by passing s=struct, which will not be considered empty for isempty(s)
% end

if startsWith(pth, ['~' filesep])
    error("input pth starts with tilde, use the full path to home directory rather than tilde" + newline)
end
if isempty(s) && isempty(nm)
    error("s and nm cannot both be empty")
end
% if getonly && ~isempty(nm)
%     error("if getonly is true, nm must be empty")
% end
if ~isempty(s) && ~isstruct(s)
    error("s must be struct if it is nonempty (for now)")
end
if isstruct(s) && ~isscalar(s) && ~isvector(s)
    error("s must be scalar or one-dimensional nonscalar struct for now")
end
if ~endsWith(pth, '.txt')
    error('pth must be .txt file (for now)')
end

autonm_write = 0;
if isempty(nm)
    autonm = 1;
    autonm_write = 1;
    autonm_prefix = 'a'; %default auto-name prefix
else
    autonm = 0;
    autonm_prefix = '';
    nm = convertStringsToChars(nm);  %just in case . . . if already char, this doesn't do anything
    if ~isletter(nm(1))
        error("you passed in nm that does not begin with a letter; must begin with letter because it is saved as structy fieldname")
    end
end

if ~isempty(autonm_prefix) && ~isletter(autonm_prefix)
    error("autonm_prefix must be letter (since it can become first character of struct fieldname")
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

    %%%%% SET UP VARIABLE NAME %%%%%

    sfile = structld(pth, nocells=1); %load from file
    if isfield(sfile, 'maketime')
        maketime = sfile.maketime;
        sfile = rmfield(sfile, 'maketime');
    else
        error("file must have maketime recording when it was first created (to reliably map to other files with ids contained in this file); you may have an old file")
    end
    if isfield(sfile, 'autonm_prefix')
        prefix_field = sfile.autonm_prefix;
        sfile = rmfield(sfile, 'autonm_prefix');
    end
    if autonm
        if isfield(sfile, 'autonm') && sfile.autonm==1
            sfile = rmfield(sfile, 'autonm');
            if isempty(s)
                error("s and nm cannot both be empty")
            else
                fprintf("searching for s in file without reference it its name in file because s is nonempty and nm is empty" + newline)
            end
        else
            error("nm is automatically derived because it is empty, but existing file did not have nm automatically derived (does not contain field autonm)")
        end
        nm_infile = fieldnames(sfile);
        nmpat = ['^' autonm_prefix '[1-9]+[0-9]*$']; %previously was '^[a-z]{1}[1-9]+[0-9]*$' single lowercase letter followed by 1 or more consecutive integers, not starting with 0, but got rid of autonm_prefix being inseparable from default nm
        fnmatches = cellflat(regexp(nm_infile,nmpat,'match'));
        if numel(fnmatches)==numel(nm_infile) %if all vars in file follow default naming pattern (autonm_prefix with consecutive numbers)
            nmnumstr = cellflat(regexp(nm_infile,'\d+','match'));
            nmnums = cellfun(@str2double, nmnumstr);
            prefix_derived = [];
            for k = 1:numel(nm_infile)
                prefix_derived = [prefix_derived erase(nm_infile(k), nmnumstr(k))];
            end
            prefix_derived = unique(prefix_derived);
            if ~isscalar(prefix_derived)
                error("default pattern can only use one autonm_prefix")
            end
            prefix_derived = cell2mat(prefix_derived);
            if ~isequal(autonm_prefix, prefix_derived, prefix_field) %make sure input autonm_prefix matches sfile.autonm_prefix and prefixes in each variable name in file
                error("input autonm_prefix must match autonm_prefix in variable names in file, autonm_prefix in autonm_prefix field in file")
            end
            if numel(nmnums)~=numel(nm_infile) || ~isequal(nmnums, 1:numel(nmnums))
                error("default name is autonm_prefix followed by an integer; integers in names should increase sequentially from 1 to numel(variables); you may have used an invalid name")
            end
        else
            error("all vars in file must follow default naming pattern since autonm=1")
        end
    else
        if isempty(s)
            if isfield(sfile, 'autonm')
                autonm_write = 1;
                sfile = rmfield(sfile, 'autonm');
            else
                fprintf("s is empty and nm is nonempty, so retrieving a variable named nm from file pth" + newline)
            end
        else
            if isfield(sfile, 'autonm')
                error("s and nm are nonempty, so you are trying to write variable to file pth with name nm, but pth exists and previously used autonm, so you must use autonm here (pass nm=[] or just don't pass nm as argument)")
            else
                fprintf("s and nm are nonempty, so if variable is not in file, writing it to file pth with name nm" + newline)
            end
        end
        nm_infile = fieldnames(sfile);
    end



    %%%%% GET MATCHED VARIABLE FROM FILE, OR WRITE UNMATCHED VARIABLE TO FILE %%%%%

    dotranspose = 0;
    matchind = [];
    for k = 1:numel(nm_infile)
        if isempty(s)
            if autonm %if no variable or name was provided
                error("s and nm cannot both be empty")
            else
                if isequal(nm, nm_infile{k}) %if name matches when no variable was provided
                    matchind = [matchind k];
                end
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
            if autonm
                if smatched %if variable matches when no name was provided
                    matchind = [matchind k];
                end
            else
                if smatched
                    if strcmp(nm, nm_infile{k}) %if variable and name match
                        matchind = [matchind k];
                    else %if variable matches but name doesn't
                        if ~dupe %if duplicates are not allowed, error
                            error("s and nm are nonempty, so you are trying to write s to file with name nm, but s already exists in pth and has name " + nm_infile{k})
                        end
                    end
                end
            end
        end
    end

    if isempty(matchind) %after looping through all variables in file, if input variable doens't match any in file, append to variables in file
        if getonly
            fprintf("no matches to input s were found, but getonly is true, so will not create file or new name" + newline)
            nmout = [];
            sout = [];
            sfilenew = [];
        else
            if autonm
                nmout = [autonm_prefix num2str(max(nmnums)+1)];
            else
                nmout = nm;
                if isempty(s)
                    fprintf("no variable in pth matching nm " + nmout + newline)
                end
            end
            sout = s;
            sfilenew = s;
        end 
    else % if input variable does match a variable in file . . . 
        if part
            nmout = cell(numel(matchind), 1);
            sout = cell(numel(matchind), 1);
            for k = 1:numel(matchind)
                nmout{k} = nm_infile{matchind(k)};
                sout{k} = sfile.(nm_infile{matchind(k)}); %if input variable matches a variable in file, give variable the name it has in file
                if dotranspose %isequal(size(spart), flip(size(sout{k})))
                    sout{k} = transpose(sout{k});
                end
                sfilenew = [];
            end
        else
            if isscalar(matchind)
                nmout = nm_infile{matchind};
                sout = sfile.(nm_infile{matchind}); %if input variable matches a variable in file, give variable the name it has in file
                if dotranspose %isequal(size(s), flip(size(sout)))
                    sout = transpose(sout);
                end
                sfilenew = [];
            else
                error("found multiple matches in file and part (allow partial matches) is false")
            end
        end
    end

else      %%%%% WRITE STRUCT TO NEW FILE SINCE FILE DOES NOT EXIST %%%%%

    fprintf("the following file will be created because it does not exist: " + pth + newline)

    sfile = struct;
    maketime = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));

    if getonly
        fprintf("pth des not exist, but getonly is true, so will not create file or output new name" + newline)
        nmout = [];
        sout = [];
        sfilenew = [];
    else
        if autonm
            nmout = [autonm_prefix '1'];
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
            glb(['maketime_' vbin], maketime); % previously tried to set globals as struct, but currently won't allow updating fields within maketime struct in glb (and maybe it shouldn't anyway), so only one field ends up being saved to globals; this is what i tried --> maketime_glb.(vbin) = maketime; glb(maketime=maketime_glb)
        end
    end
end


%%%%% WRITE TO FILE %%%%%

if isempty(sfilenew)
    fprintf("sfilenew is empty, not writing anything to file pth" + newline)
else
    if getonly
        error("should not be here if getonly is true")
    end
    if usegit
        sfile.autonm_prefix = autonm_prefix;
    end
    if autonm_write
        sfile.autonm = 1;
    end
    sfile.maketime = maketime;
    sfile.(nmout) = sfilenew;
    structsv(sfile, pth, overwrite=1, readonly=1); %write variables to file, possibly updated with (possibly renamed) s
end

if usegit
    try
        scopagit('push', files=pth) %previously files={'^opt_.*_.txt$'}
    catch
        scopagit('discard', files=pth) %previously files={'^opt_.*_.txt$'}
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

