function o = odf(oin, vbin, copybin, opt)


%{

odf is just a wrapper for odfscal; odfscal operates on scalar struct argument oin; odf just loops over elements of oin

WARNING THIS FUNCTION WORKS AS INTENDED BUT THE CODE AT THE BOTTOM THAT UPDATES ALL DEFAULTS IS UGLY AND CONFUSING;
note the docs in oset are also about odf, and are much more extensive than the docs here
odf is intended to help the user easily set a potentially complex set of pipeline options (see function oset, where odf is called)

can call odf in different ways
    zero arguments sets o equal to d (all default options)
    one argument sets options for fields in oin, setting default for options not listed 
    two arguments sets options for d.vbin only, even if vbin don't appear in oin (if they don't they will be all default); vbin can be nested (vbin1.vbin2)
    three arguments creates struct(s) (names in copybin) within vbin
    name-value argument 'files': if files==1, will find files matching user supplied stack file specifiers (or default specifiers, if no user supplied specifiers); files mode must have 'spec' vbin in oin, or 'spec' as vbin second argument; if files==0, will not search for files, but will keep found files in input struct and put them in the output struct

struct d holds all default options;
fields directly under d are mostly used within single functions called from a2p, except mn, which is used in a2p direcly
each section contains options for a major routine called in a2p (section header is options field name, with function name in parentheses, and brief description of function)
output struct o holds options used in a2p
output o matches default d unless input oin specifies a different value
in particular: if a field is in both oin.vbin and d.vbin, use the value in oin.vbin; if field is only in d.vbin, use the value in d.vbin; if field isn't in d.vbin, error

%}

arguments
    oin = [] %input options struct for overwriting defaults in default options struct d; can be omitted to just invoke defaults for all vbin listed in vbin (or all possible vbin is vbin is empty)
    vbin = '' %char, or cell of char; empty char '' is the same as all vbin (do not use []); if nonempty, and copybin is nonempty, update vbin and place results in copybin, and update ~vbin without placing in copybin; if nonempty and copybin is empty, just update vbin; if empty and copybin is nonempty, update all and place all in copybin
    copybin = '' %char, or cell of char, or empty to skip; subfields into which vbin is copied
    opt.files = 0 %whether to use spec to find stack files, or skip
    opt.fill = 0; %whether to fill all default nestings
    opt.unpack = 0; %if output is a single vbin in nestvalid, do not nest in enclosing struct (losing the name of the vbin in the output)
    opt.wild = 0; %all defaults become wildcard; if empty, all defaults remain unchanged; if nonempty, all defaults become '*' 
    opt.pthopt = [] %path to default options file; if empty, uses default path
end
files = opt.files;
fill = opt.fill;
unpack = opt.unpack;
wild = opt.wild;
pthopt = opt.pthopt;

metafields = {'copybin', 'id', 'filled', 'nestvalid'};

if ischar(oin) || isstring(oin) || iscellstr(oin) || ( iscell(oin) && isstring(oin{1}) )  % check if oin was omitted, if so, first argument was vbin; update arguments accordingly
    vbin = oin;
    oin = [];
end
if ~( ischar(vbin) || isstring(vbin) || iscellstr(vbin) || ( iscell(vbin) && isstring(vbin{1}) ) )
    error("vbin must be char or string or cell of char or string; if you want it to be empty, use empty char '' ")
end


%%%% load defaults %%%%

pthscopa = getpathscopa();
if isempty(pthopt)
    pthopt = [pthscopa 'optdf.txt'];
end

if ~isfile(pthopt)
    optdfsv();
end

if isfile(pthopt)
    d = structtxtld(pthopt, nocells=1);
    if wild
        wcpat = '*';
        d = structflat(d);
        fnd = fieldnames(d);
        for k = 1:numel(fnd)
            if ~ismember(fnd{k}, metafields)
                d.(fnd{k}) = wcpat;
            end
        end
        d = structunflat(d);
    end
else
    error(sprintf("cannot find default options file, '" + pthopt + "', run optdfsv.m to create the default options file"))
end

%%%% update options %%%%

if files %if files==1, oin must be scalar
    if numel(oin)>1
        error("if files is true, oin must be scalar")
    end
    if fill==1
        error("files cannot be true when fill is true" + newline)
    end
    if wild
        error("files cannot be true when wild is true" + newline)
    end
    o = odfscal(d, oin, vbin, copybin, files, fill, pthscopa, metafields); %odfs is for scalar struct o
else %otherwise, oin can be nonscalar
    if isempty(oin)
        o = odfscal(d, oin, vbin, copybin, files, fill, pthscopa, metafields); %odfs is for scalar struct o
    else
        for k = numel(oin):-1:1 %in case o is nonscalar, loop over each element, calling odfs; backwards to preallocate
            o(k) = odfscal(d, oin(k), vbin, copybin, files, fill, pthscopa, metafields); %odfs is for scalar struct o
        end
    end
end

if unpack
    if ~isscalar(o)
        error("cannot unpack nonscalar struct")
    end
    if sum(isfield(o, d.nestvalid))>1
        error("cannot unpack struct with multiple vbins")
    else
        o = o.(cell2mat(fieldnames(o)));
    end
end


end



function o = odfscal(d, oin, vbin, copybin, files, fill, pthscopa, metafields)


if isfield(oin, 'filled') && oin.filled==1
    error("you cannot edit options struct after it has already been filled (filled=1)")
end

if fill && isfield(oin, 'filled') && oin.filled==1
    error("you cannot fill options struct (argument fill cannot equal 1) because it has already been filled (filled=1)")
end
% 
% if fill && ~isempty(vbin)
%     error("you cannot pass vbin into odf along with fill=1 (it is redundant, since fill will operate on all possible vbin)")
% end

if fill && ~isempty(copybin)
    error("this should work as long as vbin is empty, but for some reason it doesn't create copybin everywhere")
end

if files
    if ~isfield(oin, 'spec') && ~any(strcmp(vbin, 'spec'))
        error("if files is true, you must pass input struct with spec vbin, or pass vbin argument that includes 'spec'")
    end
    [~, flatfntmp, ~] = structflat(oin, 'prefix', 'o');
    if any(strcmp(flatfntmp, 'spec.pth')) && ~isempty(oin.spec.pth)
        if (any(strcmp(flatfntmp, 'spec.recdate')) && ~isempty(oin.spec.recdate)) || (any(strcmp(flatfntmp, 'spec.fly')) && ~isempty(oin.spec.fly)) || (any(strcmp(flatfntmp, 'spec.trial')) && ~isempty(oin.spec.trial)) || (any(strcmp(flatfntmp, 'spec.suffix')) && ~isempty(oin.spec.suffix)) || (any(strcmp(flatfntmp, 'spec.substr')) && ~isempty(oin.spec.substr))
            error("in file mode, cannot pass in spec.pth and any of spec.recdate, spec.fly, spec.trial, spec.suffix, spec.substr")
        end
    end
end



%% prep inputs


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
            if ~isfield(d, vbin{k}) && ~ismember(vbin{k}, d.nestvalid)
                error(sprintf("d." + vbin{k}) + " does not exist, and " + vbin{k} + " does not exist in d.nestvalid")
            end
            if ismember(vbin{k}, d.nestvalid) %if oin is empty but there's a nested vbin (a valid one, ie, listed in d.nestvalid) 
                vbintmp = strsplit(vbin{k}, '.');
                eval(['oin.' vbin{k} '= d.(vbintmp{end});']) %fill defaults for the deepest sub-vbin, and the whole nested branch will get filled
            else
                oin.(vbin{k}) = d.(vbin{k});
            end
        end
    end
end

if isfield(oin, 'copybin')
    copybinprev = oin.copybin;
else
    copybinprev = {};
end

structhold = struct;
for k = 1:numel(metafields)
    if isfield(oin, metafields{k}) %id is the one field that doesn't have defaults (it holds found files info)
        structhold.(metafields{k}) = oin.(metafields{k}); %put it aside and put back below
        oin = rmfield(oin, metafields{k});
    end
end


%% assign defaults for any options not specified in oin


if isempty(vbin)

    o = optupdate(oin, d, copybinprev, copybin);

else

    if any(contains(vbin, '.')) %if nested vbin, remove deepest vbin and operate on it, invoking defaults throughout the nested vbin, and and then merge with everything else in input, which remains untouched (algorithm is different than non-nested, hence the if/else, otherwise we could just use eval for nested and nonnested)
        [~, fbsortinds] = sort(cellfun(@numel, regexp(vbin, '[.]*')), 'descend'); %
        vbin = vbin(fbsortinds); %sort to make update order deepest nested vbin to shallowest, otherwise doens't work
        for kk = 1:numel(vbin)
            for k = 1:numel(fnd)
                if sum(cellfun(@numel, regexp(strsplit(vbin{kk}, '.'), ['^' fnd{k} '$'])))>1
                    error(sprintf("you have multiple copies of vbin " + fnd{k} + " and possibly others; in a nested vbin each vbin can only appear once, for now at least"))
                end
            end
        end
        [~, fnflattmp] = structflat(oin, 'prefix', 'o'); %use prefix in case it's nonscalar
        fnflattmp = erase(fnflattmp, ['o' '__']);

        changed = 1;
        notvbin = fnflattmp;
        while changed
            notvbintmp = notvbin;
            notvbin = regexprep(notvbin, strcat('^', fnd, '\.'), ''); %remove contiguous sequence of vbins at the beginning (will not remove vbins preceded by a copybin)
            changed = ~isequal(notvbin, notvbintmp);
        end

        % TODO: PREVIOUSLY THERE WAS A CHECK HERE FOR VBIN APPEARING AFTER NON-VBIN (LIKE O.ROI.PB.CM) . . . THIS MAY BE A PROBLEM, DEAL WITH IT SOMETIME

        fnflat = cell(numel(notvbin), 1);
        for k = 1:numel(notvbin) %use this in loop because we are removing novbins for each fnflattmp (don't want removal across indices)
            fnflat{k} = regexprep(fnflattmp{k}, strcat('\.', notvbin{k}, '$'), ''); %keep only the vbins
        end
        fnflat = unique(fnflat);

        ignorefields_for_full_nested_vbin = []; %TODO: THIS SHOULD PROBABLY NOT ACCUMULATE, MAY NOT WANT TO IGNORE THE SAME FIELDS IN DIFFERENT NESTING BRANCHES
        for k = 1:numel(vbin)
            if startsWith(vbin{k}, 'o.')
                error("for nested vbin, omit the leading 'o.'")
            end
            vbintmp = strsplit(vbin{k}, '.');
            vbinshallowest = vbintmp{1};
            vbindeepest = vbintmp{end};
            if sum(cellfun(@numel, regexp(strsplit(vbin{k}, '.'), ['^' vbindeepest '$'])))>1
                error("currently vbindeepest can only appear once in a nested vbin, see note on 224 below")
            end
            if isempty(copybin) %if you're not making copybin of a nested vbin . . .
                ignorefields_for_full_nested_vbin = unique([ignorefields_for_full_nested_vbin, copybinprev, copybin]); %just ignore coprbinprev
            else %if you're making copybin of a nested vbin . . .
                ignorefields_for_full_nested_vbin = unique([ignorefields_for_full_nested_vbin, copybinprev, vbindeepest]); %must ignore copybinprev and vbindeepest in optupdate on the full nested vbin branch (otherwise the vbin enclosing the new copybin, vbindeepest, will get populated with defaults, but this is only needed if copybin is nonempty
            end
            if ~isfield(d, vbinshallowest)
                error(sprintf("d." + vbinshallowest) + " does not exist; nested vbin must start with primary vbin directly under o")
            end
            if ismember(vbin{k}, fnflat) %if the nested vbin exists in oin, grab the deepest vbin
                eval(['oindeepest.' vbindeepest ' = oin.' vbin{k} ';']); %use eval to succinctly extract nested field
            else %if the nesting doesn't exist in oin, create it with defaults in the deepest layer, and nothing above
                if isfield(d, vbindeepest)
                    % fprintf("you input vbin '" + vbin{k} + "', but '" + vbindeepest + "' does not exist in your input to odf, so creating it and populating with default values" + newline)
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
                o = optupdate(oinsub, d, ignorefields_for_full_nested_vbin, []); %then update the full nested vbin; don't use copybin on full nested vbin (only use it on oindeepest above); here you must ignore copybinprev_and_newvbindeepest, which contains both the enclosing vbin for the newly created copybin (vbindeepest, which will include any copybin applied to vbindeepest, and thus don't need to be listed in copybinprev_and_newvbindeepest), as well as old copybin (copybinprev); note you could break this if copybindeepest appears more than once in the nesting, then optupdate will ignore the shallower, so there's an above error to catch that
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
                    % fprintf("note: " + vbin{k} + " does not exist in your input to odf, creating it and populating with all default values" + newline)
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

for k = 1:numel(metafields)
    if isfield(structhold, metafields{k})
        o.(metafields{k}) = structhold.(metafields{k});
    end
end

copybin = unique([copybinprev, copybin]); %must ignore copybinprev and vbindeepest in optupdate on the full nested vbin branch (otherwise the vbin enclosing the new copybin, vbindeepest, will get populated with defaults, but this is only needed if copybin is nonempty
if ~isempty(copybin)
    o.copybin = copybin;
end

o = structsort(o, vectype='row');




%% find files


if files

    if ~isempty(o.spec.pth) %if user passed no input to a2p, or a struct with file specifiers, or is running odf with files flag true but no oin or no spec field in oin
        o.spec.recdate = '';
        o.spec.fly = '';
        o.spec.trial = '';
        o.spec.suffix = '';
        o.spec.substr = '';
        o.spec.match = '';
    end

    % fprintf("RUNNING odf with files true, SEARCHING FOR FILES" + newline)

    if isempty(o.spec.pth) %if fullpaths were not passed into a2p, use filename specifiers in spec to find files
        rectmp = stackfind(pthparent_local=o.spec.pthparent_local, pthparent_o2=o.spec.pthparent_o2, suffixvalid=o.spec.suffixvalid, recdate=o.spec.recdate, fly=o.spec.fly, trial=o.spec.trial, suffix=o.spec.suffix, substr=o.spec.substr, match=o.spec.match); %find files matching spec
    else
        rectmp = stackfind(pth=o.spec.pth, suffixvalid=o.spec.suffixvalid); %find files matching fullpath input to a2p (can contain wildcards following rules in rdir)
        if isempty(rectmp)
            fprintf("NONE OF THE FULL PATH INPUT (OR WILDCARD PATTERNS) TO a2p EXIST" + newline)
        end
    end
    if isempty(cell2mat(rectmp))
        error("NO STACKS FOUND")
    end
    idtmp = idmake(rectmp);
    numrec = numel(idtmp);

    if isfield(o, 'id') && ~isempty(o.id)
        fprintf("WARNING, REPLACING FIELD id" + newline)
    end
    o = repelem(o, numrec);
    for h = 1:numrec
        o(h).id = idtmp(h);
    end

else
    
    % fprintf("RUNNING odf with files false, NOT SEARCHING FOR FILES, WILL KEEP ANY EXISTING FILES" + newline)

end



%% fill (fill all nestings, and set globals, this is forced to be the last step in creating options struct)

if fill

    if isempty(vbin)
        if ~isfield(o, 'id')
            o.id = d.id;
        end
        if ~isfield(o, 'copybin')
            o.copybin = d.copybin;
        end
        if ~isfield(o, 'nestvalid')
            o.nestvalid = d.nestvalid;
        end
    end

    dnestflat = unique(cellflat(cellfun(@(x,y) strsplit(x,y), d.nestvalid, repelem({'.'}, numel(d.nestvalid)), 'un', false)));
    if any(ismember(copybinprev, dnestflat))
        error('copybin names cannot match any vbin names')
    end

    % if ~isfield(o, 'roi') || ~isstruct(o.roi) || isfield(o.roi, 'regionex')
    %     o = odf(o, 'roi', d.roi.regionex);
    %     copybinprev{1} = d.roi.regionex;
    % end

    oflat = structflat(o);
    fnoflat = fieldnames(oflat);
    fnoflat_before_copybin_all = [];
    for m = 1:numel(copybinprev)
        expr_cb = ['__' copybinprev{m} '__']; %double underscore is default for flattened options struct, keeping them seperate to make it clear, and maybe turn them into global variable
        mtch_cb = fnoflat(~cellfun(@isempty, regexp(fnoflat, expr_cb, 'match')));
        if ~isempty(mtch_cb)
            if any(cellfun(@numel, regexp(mtch_cb, ['__' copybinprev{m} '__']))>1)
                error("there is a repeated copybin, this is currently not supported")
            end
            fnoflat_before_copybin = unique(extractBefore(mtch_cb, ['__' copybinprev{m}]));
            fnoflat_before_copybin_all = unique([fnoflat_before_copybin_all fnoflat_before_copybin]);
            for k = 1:numel(d.nestvalid)
                for w = 1:numel(fnoflat_before_copybin)
                    if startsWith(d.nestvalid{k}, fnoflat_before_copybin{w})
                        dnest_after_copybin = erase(strrep(d.nestvalid{k}, '.', '__'), fnoflat_before_copybin{w}); %double underscore is default for flattened options struct, keeping them seperate to make it clear, and maybe turn them into global variable
                        if ~isempty(dnest_after_copybin)
                            expr = strcat('^', fnoflat_before_copybin{w}, '__', copybinprev{m}, dnest_after_copybin);
                            mtch = mtch_cb(~cellfun(@isempty, regexp(mtch_cb, expr, 'match')));
                            if isempty(mtch)
                                newnest = strrep(strrep(expr, '__', '.'), '^', ''); %replace double underscore with period, and remove leading carot
                                o = odf(o, newnest, files=0);
                            end
                        end
                    end
                end
            end
        end
    end


    for k = 1:numel(d.nestvalid) %doesn't matter if these get updated in loop but fnoflat doesn't (right?)
        if ~strcmp(d.nestvalid{k}, 'filled') %filled is the one field that cannot be done here
            if isempty(fnoflat_before_copybin_all) || all(cellfun(@isempty, regexp(d.nestvalid{k}, strcat('^', strrep(fnoflat_before_copybin_all, '__', '.'))))) %if d.nestvalid{k} is not any vbin with copybin from above
                expr = ['^' strrep(d.nestvalid{k}, '.', '__')];
                mtch = fnoflat(~cellfun(@isempty, regexp(fnoflat, expr, 'match')));
                if isempty(mtch)
                    o = odf(o, d.nestvalid{k}, files=0);
                end
            end
        end
    end


    % now set some globals, as the final step in creating options struct (we know it's final because filled=1 now)

    %%%% these globals should not be edited by the user in general, so they take values from d (output from optdfsv) %%%%
    if isempty(glb('pthscopa')) && isempty(glb('regionexdf')) && isempty(glb('timestr')) && isempty(glb('suffixvalid')) && isempty(glb('dmstackdf')) && isempty(glb('xyscreen'))
        xyscreen = pxscreenget;
        glb(pthscopa=pthscopa, regionexdf=d.roi.regionex, timestr=d.mn.timestr, suffixvalid=d.spec.suffixvalid, dmstackdf=d.mn.dmstackdf, xyscreen=xyscreen);
    end

    %%%% these globals (from vbin 'mn') may depend on user input, so they take values from o (which might match values from d) %%%%     
    if isempty(glb('pltvis')) && isempty(glb('plt')) && isempty(glb('pthpy')) && isempty(glb('pthscopas')) && isempty(glb('user'))
        if ( isfield(o, 'mn') && isempty(vbin) ) || ( ~isempty(vbin) && any(~cellfun(@isempty, regexp(vbin, '(^mn$|\.mn$|^mn(\.){1}\w+$)'))) )
            glb(pltvis=o.mn.pltvis, plt=o.mn.plt, pthpy=o.mn.pthpy, pthscopas=o.mn.pthscopas, user=o.mn.user)
        end
    end
    
    %%%% this global may or may not be automatically derived (from vbin 'spec'), depending on where this is being run %%%% 
    if isempty(glb('pthparent'))
        if ( isfield(o, 'spec') && isempty(vbin) ) || ( ~isempty(vbin) && any(~cellfun(@isempty, regexp(vbin, '(^spec$|\.spec$|^spec(\.){1}\w+$)'))) )
            pthparent = pthparentfind(o.spec.pthparent_local, o.spec.pthparent_o2);
            glb(pthparent=pthparent)
        end
    end


    % now check for any problems 

    if isempty(o.mn.user)
        error('o.mn.user cannot be empty')
    end
    if isempty(regexp(o.mn.user, '^[a-zA-Z]+$'))
        error('o.mn.user can only contain alphabetic characters')
    end

    fn = fieldnames(o.mn.pthscopas);
    cnt = 0;
    for k = 1:numel(fn)
        if isempty(o.mn.pthscopas.(fn{k}))
            cnt = cnt+1;
        else
            if ~endsWith(o.mn.pthscopas.(fn{k}), filesep)
                error("all pthscopas must end with filesep; add filesep")
            end
        end
    end
    if cnt==numel(fn)
        error("at least one pthscopas must be nonempty")
    end


    % mark as filled, unless you're only filling input vbin 

    o.filled = 1;

    fn = fieldnames(o);
    for k = 1:numel(fn)
        if ~strcmp(fn{k}, d.nestvalid)
            error("you cannot fill the entire options struct with a vbin that is not listed in nest valid (you may have created a vbin that can only appear within another vbin, outside that enclosing vbin)")
        end
        if ~strcmp(fn{k}, vbin)
            o.filled = 0;
            o = rmfield(o, fn{k});
        end
    end

end




end








