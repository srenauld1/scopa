function [o, oflat] = oset(specin, opt)

% FIX: EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
% edit docs_oset.m

arguments
    specin = [] % specin can be empty, or not passed as argument, and will search for file using fspc* below; specin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, make files=0
    opt.files = 1 % find recordings using specin (or o.spec, if specin is empty)
end
files = opt.files;


%%%% USER NAME (to route to different oset_* files below) %%%%

user = 'carl';


%%%% path to scopa in different filesystems (used to prevent conflicts in writing to file; valid filesystem ids are a,b,c,d,e,f,g,h) %%%%

otmp.mn.pthscopas.a = fullfile(filesep, 'Users', 'wienecke', 'scopa', filesep); %path to scopa in filesystem a 
otmp.mn.pthscopas.b = fullfile(filesep, 'home', 'caw846', 'scopa', filesep); %path to scopa in filesystem b 
otmp.mn.pthscopas.c = fullfile('C:\', 'Users', 'Wilson_Lab', 'Documents', 'GitHub', 'scopa', filesep); %path to scopa in filesystem c 
otmp.mn.pthpy = fullfile(filesep, 'Users', 'wienecke', 'miniforge3', 'envs', 'caiman', 'bin', 'python3'); %path to python executable (if you want to run any python function from a2p, like mdsisv.py, or register.py, extract.py) 

%%%% user-defined recording specifiers (used to find recordings if there is no input to a2p) %%%%

otmp.spec.pthparent_local = '/Users/wienecke/stacks';
otmp.spec.pthparent_o2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparent_local ends with; a2p will automatically find it; otherwise fill this in for use on o2
if isempty(specin) %if you're running a2p without input arguments (ie if specin is empty), set recording specifiers here to find files; any missing fields will get defaults in odf; if not specin is not empty and is not struct (ie if char or cell of file paths, with optional wildcards), will not use these specifiers
    otmp.spec.recdate = {'20241218'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.fly = {'*'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.trial = {'*'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.suffix = {'cmrg'}; %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in suffixvalid
    otmp.spec.match = 'each'; %'any' or 'each'; 'sany' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
    otmp.spec.pth = '';
elseif iscell(specin) || ischar(specin) %if input to a2p is not empty, and is not struct
    otmp.spec.pth = specin;
end


otmp = odf(otmp, files=files); %find files (if files=1), add them to struct otmp



%%%% loop over found files in otmp, setting options depending on recording (and user) %%%%

for k = 1:numel(otmp) 

    if strcmp(user, 'wenyi')
        
        recs_wenyi = {''}; %empty string means every recording

        if contains(otmp(k).id.pthstack, recs_wenyi)

            o(k) = oset_wenyi(otmp(k));

        end

    elseif strcmp(user, 'jingxuan')
        
        recs_jingxuan = {''}; %empty string means every recording

        if contains(otmp(k).id.pthstack, recs_jingxuan)

            o(k) = oset_jingxuan(otmp(k));

        end

    elseif strcmp(user, 'carl')

        recs_ganopb = {'202306', '20241208_2'};
        recs_ganoeb = {'202311', '202411', '20241207'};
        recs_fb8c = {'20241209', '20241221', '20241222'};
        recs_mito = {'mito'};
        recs_t5 = {'2211'};

        if contains(otmp(k).id.pthstack, recs_ganopb)

            o(k) = oset_ganopb(otmp(k));

        elseif contains(otmp(k).id.pthstack, recs_ganoeb)

            o(k) = oset_ganoeb(otmp(k));

        elseif contains(otmp(k).id.pthstack, recs_fb8c)

            o(k) = oset_fb8c(otmp(k));

        elseif contains(otmp(k).id.pthstack, recs_mito)

            o(k) = oset_mito(otmp(k));

        elseif contains(otmp(k).id.pthstack, recs_t5)

            o(k) = oset_t5(otmp(k));

        end

    end


end



%%%% finalize and organize options struct %%%%

o = odf(o, fill=1); % final call to odf, with fill=1 to make sure o is filled

o = structsort(o, vectype='row'); %recursively order alphabetically

o = opt2id(o);

oflat = structflat(o, prefix='o'); %get flattened struct for user to see options struct organization more easily (oflat does not get used); need prefix to make valid fieldnames in case nonscalar


end













