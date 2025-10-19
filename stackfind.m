function pthstacks = stackfind(opt)

% error message about duplicate specifier can be wrong for unusual cases where same specifiers match files in different locations with different extensions (in this case they pass in choose_ext as different files, and are found to have the same specifier by check_for_duplicate_specifiers

arguments
    opt.pthpat = 0 %full path pattern, can have wildcards (single wildcard * means 0 or more characters, but does not include file separators, or cross file separators; double wildcard ** means 0 or more folders, and must be between file separators); if you use pthpat, you cannot use stackid, recdate, fly, trial, suffix, ext, or substr inputs
    opt.pthpar = [] %path to parent folder containing all stacks (this function searches for stacks recursively within pthpar) 
    opt.stackid = [] %char, format recdate_fly_trial_suffix; can include wildcards; can truncate full stackid format with wildcard * and wildcard * gets copied to each subsequent underscore-delimited label (eg, 2025* is equivalent to 2025*_*_*_*); cannot use stackid if any of pthpat, recdate, fly, trial, or suffix are nonempty
    opt.recdate = []%char or number, alone or in cell
    opt.fly = [] %char or number, alone or in cell
    opt.trial = []%char or number, alone or in cell
    opt.suffix = [] %char, from suffixchar_raw and suffixchars
    opt.substr = [] %char, portion of path (for example, a folder in the path) to restrict results
    opt.match = 'each' %'any' to search all combinations of recdate, fly, trial, suffix, substr; 'each' to search each matched index of recdate, fly, trial, suffix, substr
    opt.ext = [] % 'mat', 'tif', 'both', or 'or'; only used if if pthpat is empty, in which case default is 'or'; 'both' will return mat and tif files, even if they are for the same stack; 'mat' will return only mat files; 'tif' will return only tif files; 'or' will return mat files if tif and mat files, or only mat files, are found, and will return tif files if only tif files are found;
    opt.suffixchar_raw = 'o'; %stack suffix character for original/raw scanimage output files, also first character on processed stacks; for flyg users, except carl, original scanimage output files will not actually have suffix 'o' (they are named with flyg convention); carl renames the flyg/scanimage original files with suffix 'o'
    opt.suffixchars = {'r', 'd', 'b', 's'}; %all valid stack suffix characters output by scopa preprocessing pipeline (pl.py, pl.sh); r=registered, d=denoised, b=background-subtracted, s=scannoise-removed; can appear in any order, multiple times; suffix denotes preprocessing steps applied to stack; suffixchar_raw (defined above) can only appear once, at the beginning of the suffix (e.g., ord means registered then denoised, o alone means original/unprocessed)
    opt.err = 0 %error if no stacks found
    opt.cellout = 0 %1 to force cell output, even when only one path is found; if 0, output is cell if multiple paths, and char vector if single path; regardless of cellout value, output is empty [] if no paths are found
end
pthpat = opt.pthpat;
pthpar = opt.pthpar;
stackid = opt.stackid;
recdate = opt.recdate;
fly = opt.fly;
trial = opt.trial;
suffix = opt.suffix;
substr = opt.substr;
match = opt.match;
ext = opt.ext;
suffixchar_raw = opt.suffixchar_raw;
suffixchars = opt.suffixchars;
err = opt.err;
cellout = opt.cellout;

optid = 'z0'; %hard coding for now, see comments by optid_sld_suffix below
optid_sld_suffix = [optid '_sld_']; %for now, hard coding this because stacks are not under id-control, and this can be omitted for convenience for people using old naming
optid_sld_suffix_flygraw = ['_' optid_sld_suffix]; %add leading underscore

disallow_same_filename_in_different_dir = 0; %error if same filename is found in different locations

validtext = @(x) ~iscellnested(x) && ( isemptyall(x) || ischar(x) || ( iscell(x) && all(cellfun(@ischar, x)) ) );
validtextornum = @(x) ~iscellnested(x) && ( isemptyall(x) || ischar(x) || isnumeric(x) || ( iscell(x) && all(cellfun(@ischar, x)) ) || ( iscell(x) && all(cellfun(@isnumeric, x)) ) );

if ~validtext(stackid) || ~validtext(suffix) || ~validtext(substr)
    error("stackid, suffix, and substr must be char or cell of char")
end
if ~validtextornum(recdate) || ~validtextornum(fly) || ~validtextornum(trial)
    error("recdate, fly, and trial must be char or number or cell of char or cell of number")
end

suffixchar_raw = convertStringsToChars(suffixchar_raw);
suffixchars = convertStringsToChars(suffixchars);
if ~iscell(suffixchars) && ~isempty(suffixchars)
    suffixchars = {suffixchars};
end

if isempty(suffixchar_raw) || sum(strlength(suffixchars))==0 
    error("no variable set for suffixchar_raw, returned files may include more than you want if specifiers include wildcard, so you must set suffixchar_raw" + newline)
end
if isempty(suffixchars) || sum(strlength(suffixchars))==0 %sum(strlength(suffixchars))==0 will test for empty char or string
    error("no variable set for suffixchars, returned files may include more than you want if specifiers include wildcard, so you must set suffixchars" + newline)
end

valid_tif_fn_regexppat = ['^\d*_\d*_\d*_' suffixchar_raw '(' strjoin(strcat(suffixchars, '*'), '') ')*_.tif$']; %for now, optid_sld_suffix does not exist for tif files because stack preprocessing options are not id-controlled 
valid_mat_fn_regexppat = regexprep(valid_tif_fn_regexppat, '.tif\$', [optid_sld_suffix '.mat$']);
valid_flygrawtif_fn_regexppat = '^\d*-\d*_.*_trial_.*_\d{5}.tif$';
valid_flygrawmat_fn_regexppat = regexprep(valid_flygrawtif_fn_regexppat, '.tif\$', [optid_sld_suffix_flygraw '.mat$']);

if isemptyall(ext)
    if isemptyall(pthpat)
        ext = 'or';
    end
else
    if ~isemptyall(pthpat)
        error("cannot specify nonempty ext with nonempty pthpat input")
    end
    if ~ismember(ext, {'mat', 'tif', 'both', 'or'})
        error("ext must be 'mat', 'tif', 'both', or 'or'")
    end
end

if ~isemptyall(pthpat)
    if ~isemptyall(stackid) || ~isemptyall(recdate) || ~isemptyall(fly) || ~isemptyall(trial) || ~isemptyall(suffix) || ~isemptyall(ext) || ~isemptyall(substr)
        error("cannot use stackid, recdate, fly, trial, suffix, ext, or substr inputs with nonempty pthpat input")
    end
    if ~iscell(pthpat)
        pthpat = {pthpat};
    end
    pthpat = strrep(pthpat, '/', filesep);
    pthpat = strrep(pthpat, '\', filesep);
elseif ~isemptyall(stackid)
    if ~isemptyall(pthpat) || ~isemptyall(recdate) || ~isemptyall(fly) || ~isemptyall(trial) || ~isemptyall(suffix)
        error("cannot use pthpat, recdate, fly, trial, or suffix inputs with nonempty stackid input (substr is allowed, however)")
    end
    if ~iscell(stackid)
        stackid = {stackid};
    end
    for k = 1:numel(stackid)
        spl = strsplit(stackid{k}, '_');
        if endsWith(spl(end), '*')
            spl(numel(spl)+1:4) = {'*'};
        else
            if numel(spl)<4
                error("stackid must have 3 underscores, or end with wildcard *");
            end
        end
        recdate{k} = spl{1};
        fly{k} = spl{2};
        trial{k} = spl{3};
        suffix{k} = spl{4};
    end
end

recdate = cellchar(recdate); %in case numeric
fly = cellchar(fly); %in case numeric
trial = cellchar(trial); %in case numeric
suffix = cellchar(suffix); %in case numeric
substr = cellchar(substr); %in case numeric


if isemptyall(pthpat)

    if isempty(pthpar)
        pthpar = pthparget();
    end

    fspc = expand_fn_specifiers(match, recdate, fly, trial, suffix, substr);

    pth_prefix_all = {};
    for k = 1:numel(fspc.recdate)
        pth_prefix_all_onespec = stackfind_onespec(fspc.recdate{k}, fspc.fly{k}, fspc.trial{k}, fspc.suffix{k}, fspc.substr{k}, pthpar, valid_tif_fn_regexppat, valid_mat_fn_regexppat, valid_flygrawtif_fn_regexppat, valid_flygrawmat_fn_regexppat);
        pth_prefix_all = cat(1, pth_prefix_all, pth_prefix_all_onespec(:));
    end

    pthstacks = choose_ext(pth_prefix_all, ext, optid_sld_suffix, optid_sld_suffix_flygraw); %keep mat and remove tif if they are for the same recording

else %if full path input (wildcards allowed)

    pthstacks = {};
    for k = 1:numel(pthpat)
        pthtmptif = filefilt(pthpat{k}, valid_tif_fn_regexppat, substr);
        pthtmpmat = filefilt(pthpat{k}, valid_mat_fn_regexppat, substr);
        pthtmpflygrawtif = filefilt(pthpat{k}, valid_flygrawtif_fn_regexppat, substr);
        pthtmpflygrawmat = filefilt(pthpat{k}, valid_flygrawmat_fn_regexppat, substr);
        pthstacks = cat(1, pthstacks, pthtmptif, pthtmpmat, pthtmpflygrawtif, pthtmpflygrawmat);
    end

end

if isempty(pthstacks)
    if isemptyall(pthpat)
        for k = 1:numel(fspc.recdate)
            fspcstr = sprintf("pthpar: " + pthpar + newline + "recdate: " + fspc.recdate{k} + newline + "fly: " + fspc.fly{k} + newline + "trial: " + fspc.trial{k} + newline + "suffix: " + fspc.suffix{k} + newline + "substr: " + fspc.substr{k});
            fprintf(newline + "WARNING, NO FILES FOUND WITH match '" + match + "' AND FILENAME SPECIFIERS:" + newline + fspcstr + newline)
        end
    else
        fprintf(newline + "WARNING, NO FILES FOUND MATCHING INPUT PATHS OR PATH PATTERNS" + newline)
    end
    pthstacks = [];
else
    check_for_duplicate_specifiers(pthstacks); %why do we care about this if we have check_for_duplicate_filenames (and that doens't even matter)?
    check_for_duplicate_filenames(pthstacks, disallow_same_filename_in_different_dir);
end

if isscalar(pthstacks) && ~cellout
    pthstacks = pthstacks{1};
end

if ~isequal(err, 0) && isempty(pthstacks)
    error("NO STACKS FOUND WITH YOUR STACK SPECIFIERS IN pthpar " + pthpar + newline)
end


end





function fspc = expand_fn_specifiers(match, recdate, fly, trial, suffix, substr)

if strcmp(match, 'any')
    fspc = combinations(recdate, fly, trial, suffix, substr);
elseif strcmp(match, 'each')
    specnums = [numel(recdate), numel(fly), numel(trial), numel(suffix), numel(substr)];
    uniquespecnums = unique(specnums);
    if numel(uniquespecnums(uniquespecnums~=1))>1
        error("for file matching style 'each' specifiers must have same length, or length 1")
    end
    maxspecnum = max(specnums);
    if isscalar(recdate)
        recdate = repelem(recdate, maxspecnum);
    end
    if isscalar(fly)
        fly = repelem(fly, maxspecnum);
    end
    if isscalar(trial)
        trial = repelem(trial, maxspecnum);
    end
    if isscalar(suffix)
        suffix = repelem(suffix, maxspecnum);
    end
    if isscalar(substr)
        substr = repelem(substr, maxspecnum);
    end
    fspc.recdate = recdate;
    fspc.fly = fly;
    fspc.trial = trial;
    fspc.suffix = suffix;
    fspc.substr = substr;
end

end


function pth_prefix_all = stackfind_onespec(recdate, fly, trial, suffix, substr, pthpar, valid_tif_fn_regexppat, valid_mat_fn_regexppat, valid_flygrawtif_fn_regexppat, valid_flygrawmat_fn_regexppat)

%%SCOPA PATTERN, TIF AND MAT
ui_tif_fn_rdirpat = [pthpar '**' filesep recdate '_' fly '_' trial '_' suffix '_.tif']; %double asterisk is 0 or more directories
pth_all_tif = filefilt(ui_tif_fn_rdirpat, valid_tif_fn_regexppat, substr);

ui_mat_fn_rdirpat = regexprep(ui_tif_fn_rdirpat, '.tif$', '.mat');
pth_all_mat = filefilt(ui_mat_fn_rdirpat, valid_mat_fn_regexppat, substr);

%%FLYG RAW PATTERN, TIF AND MAT
if strcmp(suffix, 'o') || strcmp(suffix, 'o*') || strcmp(suffix, '*')
    if strcmp(trial, '*')
        ui_flygrawtif_fn_rdirpat = [pthpar '**' filesep recdate '-' fly '_*_trial_*_*.tif']; %double asterisk is 0 or more directories
    else
        ui_flygrawtif_fn_rdirpat = [pthpar '**' filesep recdate '-' fly '_*_trial_' sprintf( '%03s', trial ) '_*.tif']; %double asterisk is 0 or more directories
    end
    pth_all_flyg_raw_tif = filefilt(ui_flygrawtif_fn_rdirpat, valid_flygrawtif_fn_regexppat, substr);

    ui_flygrawmat_fn_rdirpat = regexprep(ui_flygrawtif_fn_rdirpat, '.tif$', '.mat');
    pth_all_flyg_raw_mat = filefilt(ui_flygrawmat_fn_rdirpat, valid_flygrawmat_fn_regexppat, substr);
else
    pth_all_flyg_raw_tif = [];
    pth_all_flyg_raw_mat = [];
end

pth_prefix_all = cat(1, pth_all_tif, pth_all_mat, pth_all_flyg_raw_tif, pth_all_flyg_raw_mat); %ALL POSSIBLE PATTERNS
pth_prefix_all = unique(cellfun(@(x) x(1:end-4), pth_prefix_all, 'UniformOutput', false)); %unique files, whether tif or mat (will not find duplicates with one scopa and one flyg filename)

end


function pthstacks = choose_ext(pth_prefix_all, ext, optid_sld_suffix, optid_sld_suffix_flygraw)

pthstacks = {};
for k = 1:numel(pth_prefix_all)
    [~, fn, ~] = fileparts(pth_prefix_all{k});
    if contains(fn, 'trial_') && contains(fn, '-')
        tmpmat = [pth_prefix_all{k} optid_sld_suffix_flygraw '.mat'];
    else
        tmpmat = [pth_prefix_all{k} optid_sld_suffix '.mat'];
    end
    tmptif = [pth_prefix_all{k} '.tif']; %for now, for symmetry and clarity, making this empty dummy version of optid_sld_suffix, regexprep(optid_sld_suffix, '.*', ''), so we don't forget to replace with real version when optid exists for stack preprocessing
    if isfile(tmpmat) && ~strcmp(ext, 'tif')
        pthstacks = cat(1, pthstacks, tmpmat);
    end
    if isfile(tmptif) && ~strcmp(ext, 'mat') && ~( strcmp(ext, 'or') && isfile(tmpmat) )
        pthstacks = cat(1, pthstacks, tmptif);
    end
end

end



function check_for_duplicate_specifiers(pthstacks)

tmp = [];
for k = 1:numel(pthstacks)
    id = idmake(pthstacks{k});
    tmp{k} = [id.recdate '_' id.fly '_' id.trial '_' id.suffix '_' id.ext];
end
if numel(tmp)~=numel(unique(tmp))
    fprintf([sprintf(['there are at least two found files with the same extension and same specifiers: date, fly, trial, and suffix ' ...
        '(note suffix is "o" for original stack, whether named with flyg or scopa format); ' ...
        'be sure duplicate specifiers belong to different recordings (e.g. in different locations, which can be distinguished with specifier "substr"); ' ...
        'here are all found stacks: ']), newline, sprintf('%s \n', pthstacks{:})])
end

end



function check_for_duplicate_filenames(pth_prefix_all, disallow_same_filename_in_different_dir)

pthscheck = cellfun(@(x,y) strsplit(x,y), pth_prefix_all, repmat({filesep}, numel(pth_prefix_all), 1), 'UniformOutput', false);
justfns = cellfun(@(x) x(end), pthscheck);
[jp, ~, kp2] = unique(justfns, 'stable');
yy = hist(kp2,unique(kp2));
jp = jp(yy>1);

if ~isempty(cell2mat(jp'))
    pthdupes = pth_prefix_all(contains(pth_prefix_all, jp));
    if disallow_same_filename_in_different_dir
        error(sprintf([sprintf('repeated filenames in different locations, \nmove or rename or set error_on_repeat_filenames to 0 in local function check_for_duplicate_filenames in function stackfind.m; \nrepeated filenames are: '), newline, sprintf('%s \n', pthdupes{:})]))
    else
        fprintf([sprintf('repeated filenames in different locations; be sure duplicate specifiers belong to different recordings (e.g. in different locations, which can be distinguished with specifier "substr"); here are all found stacks:'), newline, sprintf('%s \n', pthdupes{:})])
    end
end

end


function x = cellchar(x)

if ~iscell(x)
    x = {x};
end
for k = 1:numel(x)
    if isempty(x{k})
        x{k} = '*';
    else
        x{k} = num2str(x{k});
    end
end

end


function pth_all = filefilt(input_fn_pat, valid_fn_pat, substr)

pth_all = rdir(input_fn_pat);
pth_all = {pth_all.name};
[~, fn_all_tif, fn_ext] = fileparts(pth_all);
fn_all_tif = strcat(fn_all_tif, fn_ext);
pth_all = pth_all(~cellfun(@isempty, regexp(fn_all_tif, valid_fn_pat))); %in case wildcard suffix returns unwanted files
pth_all = pth_all(~cellfun(@isempty, regexp(pth_all, regexptranslate('wildcard', substr))));
pth_all = pth_all(:); %make it column vector

end
