function optout = ofill(optin, mos, opt)

%{

construct options struct that mirrors organization of default options struct d (defined in odf.m), but, optionally, with user-supplied values

default options struct d is defined in odf.m
d is a struct built by nesting fields of struct du according to pattern in variable 'mostree'
d, du, and mostree are all defined in odf.m

user-supplied options struct 'optin' can be subset of d (ie field organization and field names must match)
option values can differ from those in d
for any fields in d that are not in optin, ofill creates those fields and fills with default values from d 

module: high-level function called directly from a2p
options: inputs to module that are tracked by id (assigned to unique set of options)
    options are tracked and given id for modules because they can have big effect on output variables; id also simplifies naming files, figures, etc.

a2p.m tracks options with the following files 
    odf.m: holds default options 
    oset.m: finds recordings, and routes to oset_* files specialized for setting options for stacks meeting some criteria; also sets global variables in function 'glb', and derives optid with function oid.m
    oset_*.m: sets options by calling ofill on an options struct created by user (for example, oset_opto.m)
    ofill.m: fills user supplied options struct 
    structfill.m: is a more general function for structs, filling one struct with values from another (for fields missing from the first)
    oid.m: creates requested combinations of options (distributes any cells) and assigns each unique options set an optid (eg 'a1', 'a2', etc), writes them to their respective opt_*.txt file, and updates options struct with new optid substructs
    structfile.m: reads/writes options to file, using optid derived in oid


module: function called directly from a2p, options tracked by id
submodule: function called from module, options tracked by id 
options: inputs to modules and submodules that are tracked by id
modules and submodules create analytic variables (ie modules are not plotting functions, or utility functions)
other a2p functions are not called modules because their inputs are not tracked by id

above/below/beside: relations among fields in options struct

mos: "module options struct" struct holding options for modules or submodules; mos can refer to the struct and the name of the struct
submos: mos when it appears below another mos 
supermos: mos when it appears above another mos
polymos: supermos with one or more submos (separated by period, supermos.submos, eg, roi.ma)
childmos: mos that only ever appears as a submos in polymos in d (eg, mos 'cm' only ever appears below mos 'roi', which in mostree is polymos 'roi.cm')
d-mos, du-mos, optin-mos: mos in d, du, and optin, respectively
mostree: list of all mos and polymos in d, ie all d-mos (defines nesting organization of d, relative to du), defined in odf.m
mostreeget: function that derives mos for any input struct, relative to du
o: main options struct holding all mos; default version is d

du: struct defined in odf, holds all default options for all modules and submodules in a2p; fields directly below du are mos, and below each mos are module options 
    fieldnames(du) returns all mos, no polymos (some du-mos appear as submos or childmos in d); d-childmos are du-mos; for example, cm only appears within roi in d, but is a du-mos
d: struct defined in odf, nested version of du, with some submodules nested within modules (mostree, also defined in odf, defines this nesting)
optout: output struct defined in ofill.m, holds module options used in a2p; matches default d unless input optin specifies a different value
    in particular: if a field is in both optin.mos and d.mos, use the value in optin.mos; if field is only in d.mos, use the value in d.mos; if field in optin.mos isn't in d.mos, error


positional arguments 
    --optin: user-input options struct that replaces default; 
    --mos: names of mos to operate on; mos means "module options struct"; in comments, optin-mos refers to mos in optin, in contrast to positional argument mos
        --childmos are only valid if optin is empty ('cm' will return options in du.cm if optin is empty; if optin is nonempty, code will error)
        --polymos will fill only the deepest mos in the polymos ('bmp.mdl.opg' will only fill opg below mdl below bmp); rec value (0 or 1) only refers to what gets filled
    --mosc: mosc means "module options struct container"; name of temporary structs to hold mos (to create different copies of mos for different datasets); 
        --mosc are useful for creating options sets with values you want together (for example, when roi.rgname='eb' you might want roi.ma.numroi=128, and when roi.rgname='pb' you might want roi.ma.numroi=256)
        --eventually (after oid) all top-level mos are put in mosc with optid names 
        --once you've set a mosc, you cannot access it as a mos in later calls to ofill (if you want to modify it, you have to modify it directly, outside ofill) 

name-value arguments 
    --rec=1: recursively finish all mos, whether derived from optin or input mos (if listed mos has no submos, equivalent to rec=0)
    --mosfinal=nonempty: set to empty any optout-mos that aren't listed in mosfinal; if mosfinal is nonempty, mos and mosc must be empty; cannot be set to empty (that would result in empty optout); all mos listed in mosfinal must be top-level mos (removing nested fields is an unusual use case that doesn't justify the complexity right now)
    --unpack=1: open/unpack top level struct in optout (only works if there is only one top-level struct)
    --wild=1: replace all default options values with wildcard (for finding saved variables with function vget)

ofill constructs o to mirror d, so access to submos (structs in du) are only available if o is empty and submos are listed as mos
ofill algorithm (basic, ignoring name-value arguments)
    --define mos:
        optin=empty,    mos=empty: if rec=0, all non-compound d-mos/mostree; if rec=1, all d-mos (compound and non-polymos listed in mostree)
        optin=nonempty, mos=empty: all optin-mos
        optin=nonempty, mos=nonempty: mos, but not optin-mos (unless also in mos) 
    --make sure mos are valid: appear in d/mostree, or as submos in du if optin is empty
    --make sure optin is valid: if rec=0, optin options exist in d; if rec=1, optin options and mos exist in d
    --update options: update d with options listed in optin, recursively (ie into enclosed mos) if rec=1

examples:
    assuming user input is 
        o.bmp.mdl.valnum = 1
            o is main options struct, bmp is mos, mdl is submos, valnum is option for module mdlmake (given mos name mdl)
    o = ofill() --> "non-recursive d fill", user input o is irrelevant and overwritten by output o; output o is all top level d-mos (mostree_top), since rec is not true, all with default options
    o = ofill(rec=1) --> "recursive d fill", user input o is irrelevant and overwritten by output o; output o is all d-mos (mostree), since rec is true, all with default options
    o = ofill(o) --> "non-recursive o fill", fill options below bmp and bmp.mdl, but no mos below bmp and bmp.mdl;
    o = ofill(o, rec=1) --> "recursive o fill", fill options and mos below bmp and bmp.mdl
    o = ofill(o, 'bmp') --> "non-recursive mos fill", fill options but no mos below bmp only; same applies if mos is a polymos, eg ofill(o, 'bmp.mdl') fills options but no mos below bmp.mdl only
    o = ofill(o, 'bmp', rec=1) --> "nested mos fill", fill options and mos recursively below bmp; same applies if mos is itself nested, eg ofill(o, 'bmp.mdl', rec=1) fills options and mos recursively below bmp.mdl only
    o = ofill([], submos)  --> "submos fill", where 'submos' is any field in du; same output with rec=0 or rec=1 since submos contain no mos (only options); input mos can only be submos if 
    o = ofill([], allmos)  --> "du fill", where 'allmos' are all du-mos (ie fieldnames(du), not d-mos/mostree); same output with rec=0 or rec=1; 

can call ofill in different ways
    no arguments: ofill(), sets optout equal to d (all default options)
    optin only: ofill(optin), sets options for fields in optin, setting default for options not listed  
    optin-mos arguments: ofill(optin, mos), sets options for d.mos only, even if mos don't appear in optin (if they don't they will be all default); mos can be nested (mos1.mos2); mos can be a sub-mos if optin is empty; can also just omit optin argument, like this ofill(mos)
    three arguments: ofill(optin, mos, mosc), creates struct(s) (names in mosc) within mos

NOTE IF YOU ARE CALLING ofill OUTSIDE ITS PLACE IN a2p (FOR EXAMPLE, TESTING ofill BY ITSELF) YOU MUST CLEAR PERSISTENT VARIABLES BY RUNNING 'clear ofill' BEFORE STARTING TO BUILD AN OPTIONS STRUCT (IE BEFORE THE FIRST ofill CALL, NOT BEFORE EVERY CALL);
NOTE optout will have temporary field 'ometa' that holds various metadata fields (all mosc user has passed into ofill before setting nonempty mosfinal, and all default option info from odf) during creation of options struct, but when running ofill with nonempty mosfinal, ometa is removed
NOTE after setting nonempty mosfinal, it is recommended you not modify the options struct 

%}

arguments
    optin = struct([]) % input options struct for overwriting defaults in default options struct d; if optin is empty, will set defaults for all mos (2nd positional argument)
    mos {mustBeText} = '' % char, or cell of char, or string, or empty; mos means "module options struct"; names of mos to fill options for; if optin is empty, empty mos gets set to all mos; if optin is nonempty, empty mos gets set to optin-mos (mos in optin) that ave not already been operated on; if mos is nonempty, ofill operates on listed mos, whether they exist in optin or not, and whether they have been operated on before or not
    opt.mosc {mustBeText} = '' % char, or cell of char, or string, or empty to skip; mosc means "module options struct container"; subfield names into which mos are copied; the mos that are placed into mosc are derived as described above (for example, if mos is empty, and optin is nonempty, mos becomes optin-mos, and all these mos would be placed in any mosc listed; each mos gets placed into all mosc (so 3 mos and 4 mosc would create 12 mosc in the options struct)
    opt.mosfinal {mustBeText} = '' % % char, or cell of char, or string, or empty; set any optout-mos to empty if they aren't listed in mosfinal; if mosfinal is nonempty, mos and mosc must be empty; cannot be set to empty (that would result in empty optout); all mos listed in mosfinal must be top-level mos (removing nested fields is an unusual use case that doesn't justify the complexity right now); mosfinal is intended for the last time you call ofill for an options struct, to simplify your oset file (so you can set all mos you might want, then remove any you don't want at the end); 
    opt.rec (1,1) {mustBeBinary} = 0; % 0 or 1; default 0; whether to finish all default nestings listed in mostree (in odf.m); if mos is nonempty, will finish all nests in input mos only; if mos is empty will finish all nestings for entire options struct; rec=1 is not necessary for an mos that has no nested mos (so it will error in this case)
    opt.unpack (1,1) {mustBeBinary} = 0; % 0 or 1; default 0; if output has a single top-level srtuct, unpack it (you will lose the name of that top level struct in the output)
    opt.wild (1,1) {mustBeBinary} = 0; % 0 or 1; default 0; all defaults become wildcard; if empty, all defaults remain unchanged; if nonempty, all defaults become '*'
    opt.id (1,1) {mustBeBinary} = 0 % 0 or 1; default 0; 
end
mosc = opt.mosc;
mosfinal = opt.mosfinal;
rec = opt.rec;
unpack = opt.unpack;
wild = opt.wild;

delimflat = '__';


%%%% CHECK INPUTS %%%%

if istextall(optin)  % check if optin was omitted, if so, first argument was mos; update arguments accordingly
    mos = optin;
    optin = struct([]);
end

mos = textin_format(mos);
mosc = textin_format(mosc);
mosfinal = textin_format(mosfinal);

if ~isempty(mosc)
    if ~isempty(mos)
        error("if mosc is nonempty, you cannot pass in any mos (2nd positional argument)")
    end
    if ~isequal(numel(mosc), 2)
        error("if mosc is nonempty, it must be a 2-element cell array or string array, that is, cell {mos, mosc} or string array [mos, mosc]")
    end
    if strcmp(mosc{2}, 'ometa')
        error("cannot name mosc 'ometa' because that fieldname is reserved for defaults loaded from odf")
    end
end

if ~isempty(mosfinal)
    if ~isempty(mos) || ~isempty(mosc) || unpack || wild
        error("if mosfinal is nonempty, you cannot set mos, mosc, unpack, or wild ")
    end
end


%%%% LOAD DEFAULT OPTIONS WITH odf.m %%%%

if ~isfield(optin, 'ometa')
    pthopt = odf(); %write defaults to file the first time ofill gets called when running a2p or oset (in particular, when persistent variables are empty)
    if isfile(pthopt)
        optin(1).ometa.dall = structld(pthopt, nocells=1, dosort=0);
        optin.ometa(1).mosc_all = {};
        for k = 2:numel(optin)
            optin(k).ometa.dall = optin(1).ometa.dall;
            optin.ometa(k).mosc_all = {};
        end
    else
        error("cannot find default options file: " + pthopt + newline + "run 'odf()' to create it")
    end
end


%%%% OPTIONALLY SET ALL OPTIONS TO WILDCARD (FOR vget) %%%%

if wild %fill d with wildcard
    wcpat = '*';
    d = structflat(d, delim=delimflat);
    fn = fieldnames(d);
    for k = 1:numel(fn)
        d.(fn{k}) = wcpat;
    end
    d = structunflat(d, delim=delimflat);
end


%%%% ofill_scalar IS ofill FOR EACH ELEMENT/STACK) %%%%

for k = numel(optin):-1:1 %in case optout is nonscalar, loop over each element, calling ofill_scalar; backward to preallocate, not that it really matters
    optout(k) = ofill_scalar(optin(k), mos, mosc, rec, mosfinal);
end


%%%% OPTIONAL UNPACK %%%%

if unpack
    optout = rmfield(optout, 'ometa'); %if unpacking, you don't need ometa (ometa is just for retaining meta-fields while building options struct, acting like persistent variables)
    if ~isscalar(optout)
        error("cannot unpack nonscalar struct")
    end
    if numel(fieldnames(optout))>1
        error("cannot unpack optout with multiple fields")
    end
    optout = optout.(cell2mat(fieldnames(optout)));
end


end



function optout = ofill_scalar(optin, mos, mosc, rec, mosfinal)

d = optin.ometa.dall.d;
du = optin.ometa.dall.du;
mostree = optin.ometa.dall.mostree;
mostree_open = optin.ometa.dall.mostree_open;
mostree_top = optin.ometa.dall.mostree_top;
if all(cellfun(@ischar, struct2cell(optin.ometa.dall.mosh)))
    mosh = structfun(@str2func, optin.ometa.dall.mosh, UniformOutput=false);
else
    mosh = optin.ometa.dall.mosh;
end
mosc_all = optin.ometa.mosc_all;

optin = rmfield(optin, 'ometa');

mostree_du = fieldnames(du); %mostree_du is the same as all non-polymos in mostree_open

if ~isemptyall(mosc) && any(ismember(mosc{2}, mostree_du))
    error("mosc cannot have same names as any mos")
end
if any(~ismember(mosfinal, mostree_top))
    error("all mos in mosfinal must be top-level mos")
end


if isemptyall(optin) && isempty(mos) && isempty(mosfinal)

    mos = mostree_top; %set mos here in case mosc is nonempty, simplifies setting mosc below
    for k = 1:numel(mos)
        if rec
            optout.(mos{k}) = d.(mos{k}); % optout is just d if no optin or input mos and rec=1
        else
            optout.(mos{k}) = du.(mos{k}); % optout is just top-level d-mos if no optin or input mos and rec=0
        end
    end

else

    if ~isempty(mosfinal) && ~isempty(optin)
        fn_optin = fieldnames(optin);
        optin = rmfield(optin, fn_optin(~ismember(fn_optin, mosfinal)));
    end

    for k = 1:size(mosc_all,1) %first remove mosc from optin
        stind = structind(mosc_all{k,1}); %the parent of the mosc is in the first cell of mosc_all
        tmp = getfield(optin, stind{:}); %get that parent from optin
        tmp = rmfield(tmp, mosc_all{k,2}); %remove the mosc from the parent (mosc alone is in second cell of mosc_all)
        optin = setfield(optin, stind{:}, tmp); %set optin with mosc removed (below it will be put into optout)
    end

    allow_du_mos = 0;
    if isemptyall(optin)
        optin = struct;
        allow_du_mos = 1;
    end

    [~, mostree_optin_open, ~] = mostreeget(optin, du); %optin-mos

    if isempty(mos)
        mos = mostree_optin_open;
        mos = unique(cat(1, mos(:), mosfinal(:)));
        mos_skip = {}; %must be empty cell
    else
        mos_skip = setdiff(mostree_optin_open, mos); %optin-mos that aren't in input mos
    end

    optout = struct;
    for k = 1:numel(mos_skip) % create mos_optin_only in optout and set to their values in optin (otherwise structfill will error)
        stind = structind(mos_skip{k});
        tmp = getfield(optin, stind{:});
        optout = setfield(optout, stind{:}, tmp);
    end

    for k = 1:numel(mos) % create mos in optout and set to their values in default structs (d, or du if allow_du_mos)
        stind = structind(mos{k});
        if ismember(mos{k}, mostree_open)
            if rec
                tmp = getfield(d, stind{:});
            else
                tmp = du.(stind{end});
            end
        elseif ismember(mos{k}, mostree_du)
            if allow_du_mos
                tmp = getfield(du, stind{:}); %rec is irrelevant in this case
            else
                error(mos{k} + " is a submos in mostree (defined in odf.m), but you can only pass in submos as mos argument to ofill if argument optin is empty")
            end
        else
            error(mos{k} + " is not listed in mostree (defined in odf.m), either as mos, submos, or polymos")
        end
        optout = setfield(optout, stind{:}, tmp);
    end
    [~, mostree_optout_open, ~] = mostreeget(optout, du); %mos in optout

    mos_return = mos_skip(~cellfun(@isempty, regexp(mos_skip, ['^(' sprintf('%s|', mos{:}) ')\..*$'], 'forceCellOutput'))); %check if any mos just filled is a parent of a mos_optin_only filled earlier, if so, it got overwritten with defaults, so return to original value
    for k = 1:numel(mos_return)
        if ~ismember(mos_return{k}, mostree_optout_open)
            stind = structind(mos_return{k});
            tmp = getfield(optin, stind{:});
            optout = setfield(optout, stind{:}, tmp);
        end
    end

    optout = structfill(optin, optout);

end

[mostree_optout, mostree_optout_open, ~] = mostreeget(optout, du); %call this a second time because optout could have changed
if ~all(ismember(mostree_optout, mostree_open)) && ~allow_du_mos
    error("there is an optout-mos that is not found in d-mos (ie not listed in mostree, in odf.m); you may have created an invalid mos, or placed a nested mos in an invalid location")
end

if ~isempty(mosc) %save any current mosc to persistent variable . . .
    if ~all(ismember(mosc{1}, mostree_optout_open))
        error("mosc first element must be mos in optout (if it weren't it would just be placing all defaults in a mosc, which is pointless; mosc are used to group options, and defaults are already in a group)")
    end
    stind = structind(mosc{1}); %the parent of the mosc is in the first cell of mosc_all
    tmp = getfield(optout, stind{:}); %get that parent from optin
    mosc_all = cat(1, mosc_all, { mosc{1}, mosc{2}, tmp }); %keep record of mos above the mosc and the mosc alone and the mosc struct, all in persistent variable (adding current to previous); save all of these for convenience, since they get used later
    mos = regexprep(mos, ['^(' mosc{1} ')(\..*)*$'], ['$1' '.' mosc{2} '$2']); %add mosc into any mos it applies to, so record of mos in persistent variable shows mosc there
end

for k = 1:size(mosc_all,1) %apply any mosc (current and previous, since both are now in mosc_all . . .
    sind_compound = structind([mosc_all{k,1} '.' mosc_all{k,2}]); % then make struct index for mos.mosc (the full "path" to the mosc, using first and second sub-cell from mosc_all) . . .
    optout = setfield(optout, sind_compound{:},  mosc_all{k,3}); % now set mosc
    sind_mos = structind(mosc_all{k,1});
    tmp_mos_new = getfield(optout, sind_mos{:}); % get mos again, after setting mosc . . .
    mosc_not = fieldnames(tmp_mos_new);
    mosc_not = mosc_not(~ismember(mosc_not, mosc_all(:,2)));
    tmp_mos_new = rmfield(tmp_mos_new, mosc_not); %remove all non-mosc fields
    optout = setfield(optout, sind_mos{:}, tmp_mos_new); % now set mosc
end


if ~isempty(mosfinal)

    mosc_all_names = {};
    if ~isempty(mosc_all)
        mosc_all_names = mosc_all(:,2);
    end

    omixcheck(optout, mosc_all_names, mostree_du);

    [~, mostree_optout_open, ~] = mostreeget(optout, du, mosc_all_names); %call this a third time because optout could have changed again
    mostree_optout_open_keep = mostree_optout_open(~cellfun(@isempty, regexp(mostree_optout_open, ['^(' sprintf('%s|', mosfinal{:}) ')(\..*)*$'], 'forcecelloutput'))); %keep mostree_optout_open that begin with mosfinal (since mosfinal are required to be from mostree_top)

    if isempty(mosc_all)
        mostree_open_with_mosc = mostree_open;
    else
        mostree_open_with_mosc = {}; %create mostree_open with all mosc inserted (not the same as mostree_optout_open with all mosc inserted)
        for k = 1:numel(mostree_open)
            spl = strsplit(mostree_open{k}, '.');
            mos_parent_above_mosc = strjoin(spl(1:end-1), '.');
            mosc_curr = mosc_all_names(ismember(strcat(mos_parent_above_mosc, '.', mosc_all_names), mostree_optout_open));
            if ~isempty(mosc_curr)
                tmp = mostree_open(startsWith(mostree_open, mos_parent_above_mosc)); %only the current mos
                tmp_w_mosc = {};
                for q = 1:numel(mosc_curr)
                    tmp_w_mosc = unique(cat(2, tmp_w_mosc, regexprep(tmp, ['^(' mos_parent_above_mosc ')(\..*)*$'], ['$1' '.' mosc_curr{q} '$2']))); %put in the mosc
                end
                mostree_open_with_mosc = mostree_open(cellfun(@isempty, regexp(mostree_open, ['^' mos_parent_above_mosc '(?:\..*)*$']))); %remove the old mos that needs updating with mosc
                mostree_open_with_mosc = cat(2, mostree_open_with_mosc, tmp_w_mosc);
            end
        end
    end

    for k = 1:numel(mostree_open_with_mosc)
        stind = structind(mostree_open_with_mosc{k});
        if ~ismember(mostree_open_with_mosc{k}, mostree_optout_open_keep)
            optout = setfield(optout, stind{:}, []); %set any missing mos to empty when mosfinal is nonempty
        end
    end

    mostree_open_with_mosc_descend = sort(mostree_open_with_mosc, 'descend'); %sort descending (deepest to shallowest)
    for k = 1:numel(mostree_open_with_mosc_descend)
        stind = structind(mostree_open_with_mosc_descend{k});
        if ~isempty(getfield(optout, stind{:})) && all(structfun(@isemptyall, getfield(optout, stind{:})))
            optout = setfield(optout, stind{:}, []); %set to empty any mos containing nothing but other empty mos
        end
    end

    optout = oid(optout); %assign ids to options sets

    for k = 1:numel(mostree_open_with_mosc) %do option validation
        clear optmosh_tmp
        stind = structind(mostree_open_with_mosc{k});
        try
            optout_tmp = getfield(optout, stind{:});
        catch %skip trying to get submos when supermos is empty
            optout_tmp = [];
        end
        if ~isempty(optout_tmp)
            try
                if ismember(stind{end}, mostree_du)
                    stindtmp = stind{end};
                    stindtmp_with_mosc_option = stindtmp;
                elseif numel(stind)>2 && ismember(stind{end-2}, mostree_du)
                    stindtmp = stind{end-2};
                    stindtmp_with_mosc_option = strjoin(stind([end-2, end]), '.');
                else
                    error("you have either created a mosc directly below a mosc, or a mosc without a mos above (neither should not be possible, how did we get here)")
                end
                for m = 1:numel(optout_tmp)
                    prs = struct2pairs(optout_tmp(m));
                    optmosh_tmp(m) = mosh.(stindtmp)('', prs{:}, och=1); %for all mos in optout, apply argument validation from arguments block (using function handles in mosh, defined in odf)
                end
            catch ME
                error("attempt to validate inputs for module " +  stindtmp_with_mosc_option + newline + "failed with this error message " + ME.message)
            end
            for m = 1:numel(optout_tmp)
                optmosh_tmp_fn = fieldnames(optmosh_tmp(m));
                optmosh_tmp_ne = rmfield(optmosh_tmp(m), optmosh_tmp_fn(structfun(@isempty, optmosh_tmp(m))));
                optout_tmp_fn = fieldnames(optout_tmp(m));
                optout_tmp_ne = rmfield(optout_tmp(m), optout_tmp_fn(structfun(@isempty, optout_tmp(m))));
                if ~isequal(optmosh_tmp_ne, optout_tmp_ne) %make sure they match, except for empties, which can be different after jsonencode/decode (empty struct becomes [])
                    fprintf("user-supplied options changed (in a minor way, like vector orientation or class) in arguments block for module " + stindtmp_with_mosc_option + newline)
                end
            end
        end
    end


else

    optout.ometa.dall.d = d;
    optout.ometa.dall.du = du;
    optout.ometa.dall.mostree = mostree;
    optout.ometa.dall.mostree_open = mostree_open;
    optout.ometa.dall.mostree_top = mostree_top;
    optout.ometa.dall.mosh = mosh;
    optout.ometa.mosc_all = mosc_all;

end

optout = structsort(optout, vectype='row');


end



function x = textin_format(x) % format text input to ofill

x = convertStringsToChars(x); %in case it's string
if isemptyall(x)
    x = {};
end
if ~iscell(x)
    x = {x};
end
if ~isequal(numel(x), numel(unique(x)))
    error("you cannot pass in repeated " + inputname(1))
end
if ~istextall(x)
    error(inputname(1) + "must be empty or char or string or cell of char or cell of string")
end

end


function omixcheck(o, mosc, mostree_du) %make sure all mos contain options and submos only, or mosc only

fn = fieldnames(o);
fn = fn(~strcmp(fn, glbfile('fnvget'))); %remove vg
for k = 1:numel(fn)
    if isstruct(o.(fn{k}))
        omixcheck(o.(fn{k}), mosc, mostree_du);
    else
        if any(ismember(fn, mosc)) && ~all(ismember(fn, mosc))
            error("you have a mixture of options and mosc, which is not allowed when mosfinal is nonempty (the final stage of creating options struct)" + newline + "here is the mixture: " + newline + sprintf('%s\n', fn{:}))
        end
        if all(ismember(fn, mostree_du))
            error("at least one mos contains nothing but submos (ie does not contain options); this should not occur")
        end
    end
end

end