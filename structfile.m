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
default pattern (nmpat) is '^[a-z]{1}[1-9]+[0-9]*$' (single lowercase letter followed by 1 or more consecutive integers, not starting with 0)
if file has loc and prefix fields, it can only be used in the filesystem matching loc (to prevent merge conflicts across filesystems)
if file was created using default variable names, autonm is true, and user must always use default names for that file
default naming 
filesystem protection 

prefix empty means you are using filesystem protection (prefix is automatically derived to match filesystem)
nm empty means you are using default naming (nm is automatically derived)

%}


arguments
    pth %path to file containing variables; can contain wildcard *; if prefix is not empty (including if prefix='*'), prefix must be in this position in nm of pth: '_prefix_.txt'; if prefix is empty or not passed as argument, wildcard * is treated like a normal wildcard;
    opt.s = [] %variable to write to file, or get from file
    opt.nm = [] %by default, names variables automatically
    opt.useprefix = 0 %by default, does not use prefix (ie does not use filesystem protection); if prefix is not empty
    opt.pthscopas = [] %by default, looks for pthscopas in glb('pthscopas')
end
s = opt.s;
nm = opt.nm;
useprefix = opt.useprefix;
pthscopas = opt.pthscopas;


%%%%% CHECK AND SET SOME INPUTS %%%%%

pthscopa = getpathscopa();
pthall = rdir(pth);

if ~isempty(s) && ~isstruct(s)
    error("s must be struct if it is nonempty (for now)")
end
if ~endsWith(pth, '.txt')
    error('pth must be .txt file (for now)')
end

autonm_write = 0;
if isempty(nm)
    autonm = 1;
    autonm_write = 1;
else
    autonm = 0;
end


%%%%% SET OR DERIVE PREFIX AND FILE PATH %%%%%

if useprefix

    if ~isscalar(regexp(pth, '_*_.txt'))
        error("pth does not contain filename suffix (for prefix) in correct position")
    end
    if ~isscalar(regexp(pth, '*'))
        error("if useprefix is true, pth must contain one and only one *")
    end
    if isempty(pthscopas)
        pthscopas = glb('pthscopas');
        if isempty(pthscopas)
            error("to use structfile with useprefix=1, you must have passed in name-value argument pthscopas, or set glb('pthscopas')")
        end
    end
    if isempty(pthall)
        pftmp = struct2cell(pthscopas);
        for k = 1:numel(pftmp)
            if ~isempty(pftmp{k}) && ~endsWith(pftmp{k}, filesep)
                pftmp{k} = [pftmp{k} filesep];
            end
        end
        fnpf = fieldnames(pthscopas);
        prefix = fnpf(strcmp(pthscopa,pftmp));
        if numel(prefix)~=1
            error("there must be only one match to prefix")
        end
        prefix = cell2mat(prefix);
        pth = strrep(pth, '*', prefix);
    else
        filesystem_matched = 0;
        for k = 1:numel(pthall) %if pth contains wildcard, it's because it's filesystem protected, so find the file for this filesystem
            sfile = structtxtld(pthall(k).name, nocells=1);
            if ~isfield(sfile, 'loc') || ~isfield(sfile, 'prefix')
                error("useprefix is true but pth is a file that previously did not use prefix")
            end
            if strcmp(sfile.loc, pthscopa)
                if filesystem_matched==1
                    error("there can only be one options file for each filesystem")
                end
                filesystem_matched = 1;
                prefix = sfile.prefix;
                pth = pthall(k).name;
            end
        end
        if filesystem_matched==0
            error("no file on current filesystem found; check glb('pthscopas'), which matches o.mn.pthscopas")
        end
    end

else

    prefix = ''; %empty char
    if autonm
        error("if nm isempty (using automatically generated names, ie autonm is true), useprefix must be true")
    end
    if isscalar(pthall)
        pth = pthall.name;
    elseif isempty(pthall)
        fprintf("pth does not exist, will create it" + newline)
    else
        error("pth has multiple matches")
    end

end


%%%%% INSPECT FILE %%%%%

[pthdir, flnm, ~] = fileparts(pth);
loc = [pthdir filesep];

if isfile(pth)

    sfile = structtxtld(pth, nocells=1); %load from file
    if isfield(sfile, 'loc')
        if ~useprefix
            error("useprefix must be true since pth exists and previously used prefix")
        end
        loc_field = sfile.loc;
        sfile = rmfield(sfile, 'loc');
        if ~strcmp(loc, loc_field)
            error("if loc is a field in file, it must match location of file")
        end
        if isfield(sfile, 'prefix')
            prefix_field = sfile.prefix;
            sfile = rmfield(sfile, 'prefix');
        else
            error("if loc is a field in file, prefix must also be a field in file (prefix is a shorthand for loc)")
        end
    end
    if autonm
        if isfield(sfile, 'autonm') && sfile.autonm==1
            sfile = rmfield(sfile, 'autonm');
            if isempty(s)
                error("s and nm cannot bot be empty")
            else
                fprintf("searching for s in file without reference it its name in file because s is nonempty and nm is empty" + newline)
            end
        else
            error("nm is automatically derived because it is empty, but existing file did not have nm automatically derived (does not contain field autonm)")
        end
        nmfile = fieldnames(sfile);
        nmpat = ['^' prefix '[1-9]+[0-9]*$']; %previously was '^[a-z]{1}[1-9]+[0-9]*$' single lowercase letter followed by 1 or more consecutive integers, not starting with 0, but got rid of prefix being inseparable from default nm
        fnmatches = cellflat(regexp(nmfile,nmpat,'match'));
        if numel(fnmatches)==numel(nmfile) %if all vars in file follow default naming pattern (prefix with consecutive numbers)
            nmnumstr = cellflat(regexp(nmfile,'\d+','match'));
            nmnums = cellfun(@str2double, nmnumstr);
            prefix_derived = unique(erase(nmfile, nmnumstr));
            if ~isscalar(prefix_derived)
                error("default pattern can only use one prefix")
            end
            prefix_derived = cell2mat(prefix_derived);
            prefix_in_filename = strsplit(flnm, '_');
            prefix_in_filename = prefix_in_filename{end-1};
            if ~isequal(prefix, prefix_derived, prefix_field, prefix_in_filename) %make sure input prefix matches sfile.prefix and prefixes in each variable name in file
                error("input prefix must match prefix in variable names in file, prefix in prefix field in file, and prefix in filename")
            end
            if numel(nmnums)~=numel(nmfile) || ~isequal(nmnums, 1:numel(nmnums))
                error("default name is prefix followed by an integer; integers in names should increase sequentially from 1 to numel(variables); you may have used an invalid name")
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
                fprintf("s and nm are nonempty, so writing variable to file pth with name nm" + newline)
            end
        end
        nmfile = fieldnames(sfile);
    end

else

    sfile = struct;
    nmfile = fieldnames(sfile);

end


%%%%% GET MATCHED VARIABLE FROM FILE, OR WRITE UNMATCHED VARIABLE TO FILE %%%%%

sout = [];
if ~isfile(pth)
    if autonm
        nmout = [prefix '1'];
    else
        nmout = [prefix nm];
    end
    sout = s;
    sfile.(nmout) = s;
else
    matchind = [];
    for k = 1:numel(nmfile)
        if isempty(s)
            if autonm %if no variable or name was provided
                error("s and nm cannot both be empty")
            else
                if isequal([prefix nm], nmfile{k}) %if name matches when no variable was provided
                    matchind = [matchind k];
                end
            end
        else
            if autonm
                if isequal(s, sfile.(nmfile{k})) %if variable matches when no name was provided
                    matchind = [matchind k];
                end
            else
                if isequal(s, sfile.(nmfile{k})) && ~strcmp([prefix nm], nmfile{k}) %if variable matches but name doesn't
                    error("s and nm are nonempty, so you are trying to write s to file with name nm, but s already exists in pth and has name " + nmout)
                end
            end
        end
    end

    if isempty(matchind) %after looping through all vars in file, if current variable doesn't match any vars in file, append to variables in file
        if autonm
            nmout = [prefix num2str(max(nmnums)+1)];
        else
            nmout = [prefix nm];
            if isempty(s)
                fprintf("no variable in pth matching nm " + [prefix nm] + newline)
                return
            else
                nmout = [prefix nm];
            end
        end
        sout = s;
        sfile.(nmout) = s;
    elseif isscalar(matchind)
        nmout = nmfile{matchind};
        sout = sfile.(nmfile{matchind}); %if variable matches a variable in file, give variable the name it has in file
    else
        error("found multiple matches in file")
    end

end

%%%%% WRITE TO FILE %%%%%

if isempty(sout)
    fprintf("sout is empty, not writing anything to file pth" + newline)
else
    if useprefix
        sfile.loc = loc;
        sfile.prefix = prefix;
    end
    if autonm_write
        sfile.autonm = 1;
    end
    structtxtsv(sfile, pth, overwrite=1, readonly=1); %write variables to file, possibly updated with (possibly renamed) s
end

