function optout = ofill(optin, mos, mosc, opt)

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
compound mos: mos and submos
childmos: mos that only ever appear as submos in compound mos, in d (eg, cm only ever appears within mos roi, which in mostree is compound mos roi.cm)
d-mos, du-mos, optin-mos: mos in d, du, and optin, respectively
mostree: list of all mos and compound mos in d, ie all d-mos (defines nesting organization of d, relative to du), defined in odf.m
mostreeget: function that derives mos for any input struct, relative to du
o: main options struct holding all mos; default version is d

du: struct defined in odf, holds all default options for all modules and submodules in a2p; fields directly below du are mos, and below each mos are module options 
    fieldnames(du) returns all mos, no compound mos (some du-mos appear as submos or childmos in d); d-childmos are du-mos; for example, cm only appears within roi in d, but is a du-mos
d: struct defined in odf, nested version of du, with some submodules nested within modules (mostree, also defined in odf, defines this nesting)
optout: output struct defined in ofill.m, holds module options used in a2p; matches default d unless input optin specifies a different value
    in particular: if a field is in both optin.mos and d.mos, use the value in optin.mos; if field is only in d.mos, use the value in d.mos; if field in optin.mos isn't in d.mos, error


positional arguments 
    --optin: user-input options struct that replaces default; 
    --mos: names of mos to operate on; mos means "module options struct"; in comments, optin-mos refers to mos in optin, in contrast to positional argument mos
        --childmos are only valid if optin is empty ('cm' will return options in du.cm if optin is empty; if optin is nonempty, code will error)
        --compound mos will fill only the deepest mos in the compound mos ('bmp.mdl.opg' will only fill opg below mdl below bmp); rec value (0 or 1) only refers to what gets filled
    --mosc: mosc means "module options struct container"; name of temporary structs to hold mos (to create different copies of mos for different datasets); eventually (after oid) all top-level mos are put in mosc with optid names 

name-value arguments 
    --rec=1: recursively finish all mos, whether derived from optin or input mos (if listed mos has no submos, equivalent to rec=0)
    --mosfinal=nonempty: set to empty any optout-mos that aren't listed in mosfinal; if mosfinal is nonempty, mos and mosc must be empty; cannot be set to empty (that would result in empty optout); all mos listed in mosfinal must be top-level mos (removing nested fields is an unusual use case that doesn't justify the complexity right now)
    --unpack=1: open/unpack top level struct in optout (only works if there is only one top-level struct)
    --wild=1: replace all default options values with wildcard (for finding saved variables with function tsget)

ofill constructs o to mirror d, so access to submos (structs in du) are only available if o is empty and submos are listed as mos
ofill algorithm (basic, ignoring name-value arguments)
    --define mos:
        optin=empty,    mos=empty: if rec=0, all non-compound d-mos/mostree; if rec=1, all d-mos (compound and non-compound mos listed in mostree)
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
    o = ofill(o, 'bmp') --> "non-recursive mos fill", fill options but no mos below bmp only; same applies if mos is a compound mos, eg ofill(o, 'bmp.mdl') fills options but no mos below bmp.mdl only
    o = ofill(o, 'bmp', rec=1) --> "nested mos fill", fill options and mos recursively below bmp; same applies if mos is itself nested, eg ofill(o, 'bmp.mdl', rec=1) fills options and mos recursively below bmp.mdl only
    o = ofill([], submos)  --> "submos fill", where 'submos' is any field in du; same output with rec=0 or rec=1 since submos contain no mos (only options); input mos can only be submos if 
    o = ofill([], allmos)  --> "du fill", where 'allmos' are all du-mos (ie fieldnames(du), not d-mos/mostree); same output with rec=0 or rec=1; 

can call ofill in different ways
    no arguments: ofill(), sets optout equal to d (all default options)
    optin only: ofill(optin), sets options for fields in optin, setting default for options not listed  
    optin-mos arguments: ofill(optin, mos), sets options for d.mos only, even if mos don't appear in optin (if they don't they will be all default); mos can be nested (mos1.mos2); mos can be a sub-mos if optin is empty; can also just omit optin argument, like this ofill(mos)
    three arguments: ofill(optin, mos, mosc), creates struct(s) (names in mosc) within mos

NOTE IF YOU ARE CALLING ofill OUTSIDE ITS PLACE IN a2p (FOR EXAMPLE, TESTING ofill BY ITSELF) YOU MUST CLEAR PERSISTENT VARIABLES BY RUNNING 'clear ofill' BEFORE STARTING TO BUILD AN OPTIONS STRUCT (IE BEFORE THE FIRST ofill CALL, NOT BEFORE EVERY CALL);

%}

arguments
    optin = [] % input options struct for overwriting defaults in default options struct d; if optin is empty, will set defaults for all mos (2nd positional argument)
    mos = [] % char, or cell of char, or string, or empty; mos means "module options struct"; names of mos to fill options for; if optin is empty, empty mos gets set to all mos; if optin is nonempty, empty mos gets set to optin-mos (mos in optin)
    mosc = [] % char, or cell of char, or string, or empty to skip; mos means "module options struct container"; subfield names into which mos are copied; the mos that are placed into mosc are derived as described above (for example, if mos is empty, and optin is nonempty, mos becomes optin-mos, and all these mos would be placed in any mosc listed; each mos gets placed into all mosc (so 3 mos and 4 mosc would create 12 mosc in the options struct)
    opt.mosfinal = [] % % char, or cell of char, or string, or empty; set any optout-mos to empty if they aren't listed in mosfinal; if mosfinal is nonempty, mos and mosc must be empty; cannot be set to empty (that would result in empty optout); all mos listed in mosfinal must be top-level mos (removing nested fields is an unusual use case that doesn't justify the complexity right now); mosfinal is intended for the last time you call ofill for an options struct, to simplify your oset file (so you can set all mos you might want, then remove any you don't want at the end); after mosfinal, finished=1 appears as top level field in optout
    opt.rec = []; % 0 or 1; default 0 (set below); whether to finish all default nestings listed in mostree (in odf.m); if mos is nonempty, will finish all nests in input mos only; if mos is empty will finish all nestings for entire options struct; rec=1 is not necessary for an mos that has no nested mos (so it will error in this case)
    opt.unpack = []; % 0 or 1; default 0 (set below); if output has a single top-level srtuct, unpack it (you will lose the name of that top level struct in the output)
    opt.wild = []; % 0 or 1; default 0 (set below); all defaults become wildcard; if empty, all defaults remain unchanged; if nonempty, all defaults become '*'
end
mosfinal = opt.mosfinal;
rec = opt.rec;
unpack = opt.unpack;
wild = opt.wild;

persistent d
persistent du
persistent mostree
persistent mostree_open
persistent mostree_top

delimflat = '__';

%%%% check inputs %%%%

if istextall(optin)  % check if optin was omitted, if so, first argument was mos; update arguments accordingly
    if istextall(mos)
        mosc = mos;
    end
    mos = optin;
    optin = [];
end

mos = textin_format(mos);
mosc = textin_format(mosc);
mosfinal = textin_format(mosfinal);

if ~isempty(mosfinal)
    if ~isempty(mos) || ~isempty(mosc) || ~isempty(rec) || ~isempty(unpack) || ~isempty(wild)
        error("if mosfinal is nonempty, you cannot set any other inputs (mos, mosc, rec, unpack, and wild)")
    end
end

if isempty(rec)
    rec = 0;
end
if isempty(unpack)
    unpack = 0;
end
if isempty(wild)
    wild = 0;
end


%%%% load default options with odf.m %%%%

pthopt = [pthscopaget() 'optdf.txt'];

if isempty(d) && isempty(du) && isempty(mostree)
    odf(pthopt); %write defaults to file the first time ofill gets called when running a2p or oset (in particular, when persistent variables are empty)
    if isfile(pthopt)
        dall = structld(pthopt, nocells=1, dosort=0);
        d = dall.d;
        du = dall.du;
        mostree = dall.mostree;
        mostree_open = dall.mostree_open;
        mostree_top = dall.mostree_top;
    else
        error("cannot find default options file: " + pthopt + newline + "run 'odf()' to create it")
    end
end

%%%% optionally set all options to wildcard (for tsget) %%%%

if wild %fill d with wildcard
    wcpat = '*';
    d = structflat(d, delim=delimflat);
    fn = fieldnames(d);
    for k = 1:numel(fn)
        d.(fn{k}) = wcpat;
    end
    d = structunflat(d, delim=delimflat);
end


%%%% ofill_scalar (ofill for each struct element, ie stack) %%%%

if isempty(optin)
    optout = ofill_scalar(d, du, mostree, mostree_open, mostree_top, optin, mos, mosc, rec, mosfinal);
else
    for k = numel(optin):-1:1 %in case optout is nonscalar, loop over each element, calling ofill_scalar; backward to preallocate
        optout(k) = ofill_scalar(d, du, mostree, mostree_open, mostree_top, optin(k), mos, mosc, rec, mosfinal);
    end
end


%%%% optional unpack %%%%

if unpack
    if ~isscalar(optout)
        error("cannot unpack nonscalar struct")
    end
    if numel(fieldnames(optout))>1
        error("cannot unpack optout with multiple fields")
    end
    optout = optout.(cell2mat(fieldnames(optout)));
end


end



function optout = ofill_scalar(d, du, mostree, mostree_open, mostree_top, optin, mos, mosc, rec, mosfinal)


persistent mosc_all_loc
if isempty(mosc_all_loc)
    mosc_all_loc = {};
end

if isfield(optin, 'finished')
    if isequal(optin.finished, 1)
        error("you cannot call ofill on an options struct that is 'finished' (has field named 'finished', which will always take value of 1, if field exists)")
    else
        error("the value of field 'finished' is not 1; the only valid value is 1")
    end
end

if isempty(mosfinal)

    if isemptyall(optin) && isempty(mos)

        mos = mostree_top; %set mos here in case mosc is nonempty, simplifies setting mosc below
        for k = 1:numel(mos)
            if rec
                optout.(mos{k}) = d.(mos{k}); % optout is just d if no optin or input mos and rec=1
            else
                optout.(mos{k}) = du.(mos{k}); % optout is just top-level d-mos if no optin or input mos and rec=0
            end
        end

    else

        for k = 1:numel(mosc_all_loc)
            sind = structind(mosc_all_loc{k}{1}); %the parent of the mosc is in the first cell of mosc_all_loc
            tmp = getfield(optin, sind{:}); %get that parent from optin
            tmp = rmfield(tmp, mosc_all_loc{k}{2}); %remove the mosc from the parent (mosc alone is in second cell of mosc_all_loc)
            optin = setfield(optin, sind{:}, tmp); %set optin with mosc removed (below it will be put into optout) 
        end

        allow_du_mos = 0;
        if isemptyall(optin)
            optin = struct;
            allow_du_mos = 1;
        end

        [~, mostree_optin_open, ~] = mostreeget(optin, du); %optin-mos

        if isempty(mos)
            mos = mostree_optin_open;
            mos_optin_only = {};
        else
            mos_optin_only = setdiff(mostree_optin_open, mos); %optin-mos that aren't in input mos
        end

        optout = struct;
        for k = 1:numel(mos_optin_only) % create mos_optin_only in optout and set to their values in optin (otherwise structfill will error)
            sind = structind(mos_optin_only{k});
            tmp = getfield(optin, sind{:});
            optout = setfield(optout, sind{:}, tmp);
        end

        for k = 1:numel(mos) % create mos in optout and set to their values in default structs (d, or du if allow_du_mos)
            sind = structind(mos{k});
            if ismember(mos{k}, mostree_open)
                if rec
                    tmp = getfield(d, sind{:});
                else
                    tmp = du.(sind{end});
                end
            elseif ismember(mos{k}, fieldnames(du))
                if allow_du_mos
                    tmp = getfield(du, sind{:}); %rec is irrelevant in this case
                else
                    error(mos{k} + " is a submos in mostree (defined in odf.m), but you can only pass in submos as mos argument to ofill if argument optin is empty")
                end
            else
                error(mos{k} + " is not listed in mostree (defined in odf.m), either as mos, submos, or compound mos")
            end
            optout = setfield(optout, sind{:}, tmp);
        end
        [~, mostree_optout_open, ~] = mostreeget(optout, du); %mos in optout

        mos_return = mos_optin_only(~cellfun(@isempty, regexp(mos_optin_only, ['^(' sprintf('%s|', mos{:}) ')\..*$']))); %check if any mos just filled is a parent of a mos_optin_only filled earlier, if so, it got overwritten with defaults, so return to original value
        for k = 1:numel(mos_return)
            if ~ismember(mos_return{k}, mostree_optout_open)
                sind = structind(mos_return{k});
                tmp = getfield(optin, sind{:});
                optout = setfield(optout, sind{:}, tmp);
            end
        end

        optout = structfill(optin, optout);

    end

    optout = structsort(optout, vectype='row');

    mostree_optout = mostreeget(optout, du); %call this a second time because optout could have changed
    if ~all(ismember(mostree_optout, mostree_open)) && ~allow_du_mos
        error("there is an optout-mos that is not found in d-mos (ie not listed in mostree, in odf.m); you may have created an invalid mos, or placed a nested mos in an invalid location")
    end

    for q = 1:numel(mosc) %loop over any current mosc . . .
        for k = 1:numel(mos) %and all current mos 
            mosc_all_loc = cat(2, mosc_all_loc, { { mos{k}, mosc{q} } }); %keep record of mos above the mosc and the mosc alone in persistent variable (adding current to previous); save both for convenience, since they get used later
        end
    end

    for k = 1:numel(mosc_all_loc) %apply any mosc (current and previous, since both are now in mosc_all_loc . . .
        sind = structind(mosc_all_loc{k}{1});
        tmp = getfield(optout, sind{:}); % get mos first . . .
        optout = setfield(optout, sind{:}, []); % then set it to empty . . .
        sind = structind([mosc_all_loc{k}{1} '.' mosc_all_loc{k}{2}]); % then make strucd index for mos.mosc (the full "path" to the mosc, using first and second sub-cell from mosc_all_loc) . . .
        optout = setfield(optout, sind{:}, tmp); % now set mosc
    end

    glb(1, mosc=mosc_all_loc);

else %if mosfinal is nonempty

    optout = optin;
    if any(~ismember(mosfinal, mostree_top))
        error("all mos in mosfinal must be top-level mos")
    end
    [~, mostree_optout_open, ~] = mostreeget(optout, du); %call this a third time because optout could have changed again
    mostree_optout_open_keep = mostree_optout_open(~cellfun(@isempty, regexp(mostree_optout_open, ['^(' sprintf('%s|', mosfinal{:}) ')(\..*)*$'])));
    for k = 1:numel(mostree_open)
        sind = structind(mostree_open{k});
        if ~ismember(mostree_open{k}, mostree_optout_open_keep)
            optout = setfield(optout, sind{:}, []); %set any missing mos to empty when mosfinal is nonempty
        end
    end

    mos_open_descend = sort(mostree_open, 'descend'); %sort descending (deepest to shallowest)
    for k = 1:numel(mos_open_descend)
        sind = structind(mos_open_descend{k});
        if ~isempty(getfield(optout, sind{:})) && all(structfun(@isempty, getfield(optout, sind{:})))
            optout = setfield(optout, sind{:}, []); %set to empty any mos containing nothing but other empty mos
        end
    end

    optout.finished = 1; %create this field and set to true when options struct is finished (this will prevent further modification, and permit some other functions to run (like oid and tsget)

end


end



function x = textin_format(x)

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