function [o, oflat] = oset(specin, opt)

%{
see docs_oset.m
FIX: EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
FIX: NONFUNCTIONAL (PLOTTING) OPTIONS ARE CURRENTLY ALL IN SEPARATE VBIN, SO OID EASILY DEALS WITH THEM, BUT CAN THIS ALWAYS BE THE CASE? what about redundant vbins that get removed in ored, they aren't returned, is that a problem? should options leaving oset always have same fields?? 
FIX: ORED NEEDS TO REMOVE NONFUNCTIONAL VBIN AT ANY NESTING 
when constructing o, you can only append vbin or option listed in odfsv;
options can be structs themselves, but defaults for all fields have to be defined oin odfsv
the only time a struct can appear within an option is struct tg, which
has special handling in odf

**** NB: DO NOT USE CELLS UNLESS YOU INTEND THEM FOR DISTRIBUTION****

%}

arguments
    specin = '' % specin can be empty, or not passed as argument, and will search for file using fspc* below; specin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, make files=0
    opt.files = 1 % find recordings using specin (or o.spec, if specin is empty)
end
otmp.spec.pth = specin;
files = opt.files;

%%%% user, path to your scopa in different filesystems, and python path %%%%

dodf = 0; %set to 1 use all defaults (do not enter any oset_* file)

otmp.mn.user = 'sophia'; %cw, wz, jf, yz, sr; (to route to different oset_* files below)
otmp.mn.pthscopas.a = fullfile(filesep, 'Users', 'sophiarenauld', 'scopa', filesep); %path to your scopa in filesystem a, for example, for carl fullfile(filesep, 'Users', 'wienecke', 'scopa', filesep)
otmp.mn.pthscopas.b = fullfile(filesep, 'home', 'caw846', 'scopa', filesep); %path to your scopa in filesystem b, for example, for carl fullfile(filesep, 'home', 'caw846', 'scopa', filesep)
otmp.mn.pthpy = fullfile(filesep, 'Users', 'wienecke', 'miniforge3', 'envs', 'caiman', 'bin', 'python3'); %path to python executable (if you want to run any python function from a2p, like mdsisv.py, or register.py, extract.py)

%%%% recording specifiers (used to find recordings if there is no input to a2p) %%%%

otmp.spec.pthparent_local = fullfile(filesep, 'Users', 'sophiarenauld', 'stacks', filesep);
otmp.spec.pthparent_o2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparent_local ends with; a2p will automatically find it; otherwise fill this in for use on o2
if isempty(otmp.spec.pth) %if you're running a2p without input arguments (ie if otmp.spec.pth is empty), set recording specifiers here to find files; any missing fields will get defaults in odf; if not otmp.spec.pth is not empty and is not struct (ie if char or cell of file paths, with optional wildcards), will not use these specifiers
    otmp.spec.recdate = {'20250327'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.fly = {'5'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.trial = {'*'}; %cell ara2ray of char (or scalar char), can use wildcards
    otmp.spec.suffix = {'cmrg'}; %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in suffixvalid
    otmp.spec.substr = {'*'}; %cell array of char (or scalar char), can use wildcards, substring contained in path to stack (e.g. if all recordings from one campaign are in a subfolder with a descriptive name, you could put that name here, and asterisks for recdate, fly, trial, and get all those recordings just with the substr)
    otmp.spec.match = 'each'; %'any' or 'each'; 'sany' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
end


otmp = odf(otmp, files=files); %find files (if files=1), add them to struct otmp


%%%% loop over found files in otmp, setting options depending on recording (and user) %%%%

for k = 1:numel(otmp)

    otmp2 = [];
    if dodf

        otmp2 = otmp(k);

    else

        switch otmp(1).mn.user

            case 'wz'

                if contains(otmp(k).id.pthstack, {''}) %empty string means every recording

                    otmp2 = oset_wenyi(otmp(k));

                end

            case 'jf'

                if contains(otmp(k).id.pthstack, {''}) %empty string means every recording

                    otmp2 = oset_jingxuan(otmp(k));

                end

            case 'yz'

                if contains(otmp(k).id.pthstack, {''}) %empty string means every recording

                    otmp2 = oset_yunzhi(otmp(k));

                end

            case 'sophia'

                if contains(otmp(k).id.pthstack, {''}) %empty string means every recording

                    otmp2 = oset_sophia(otmp(k));

                end

            case 'cw'

                if contains(otmp(k).id.pthstack, {'ganopb'})

                    otmp2 = oset_ganopb(otmp(k));

                elseif contains(otmp(k).id.pthstack, {'ganoeb'})

                    otmp2 = oset_ganoeb(otmp(k));
                    
                elseif contains(otmp(k).id.pthstack, {'noel'})

                    otmp2 = oset_noel(otmp(k));

                elseif contains(otmp(k).id.pthstack, {'noeb'}) && ~contains(otmp(k).id.pthstack, {'ganoeb'})

                    otmp2 = oset_noeb(otmp(k));

                elseif contains(otmp(k).id.pthstack, {'fb8c'})

                    otmp2 = oset_fb8c(otmp(k));

                elseif contains(otmp(k).id.pthstack, {'mito'})

                    otmp2 = oset_mito(otmp(k));

                elseif contains(otmp(k).id.pthstack, {'312'})

                    otmp2 = oset_312(otmp(k));

                elseif contains(otmp(k).id.pthstack, {'f91g'})

                    otmp2 = oset_t5(otmp(k));

                end

        end

    end

    if ~isempty(otmp2)
        o(k) = odf(otmp2, fill=1); %fill all options
    else
        if k==numel(otmp)
            error("you must enter an oset_* file for at least one found recording in otmp, or you must make dodf=1")
        end
    end

end


%%%% remove empty options structs (in case recording matches otmp.spec but not contains* criterion) %%%%

for k = numel(o):-1:1
    if all(structfun(@isempty, o(k)))
        o(k) = [];
    end
end


%%%% finalize/organize options struct %%%%

o = structsort(o, vectype='row'); %recursively order alphabetically

o = oid(o); %assign id to options sets, if multiple requested with cell array options

oflat = structflat(o, prefix='o'); %get flattened struct for user to see options struct organization more easily (oflat does not get used); need prefix to make valid fieldnames in case nonscalar


end













