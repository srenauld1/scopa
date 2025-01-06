function [o, oflat] = oset(specin, opt)

% FIX: EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
% edit docs_oset.m

arguments
    specin = '' % specin can be empty, or not passed as argument, and will search for file using fspc* below; specin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, make files=0
    opt.files = 1 % find recordings using specin (or o.spec, if specin is empty)
end
otmp.spec.pth = specin;
files = opt.files;


%%%% user, path to scopa in different filesystems, and python path %%%%

otmp.mn.user = 'cw'; %cw, wz, jf; (to route to different oset_* files below)
otmp.mn.pthscopas.a = fullfile(filesep, 'Users', 'wienecke', 'scopa', filesep); %path to scopa in filesystem a
otmp.mn.pthscopas.b = fullfile(filesep, 'home', 'caw846', 'scopa', filesep); %path to scopa in filesystem b
otmp.mn.pthpy = fullfile(filesep, 'Users', 'wienecke', 'miniforge3', 'envs', 'caiman', 'bin', 'python3'); %path to python executable (if you want to run any python function from a2p, like mdsisv.py, or register.py, extract.py)

%%%% recording specifiers (used to find recordings if there is no input to a2p) %%%%

otmp.spec.pthparent_local = fullfile(filesep, 'Users', 'wienecke', 'stacks', filesep);
otmp.spec.pthparent_o2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparent_local ends with; a2p will automatically find it; otherwise fill this in for use on o2
if isempty(otmp.spec.pth) %if you're running a2p without input arguments (ie if otmp.spec.pth is empty), set recording specifiers here to find files; any missing fields will get defaults in odf; if not otmp.spec.pth is not empty and is not struct (ie if char or cell of file paths, with optional wildcards), will not use these specifiers
    otmp.spec.recdate = {'20230627'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.fly = {'2'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.trial = {'2'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.suffix = {'raw'}; %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in suffixvalid
    otmp.spec.substr = {'*'}; %cell array of char (or scalar char), can use wildcards, substring contained in path to stack (e.g. if all recordings from one campaign are in a subfolder with a descriptive name, you could put that name here, and asterisks for recdate, fly, trial, and get all those recordings just with the substr)
    otmp.spec.match = 'each'; %'any' or 'each'; 'sany' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
end


otmp = odf(otmp, files=files); %find files (if files=1), add them to struct otmp



%%%% loop over found files in otmp, setting options depending on recording (and user) %%%%

for k = 1:numel(otmp)

    switch otmp(1).mn.user

        case 'wz'

            if contains(otmp(k).id.pthstack, {''}) %empty string means every recording

                o(k) = oset_wenyi(otmp(k));

            end

        case 'jf'

            if contains(otmp(k).id.pthstack, {''}) %empty string means every recording

                o(k) = oset_jingxuan(otmp(k));

            end

        case 'cw'

            if contains(otmp(k).id.pthstack, {'ganopb'})

                o(k) = oset_ganopb(otmp(k));

            elseif contains(otmp(k).id.pthstack, {'ganoeb'})

                o(k) = oset_ganoeb(otmp(k));

            elseif contains(otmp(k).id.pthstack, {'fb8c'})

                o(k) = oset_fb8c(otmp(k));

            elseif contains(otmp(k).id.pthstack, {'mito'})

                o(k) = oset_mito(otmp(k));

            elseif contains(otmp(k).id.pthstack, {'312'})

                o(k) = oset_312(otmp(k));
                            
            elseif contains(otmp(k).id.pthstack, {'f91g'})

                o(k) = oset_t5(otmp(k));

            end

    end


end


%%%% remove empty options structs (in case recording matches otmp.spec but not contains* criterion) %%%%

rmidx = [];
for k = 1:numel(o)
    if all(structfun(@isempty, o(k)))
        rmidx = [rmidx k];
    end
end
o(rmidx) = []; %remove empty


%%%% finalize/organize options struct %%%%

o = structsort(o, vectype='row'); %recursively order alphabetically

o = opt2id(o);

oflat = structflat(o, prefix='o'); %get flattened struct for user to see options struct organization more easily (oflat does not get used); need prefix to make valid fieldnames in case nonscalar


end













