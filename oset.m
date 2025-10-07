function [o, oflat] = oset(spec, opt)

%{

wrapper for the following functions:
    --stackfind: find imaging stacks
    --oset_*: set options (can be specific to stack)
    --oid: give each options set a unique id

see docs_oset.m for more detail

**** NB: DO NOT USE CELLS FOR OPTIONS IN OSET_* FILES UNLESS YOU INTEND THEM FOR DISTRIBUTION IN OID ****

%}

arguments
    spec = [] % spec struct (see function stackfind), or char or cell of char specifying full path to stack(s); if the latter, can have wildcards *; if empty, will search for file using spec below;
    opt.usegit = 0; %1 to use git to sync with scopa remote repository to ensure opt files (and consequently, optid and varid) are integrated across filesystems; 0 to skip git
end
usegit = opt.usegit;

clear ofill

%%%% MAKE SURE userdat.txt HAS BEEN SET %%%%

userdatfile()

%%%% RECORDING SPECIFIERS (USED TO FIND RECORDINGS IF THERE IS NO INPUT TO a2p) %%%%


if isempty(spec) %if you're running a2p without input arguments (ie if optional input 'spec' is empty), set specifiers here to find stack(s); any missing fields will get defaults in ofill; if spec is not empty, these specifiers are ignored
    spec.pth = {''}; %full path pattern, can have wildcards; if you use pth, you cannot use stackid, recdate, fly, trial, suffix, or substr (single wildcard * means 0 or more characters, but does not include file separators, or cross file separators; double wildcard ** means 0 or more folders, and must be between file separators);
    spec.stackid = {'20250930_3*'}; %char, format recdate_fly_trial_suffix; can include wildcards; can truncate full stackid format with wildcard * and wildcard * gets copied to each subsequent underscore-delimited label (eg, 2025* is equivalent to 2025*_*_*_*); cannot use stackid if any of pth, recdate, fly, trial, or suffix are nonempty
    spec.recdate = {'*'}; %cell array of char (or char vector), can use wildcards; empty will find any (equivalent to '*')
    spec.fly = {'*'}; %cell array of char (or char vector), can use wildcards; empty will find any (equivalent to '*')
    spec.trial = {'*'}; %cell ara2ray of char (or char vector), can use wildcards; empty will find any (equivalent to '*')
    spec.suffix = {'*'}; %cell array of char (or char vector), can use wildcards, stack filename suffix to use; valid suffixes are defined in odf, d.spec.suffixchar_raw and d.spec.suffixchars; empty will find any (equivalent to '*')
    spec.substr = {'*'}; %cell array of char (or char vector), can use wildcards, substring contained in path to stack (e.g. if all recordings from one campaign are in a subfolder with a descriptive name, you could put that name here, and asterisks for recdate, fly, trial, and get all those recordings just with the substr); empty will find any (equivalent to '*')
    spec.match = 'each'; %'any' or 'each'; 'any' for all combinations of recdate, fly, trial, suffix; 'each' for matched indices of each of these specifiers (length 1 will be repeated to match anything longer)
    spec.pthpar = userdatfile('pthpar'); %read pthpar from userdatfile
elseif istextall(spec)
    spec.pth = spec;
end

spectmp = struct2pairs(spec);
pthstacks = stackfind(spectmp{:}, err=1); % find stacks using spec; error if none found (err=1)
idtmp = idmake(pthstacks);

%%%% LOOP OVER FOUND STACKS IN idtmp, SETTING OPTIONS (IN oset_* FILES) SPECIFIC TO RECORDING AND SCOPAUSERNAME %%%%

for k = 1:numel(idtmp)

    clear ofill %clear persistent variables in ofill on each loop
    opttmp = [];  %if we don't enter any oset_* file below, empty opttmp will invoke all default options when passed into ofill

    switch userdatfile('scopausername')

        case 'wz'

            if contains(idtmp(k).pthstack, {''}) %empty string means every recording

                opttmp = oset_wenyi();

            end

        case 'jf'

            if contains(idtmp(k).pthstack, {''}) %empty char for no path filtering

                opttmp = oset_jingxuan();

            end

        case 'yz'

            if contains(idtmp(k).pthstack, {''}) %empty char for no path filtering

                opttmp = oset_yunzhi();

            end

        case 'sr'

            if contains(idtmp(k).pthstack, {''}) %empty char for no path filtering

                opttmp = oset_sophia();

            end

        case 'cw'

            if contains(idtmp(k).pthstack, {'ebganoo'})

                opttmp = oset_ebgano();

            elseif contains(idtmp(k).pthstack, {'ganopb'})

                opttmp = oset_ganopb();

            elseif contains(idtmp(k).pthstack, {'elno'})

                opttmp = oset_elno();

            elseif contains(idtmp(k).pthstack, {'ebno'})

                opttmp = oset_ebno();

            elseif contains(idtmp(k).pthstack, {'opto'})

                opttmp = oset_opto();

            elseif contains(idtmp(k).pthstack, {'fb8c'})

                opttmp = oset_fb8c();

            elseif contains(idtmp(k).pthstack, {'mito'})

                opttmp = oset_mito();

            elseif contains(idtmp(k).pthstack, {'312'})

                opttmp = oset_312();

            elseif contains(idtmp(k).pthstack, {'f91g'})

                opttmp = oset_t5();

            end

    end

    o(k) = ofill(opttmp, finish=1);

end


%%%% now set some globals (in glb) %%%%

glb( ...
    plt=[""], ... %string array listing modules that get plots (empty string for none by default); all would be plt=["daq", "sld", "ftv", "roi", "bmp", "mdl"]
    optiddf='z0', ... %default option id; if user doesn't use oid to map options sets to optid, optiddf is used instead (in filenames, figures, and struct names) 
    dmstackdf='yxztck', ... %default stack dimension order; if you use stackld to load the stack from tif (and save as mat), the stack is put into this order; c is stack collection channel (eg stack collected with 2 pmts makes 2 channels), k is truecolor stack's rgb channel (in general, stack is grayscale, not truecolor, so this is typically singleton), ...
    delimflat='__', ... %delimiter used to options flatten struct; set here because it's used throughout a2p and it must be consistent to prevent 
    usegit=usegit, ...
    pthscopa=pthscopaget(), ... %path to scopa
    pthpy=userdatfile('pthpy'), ... %path to python executable, in case user calls some python code from a2p (caiman registration or roi extraction, for example)
    scopausername=userdatfile('scopausername'), ... %username; must be alphabetic char vector; used in options filenames, and to route to correct oset_* files
    xyscreen=screenpx(), ... %screen dimensions in pixels
    pthpar=pthparget() ... %path to parent folder containing all stacks (function stackfind function searches for stacks recursively within pthpar) 
    )

%%%% FINALIZE/ORGANIZE OPTIONS STRUCT AND DERIVE optids %%%%

o = structsort(o, vectype='row'); %recursively order alphabetically

o = oid(o, usegit=usegit); %assign ids to options sets

for k = 1:numel(idtmp)
    o(k).id = idtmp(k); %put id (stack info) into options struct
end

oflat = structflat(o, delim=o(1).mn.delimflat, prefix='o'); %flatten struct for user to see options struct organization more easily; prefix used to make valid fieldnames in case o is nonscalar


end













