function [o, oflat] = oset(spec, opt)

%{

see docs_oset.m
FIX: EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
FIX: NONFUNCTIONAL (PLOTTING) OPTIONS ARE CURRENTLY ALL IN SEPARATE OBIN, SO OID EASILY DEALS WITH THEM, BUT CAN THIS ALWAYS BE THE CASE? what about redundant obins that get removed in ored, they aren't returned, is that a problem? should options leaving oset always have same fields?? 
FIX: ORED NEEDS TO REMOVE NONFUNCTIONAL OBIN AT ANY NESTING 
when constructing o, you can only append obin or option listed in odf;
options can be structs themselves, but defaults for all fields have to be defined oin odf
the only time a struct can appear within an option is struct tg, which
has special handling in ofill

**** NB: DO NOT USE CELLS UNLESS YOU INTEND THEM FOR DISTRIBUTION ****

%}

arguments
    spec = '' % spec struct (see function stackfind), or char or cell of char specifying full path to stack(s); if the latter, can have wildcards *; if empty, will search for file using spec below;
    opt.findstacks = 1 % find recordings using spec (or o.spec, if spec is empty); if you just want access to params and do not want to search for stacks, make findstacks=0
end
findstacks = opt.findstacks;

%%%% dodf, git, scopausername, python path %%%%

dodf = 0; %set to 1 use all defaults in odf.m (skip all oset_* files)

mn.usegit = 0; %1 to use git to sync with scopa remote repository to ensure integration across filesystems (eg for opt files); 0 to skip git
mn.scopausername = userdatfile('scopausername'); %cw, wz, jf, yz, sr; (to route to different oset_* files below)
mn.pthpy = fullfile(filesep, 'Users', 'wienecke', 'miniforge3', 'envs', 'caiman', 'bin', 'python3'); %path to python executable (if you want to run any python function from a2p, like mdsisv.py, or register.py, extract.py)

%%%% recording specifiers (used to find recordings if there is no input to a2p) %%%%

if findstacks

    if isempty(spec) %if you're running a2p without input arguments (ie if optional input 'spec' is empty), set specifiers here to find stack(s); any missing fields will get defaults in ofill; if spec is not empty, these specifiers are ignored
        spec.pthparloc = fullfile(filesep, 'Users', 'wienecke', 'stacks', filesep);
        spec.pthparo2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparloc ends with; a2p will automatically find it; otherwise fill this in to use o2
        spec.pth = {''}; %full path pattern, can have wildcards; if you use pth, you cannot use stackid, recdate, fly, trial, suffix, or substr (single wildcard * means 0 or more characters, but does not include file separators, or cross file separators; double wildcard ** means 0 or more folders, and must be between file separators);
        spec.stackid = {'20250920*'}; %char, format recdate_fly_trial_suffix; can include wildcards; can truncate full stackid format with wildcard * and wildcard * gets copied to each subsequent underscore-delimited label (eg, 2025* is equivalent to 2025*_*_*_*); cannot use stackid if any of pth, recdate, fly, trial, or suffix are nonempty
        spec.recdate = {''}; %cell array of char (or char vector), can use wildcards; empty will find any (equivalent to '*')
        spec.fly = {''}; %cell array of char (or char vector), can use wildcards; empty will find any (equivalent to '*')
        spec.trial = {''}; %cell ara2ray of char (or char vector), can use wildcards; empty will find any (equivalent to '*')
        spec.suffix = {''}; %cell array of char (or char vector), can use wildcards, stack filename suffix to use; valid suffixes are defined in odf, d.spec.suffixchar_raw and d.spec.suffixchars; empty will find any (equivalent to '*')
        spec.substr = {''}; %cell array of char (or char vector), can use wildcards, substring contained in path to stack (e.g. if all recordings from one campaign are in a subfolder with a descriptive name, you could put that name here, and asterisks for recdate, fly, trial, and get all those recordings just with the substr); empty will find any (equivalent to '*')
        spec.match = 'each'; %'any' or 'each'; 'any' for all combinations of recdate, fly, trial, suffix; 'each' for matched indices of each of these specifiers (length 1 will be repeated to match anything longer)
    else
        if ischar(spec) || isstring(spec) || iscellstr(spec) || ( iscell(spec) && isstring(spec{1}) )
            spec.pth = spec;
        elseif ~isstruct(spec)
            error("spec must be empty or char or string or cell of char or cell of string or struct")
        end
    end

    tmp = struct2pairs(spec);
    pthstacks = stackfind(tmp{:});
    if isempty(pthstacks)
        error("NO STACKS FOUND USING YOUR STACK SPECIFIERS (EITHER SET IN OSET, OR PASSED INTO a2p)" + newline)
    end

    idtmp = idmake(pthstacks);

end



%%%% loop over found stacks in otmp, setting options depending on recording (and scopausername) %%%%

for k = 1:numel(idtmp)

    otmp2 = [];

    if dodf

        otmp2 = otmp(k);

    else

        switch mn.scopausername

            case 'wz'

                if contains(idtmp(k).pthstack, {''}) %empty string means every recording

                    otmp2 = oset_wenyi();

                end

            case 'jf'

                if contains(idtmp(k).pthstack, {''}) %empty char for no path filtering

                    otmp2 = oset_jingxuan();

                end

            case 'yz'

                if contains(idtmp(k).pthstack, {''}) %empty char for no path filtering

                    otmp2 = oset_yunzhi();

                end

            case 'sr'

                if contains(idtmp(k).pthstack, {''}) %empty char for no path filtering

                    otmp2 = oset_sophia();

                end

            case 'cw'

                if contains(idtmp(k).pthstack, {'ebgano'})

                    otmp2 = oset_ebgano();

                elseif contains(idtmp(k).pthstack, {'ganopb'})

                    otmp2 = oset_ganopb();

                elseif contains(idtmp(k).pthstack, {'elno'})

                    otmp2 = oset_elno();

                elseif contains(idtmp(k).pthstack, {'ebno'}) && ~contains(idtmp(k).pthstack, {'ebgano'})

                    otmp2 = oset_ebno();

                elseif contains(idtmp(k).pthstack, {'opto'})

                    otmp2 = oset_opto();

                elseif contains(idtmp(k).pthstack, {'fb8c'})

                    otmp2 = oset_fb8c();

                elseif contains(idtmp(k).pthstack, {'mito'})

                    % otmp2 = oset_mito();
                    otmp2 = oset_mito2();

                elseif contains(idtmp(k).pthstack, {'312'})

                    otmp2 = oset_312();

                elseif contains(idtmp(k).pthstack, {'f91g'})

                    otmp2 = oset_t5();

                end

            otherwise

                error("scopausername not recognized, or empty; set mn.scopausername to one of the usernames that route oset into an oset_* file")

        end

    end

    if ~isempty(otmp2)
        o(k) = ofill(otmp2, nest=1); %fill all options
    else
        if k==numel(otmp)
            error("you must enter an oset_* file for at least one found recording in otmp, or you must make dodf=1")
        end
    end

end


%%%% remove empty options structs (in case recording matches spec but not path filtering criteria) %%%%


for k = numel(o):-1:1
    if all(structfun(@isempty, o(k)))
        o(k) = [];
    end
end


%%%% finalize/organize options struct %%%%

o = structsort(o, vectype='row'); %recursively order alphabetically

try
    o = oid(o); %assign ids to options sets
catch ME
    if o(1).mn.usegit
        scopagit('discard', files={'^opt_.*_.txt$'})
    end
    error("oid failed with the following error: " + ME.message)
end

oflat = structflat(o, delim=o(1).delimflat, prefix='o'); %flatten struct for user to see options struct organization more easily; prefix used to make valid fieldnames in case o is nonscalar


end













