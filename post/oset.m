function [o, oflat] = oset(specin, opt)

% FIX: EMPTY [], '', {}, WILL INVOKE DEFAULT (ALTHOUGH EMPTY STRING ARRAY [""] WILL NOT INVOKE DEFAULT STRING ARRAY)
% edit docs_oset.m

arguments
    specin = [] % specin can be empty, or not passed as argument, and will search for file using fspc* below; specin can be full path to filename, or cell array of one or multiple full paths to filename(s); if you just want access to params and do not want to search for files, make files=0
    opt.files = 1 % find recordings using specin (or o.spec, if specin is empty) 
end
files = opt.files;

%%%% user-defined recording specifiers (if no input to a2p) %%%%

otmp.spec.pthparent_local = '~/stacks';
otmp.spec.pthparent_o2 = ''; %can leave blank if you keep experimental folders in the same folder that pthparent_local ends with; a2p will automatically find it; otherwise fill this in for use on o2
if isempty(specin) %if you're running a2p without input arguments (ie if specin is empty), set recording specifiers here to find files; any missing fields will get defaults in odf; if not specin is not empty and is not struct (ie if char or cell of file paths, with optional wildcards), will not use these specifiers
    otmp.spec.recdate = {'20230627'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.fly = {'*'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.trial = {'*'}; %cell array of char (or scalar char), can use wildcards
    otmp.spec.suffix = {'cmrg_dcdn'}; %cell array of char (or scalar char), can use wildcards, scopa 'pre' pipeline output filename suffix to use in this 'post' pipeline (or 'raw' for raw tif output by scanimage/flyg, which does not necessarily have filename suffix 'raw'); valid suffixes are defined in suffixvalid
    otmp.spec.match = 'each'; %'any' or 'each'; 'sany' for all combinations of recdate, fly, trial, suffixstack, 'each' for matched indices of each (length 1 will be repeated to match anything longer)
    otmp.spec.pth = '';
elseif iscell(specin) || ischar(specin) %if input to a2p is not empty, and is not struct
    otmp.spec.pth = specin;
end

otmp = odf(otmp, files=files); %find files (if files=1), add them to struct o

recs_ganopb = {'202306', '20241208_2'};
recs_ganoeb = {'202311', '202411', '20241207'};
recs_t5 = {'2211'};

for k = 1:numel(otmp) %loop over found files, setting options depending on recording

    if contains(otmp(k).id.pthstack, recs_ganopb)

        o(k) = oset_ganopb(otmp(k));

    elseif contains(otmp(k).id.pthstack, recs_ganoeb)

        o(k) = oset_ganopb(otmp(k));

    elseif contains(otmp(k).id.pthstack, recs_t5)

        o(k) = oset_t5(otmp(k));

    end

end


%%%% organize %%%%

o = structsort(o, vectype='row'); %recursively order alphabetically

o = opt2id(o, 'roi');

oflat = structflat(o, prefix='o'); %get flattened struct for user to see options struct organization more easily (oflat does not get used); need prefix to make valid fieldnames in case nonscalar

end













