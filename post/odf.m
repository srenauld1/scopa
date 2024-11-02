function o = odf(oin, vbin, copybin, opt)


%{

odf is just a wrapper for odfscal; odfscal operates on scalar struct argument oin; odf just loops over elements of oin

WARNING THIS FUNCTION WORKS AS INTENDED BUT THE CODE AT THE BOTTOM THAT UPDATES ALL DEFAULTS IS CONFUSING;
note the docs in oset are also about odf, and are much more extensive than the docs here
odf is intended to help the user easily set a potentially complex set of pipeline options (see function oset, where odf is called)

can call odf in different ways
    zero arguments sets o equal to d (all default options)
    one argument sets options for fields in oin, setting default for options not listed 
    two arguments sets options for d.vbin only, even if vbin don't appear in oin (if they don't they will be all default); vbin can be nested (vbin1.vbin2)
    three arguments creates struct(s) (names in copybin) within vbin
    name-value argument 'files': if files==1, will find files matching user supplied stack file specifiers (or default specifiers, if no user supplied specifiers); files mode must have 'spec' vbin in oin, or 'spec' as vbin second argument; if files==0, will not search for files; if files==2, will not search for files, but will keep found files in input struct and put them in the output struct

struct d holds all default options;
fields directly under d are mostly used within single functions called from a2p, except mn, which is used in a2p direcly
each section contains options for a major routine called in a2p (section header is options field name, with function name in parentheses, and brief description of function)
output struct o holds options used in a2p
output o matches default d unless input oin specifies a different value
in particular: if a field is in both oin.vbin and d.vbin, use the value in oin.vbin; if field is only in d.vbin, use the value in d.vbin; if field isn't in d.vbin, error

%}

arguments
    oin = [] %input options struct for overwriting defaults in default options struct d
    vbin = [] %cell of char (or char, if scalar); if nonempty, and copybin is nonempty, update vbin and place results in copybin, and update ~vbin without placing in copybin; if nonempty and copybin is empty, just update vbin; if empty and copybin is nonempty, update all and place all in copybin
    copybin = [] %subfields into which vbin is copied
    opt.files = 0 %whether to use spec to find stack files, or skip
    opt.pthopt = [] %path to default options file; if empty, uses default path
end
files = opt.files;
pthopt = opt.pthopt;

if isstring(oin) || isstring(vbin) || isstring(vbin)
    error('you may have attempted to pass "files" name-value argument, without some of the other non-name-value arguments, but misspelled "files" it or used the wrong term;')
end

pthscopa = getpathscopa();
if isempty(pthopt)
    pthopt = [pthscopa 'optdf.txt'];
end

if files %if files==1, oin must be scalar
    if numel(oin)>1
        error("if files==1, oin must be scalar")
    end
    o = odfscal(oin, vbin, copybin, files, pthscopa, pthopt); %odfs is for scalar struct o
else %otherwise, oin can be nonscalar
    if ( numel(oin)>1 && any(~cellfun(@isempty, getfieldns(oin,'id.pth'))) ) || ( isfield(oin, 'id') && isfield(oin.id, 'pth') )
        files=2;
    end
    if isempty(oin)
        o = odfscal(oin, vbin, copybin, files, pthscopa, pthopt); %odfs is for scalar struct o
    else
        for k = numel(oin):-1:1 %in case o is nonscalar, loop over each element, calling odfs; backwards to preallocate
            o(k) = odfscal(oin(k), vbin, copybin, files, pthscopa, pthopt); %odfs is for scalar struct o
        end
    end
end

end

function o = odfscal(oin, vbin, copybin, files, pthscopa, pthopt)


if files && ~isfield(oin, 'spec') && ~any(strcmp(vbin, 'spec'))
    error("if files is true, you must pass input struct with spec vbin, or pass vbin argument that includes 'spec'")
end

if files
    [~, flatfntmp, ~] = structflat(oin, 'prefix', 'o');
    if any(strcmp(flatfntmp, 'spec.pth')) && ~isempty(oin.spec.pth)
        if (any(strcmp(flatfntmp, 'spec.recdate')) && ~isempty(oin.spec.recdate)) || (any(strcmp(flatfntmp, 'spec.fly')) && ~isempty(oin.spec.fly)) || (any(strcmp(flatfntmp, 'spec.trial')) && ~isempty(oin.spec.trial)) || (any(strcmp(flatfntmp, 'spec.suffix')) && ~isempty(oin.spec.suffix))
            error("in file mode, cannot pass in spec.pth and any of spec.recdate, spec.fly, spec.trial, spec.suffix")
        end
    end
end


%% load defaults

if isfile(pthopt)
    d = structtxtld(pthopt, nocells=1);
else
    error(sprintf("cannot find default options file, '" + pthopt + "', run optdfsv.m to create the default options file"))
end

if ~files %if not in files mode, update default spec to be empty 
    d.spec.recdate = ''; 
    d.spec.fly = '';
    d.spec.trial = ''; 
    d.spec.suffix = '';
    d.spec.match = '';
end

%% fill in defaults for any options not specified in oin

if isfield(oin, 'id') %id is the one field that doesn't have defaults (it holds found files info)
    idhold = oin.id; %put it aside and put back below
    oin = rmfield(oin, 'id');
else
    idhold = [];
end

fnd = fieldnames(d);

if isempty(vbin)
    vbin = {};
end
if ~iscell(vbin)
    vbin = {vbin};
end
if isempty(copybin)
    copybin = {};
end
if ~iscell(copybin)
    copybin = {copybin};
end

if isempty(oin) || isempty(fieldnames(oin))
    if isempty(vbin)
        oin = d;
    else
        for k = 1:numel(vbin)
            if ~isfield(d, vbin{k})
                error(sprintf("d." + vbin{k}) + " does not exist")
            end
            oin.(vbin{k}) = d.(vbin{k});
        end
    end
end

if ~isfield(oin, 'copybinprev')
    oin.copybinprev = {};
end
copybinprev = oin.copybinprev;

if isempty(vbin)
    o = optupdate(oin, d, copybinprev, copybin);
else
    if any(contains(vbin, '.')) %if nested vbin, remove deepest vbin and operate on it, invoking defaults throughout the nested vbin, and and then merge with everything else in input, which remains untouched (algorithm is different than non-nested, hence the if/else, otherwise we could just use eval for nested and nonnested)
        [~, fbsortinds] = sort(cellfun(@numel, regexp(vbin, '[.]*')), 'descend'); %
        vbin = vbin(fbsortinds); %sort to make update order deepest nested vbin to shallowest, otherwise doens't work
        for k = 1:numel(fnd)
            repeatvbin = cellfun(@numel, strfind(vbin, fnd{k}))>1;
            if any(repeatvbin)
                error(sprintf("you have multiple copies of vbin " + fnd{k} + " and possibly others; in a nested vbin each vbin can only appear once, for now at least"))
            end
        end
        [~, fnflattmp] = structflat(oin, 'prefix', 'o'); %use prefix in case it's nonscalar
        fnflattmp = erase(fnflattmp, 'o_');
        notvbin = regexprep(erase(fnflattmp, strcat(fnd, '.')), '^[.]*', ''); %remove everything but the vbins
        if ~isempty(cell2mat(regexp(notvbin, '[.]{2,}'))) %at least 2 periods means a non-vbin is above a vbin
            error("you must have placed a non-vbin somewhere other than the end of a nesting; for example, o.vbin1.optionA.vbin2 is not allowed; options can themselves be nested, but options must come at the end of each flattened fieldname")
        end
        fnflat = unique(regexprep(erase(fnflattmp, notvbin), '[.]*$', '')); %just the vbins (options and copybins removed)
        copybinprev_and_newvbindeepest = [];
        for k = 1:numel(vbin)
            if startsWith(vbin{k}, 'o.')
                error("for nested vbin, omit the leading 'o.'")
            end
            vbintmp = strsplit(vbin{k}, '.');
            vbinshallowest = vbintmp{1};
            vbindeepest = vbintmp{end};
            if ~isempty(copybin) %if you're making copybin of a nested vbin . . .
                copybinprev_and_newvbindeepest = unique([copybinprev_and_newvbindeepest, copybinprev, vbindeepest]); %must ignore copybinprev and vbindeepest in optupdate on the full nested vbin branch (otherwise the vbin enclosing the new copybin, vbindeepest, will get populated with defaults, but this is only needed if copybin is nonempty
            end
            if ~isfield(d, vbinshallowest)
                error(sprintf("d." + vbinshallowest) + " does not exist; nested vbin must start with primary vbin directly under o")
            end
            if ismember(vbin{k}, fnflat) %if the nested vbin exists in oin, grab the deepest vbin
                eval(['oindeepest.' vbindeepest ' = oin.' vbin{k} ';']); %use eval to succinctly extract nested field
            else %if the nesting doesn't exist in oin, create it with defaults in the deepest layer, and nothing above
                if isfield(d, vbindeepest)
                    fprintf("note: " + vbindeepest + " does not exist in your input to odf, creating it and populating with all default values" + newline)
                else
                    error(sprintf("d." + vbindeepest) + " does not exist")
                end
                oindeepest.(vbindeepest) = d.(vbindeepest);
            end
            oindeepest = optupdate(oindeepest, d, copybinprev, copybin); %update deepest vbin
            eval(['oin.' vbin{k} ' = oindeepest.' vbindeepest ';']); %after updating, put deepest back into oin where it was before (ie according to vbin nesting), with possible copybin applied
            oinsub.(vbinshallowest) = oin.(vbinshallowest); %put that nested vbin aside and ...
            oin = rmfield(oin, vbinshallowest); %remove it from oin
            if k==numel(vbin)
                o = optupdate(oinsub, d, copybinprev_and_newvbindeepest, []); %then update the full nested vbin; don't use copybin on full nested vbin (only use it on oindeepest above); here you must ignore copybinprev_and_newvbindeepest, which contains both the enclosing vbin for the newly created copybin (vbindeepest), as well as old copybin (copybinprev); note you could break this if copybindeepest appears more than once in the nesting, then optupdate will ignore the shallower, so there's an above error to catch that
            end
        end
    else %if non-nested vbin, remove vbin and operate on it, and then merge with everything else in input, which remains untouched
        fn = fieldnames(oin);
        for k = 1:numel(vbin)
            if ismember(vbin{k}, fn)
                oinsub.(vbin{k}) = oin.(vbin{k});
                oin = rmfield(oin, vbin{k});
            else
                if isfield(d, vbin{k})
                    fprintf("note: " + vbin{k} + " does not exist in your input to odf, creating it and populating with all default values" + newline)
                    oinsub.(vbin{k}) = d.(vbin{k}); %use all defaults vbin{k} is not in oin
                else
                    error(sprintf("d." + vbin{k}) + " does not exist")
                end
            end
        end
        copybin_inert = copybin(ismember(copybin, copybinprev));
        if ~isempty(copybin_inert)
            fprintf(strjoin(copybin_inert, ', ') + " has/have already been set, nothing will change in this/these copybin" + newline)
        end
        o = optupdate(oinsub, d, copybinprev, copybin); %just update vbin
    end
    o = cell2struct([struct2cell(oin); struct2cell(o)],[fieldnames(oin); fieldnames(o)]); %combine with what was unchanged
end

o.copybinprev = unique([oin.copybinprev, copybin]); %must ignore copybinprev and vbindeepest in optupdate on the full nested vbin branch (otherwise the vbin enclosing the new copybin, vbindeepest, will get populated with defaults, but this is only needed if copybin is nonempty

o.id = idhold;
o = structord(o, vectype='row');


%% find files


if files
    if ~isempty(o.spec.pth) %if user passed no input to a2p, or a struct with file specifiers, or is running odf with files flag true but no oin or no spec field in oin
        o.spec.recdate = '';
        o.spec.fly = '';
        o.spec.trial = '';
        o.spec.suffix = '';
        o.spec.match = '';
    end
end

if files==1
    fprintf("RUNNING odf with files==1, SEARCHING FOR FILES" + newline)

    if isempty(o.spec.pth) %if fullpaths were not passed into a2p, use filename specifiers in spec to find files
        rectmp = stackfind(pthparent_local=o.spec.pthparent_local, pthparent_o2=o.spec.pthparent_o2, validsuffix=o.spec.validsuffix, recdate=o.spec.recdate, fly=o.spec.fly, trial=o.spec.trial, suffix=o.spec.suffix, match=o.spec.match); %find files matching spec
    else
        rectmp = stackfind(pth=o.spec.pth); %find files matching fullpath input to a2p (can contain wildcards following rules in rdir)
        if isempty(rectmp)
            fprintf("NONE OF THE FULL PATH INPUT (OR WILDCARD PATTERNS) TO a2p EXIST" + newline)
        end
    end
    if isempty(cell2mat(rectmp))
        error("NO STACKS FOUND")
    end
    idtmp = idmake(rectmp);
    numrec = numel(idtmp);

    o = rmfield(o, 'id'); %if id exists, remove it because you just made it (it's either empty or 'nofile' or is the same as idtmp)
    o = repelem(o, numrec);
    for h = 1:numrec
        o(h).id = idtmp(h);
    end

elseif files==0
    o.id = 'nofilemode';
    fprintf("RUNNING odf with files==0, NOT SEARCHING FOR FILES" + newline)
elseif files==2
    fprintf("RUNNING odf with files==2, NOT SEARCHING FOR FILES, BUT KEEPING EXISTING FILES IN o.id" + newline)
end



%% globals

if isempty(glb('pthscopa')) && isempty(glb('pthparent')) && isempty(glb('regionexdf')) && isempty(glb('timestr')) && isempty(glb('validsuffix')) && isempty(glb('pltvis'))
    pthparent = pthparentfind(oin.spec.pthparent_local, oin.spec.pthparent_o2);
    glb(pthscopa=pthscopa, pthparent=pthparent, regionexdf=d.roi.regionex, timestr=d.mn.timestr, validsuffix=d.spec.validsuffix, pltvis=d.mn.pltvis); %set some globals, force update if they already have been set with first argument 1
end

end








