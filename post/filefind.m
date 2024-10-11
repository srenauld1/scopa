function pth_all = filefind(opt)

% error message about duplicate specifier can be wrong for unusual cases where same specifiers match files in different locations with different extensions (in this case they pass prioritize_mat as different files, and are found to have the same specifier by check_for_duplicate_specifiers

arguments
    opt.pth = [] %full path pattern (can have wildcards)
    opt.validsuffix = []
    opt.pthsib = []  %full path to a file, returned files will include all matching files in same folder, along with pthsib
    opt.pthparent_local = []
    opt.pthparent_o2 = []
    opt.recdate = []
    opt.fly = []
    opt.trial = []
    opt.suffix = []
    opt.match = 'each'
end

pth = opt.pth;
pthsib = opt.pthsib;
pthparent_local = opt.pthparent_local;
pthparent_o2 = opt.pthparent_o2;
validsuffix = opt.validsuffix;
recdate = opt.recdate;
fly = opt.fly;
trial = opt.trial;
suffix = opt.suffix;
match = opt.match;

if ~isempty(pth) && ~isempty(pthsib)
    error("cannot use pth and pthsib inputs at the same time")
end
if ~isempty(pth)
    pth = strrep(pth, '/', filesep);
    pth = strrep(pth, '\', filesep);
    if ~iscell(pth)
        pth = {pth};
    end
    if ~isempty(recdate) || ~isempty(fly) || ~isempty(trial) || ~isempty(suffix)
        error("cannot use recdate, fly, trial, or suffix inputs with pth input")
    end
end
if ~isempty(pthsib)
    pthsib = strrep(pthsib, '/', filesep);
    pthsib = strrep(pthsib, '\', filesep);
    if ~iscell(pthsib)
        pthsib = {pthsib};
    end
    if ~isempty(recdate) || ~isempty(fly) || ~isempty(trial)
        error("cannot use recdate, fly, or trial inputs with pthsib input")
    end
end



if isempty(recdate)
    recdate = '*';
end
if isempty(fly)
    fly = '*';
end
if isempty(trial)
    trial = '*';
end
if isempty(suffix)
    suffix = '*';
end
if isempty(validsuffix)
    validsuffix = glb('validsuffix');
    if isempty(validsuffix)
        sprintf('no variable set for validsuffix, returned files may include more than you want if specifiers include wildcard')
    end
end

if isempty(pth)

    if isempty(pthsib)
        pth_parent = find_parent_path(pthparent_local, pthparent_o2);
    else
        if isfile(pthsib)
            [pth_parent, ~, ~] = fileparts(pthsib);
            pth_parent = [pth_parent filesep];
            id = idmake(pthsib);
            recdate = id.recdate;
            fly = id.fly;
            trial = id.trial;
        else
            error(sprintf("the following pthsib is not a file: " + newline + pthsib))
        end
    end

    fspc = expand_fn_specifiers(match, recdate, fly, trial, suffix);

    pth_prefix_all = [];
    for j = 1:numel(fspc.recdate)
        pth_prefix_all_onespec = filefind_onespec(fspc.recdate{j}, fspc.fly{j}, fspc.trial{j}, fspc.suffix{j}, pth_parent, validsuffix);
        pth_prefix_all = cat(1, pth_prefix_all, vec(pth_prefix_all_onespec));
    end

else %if full path input (wildcards allowed)

    pth_prefix_all = {};
    for k = 1:numel(pth)
        pthtmp = rdir(pth{k});
        pthtmp = {pthtmp.name};
        pthtmptif = erase(pthtmp(contains(pthtmp, strcat(validsuffix ,'_.tif'))), '.tif');
        pthtmpmat = erase(pthtmp(contains(pthtmp, strcat(validsuffix ,'_.mat'))), '.mat');
        pth_prefix_all = unique([pth_prefix_all, pthtmptif, pthtmpmat]);
    end

end

if isempty(pth_prefix_all)
    if isempty(pth)
        fspcstr = sprintf("pth_parent: " + pth_parent + newline + "recdate: " + recdate + newline + "fly: " + fly + newline + "trial: " + trial + newline + "suffix: " + suffix);
        sprintf("WARNING, NO FILES FOUND WITH match '" + match + "' AND FILENAME SPECIFIERS:" + newline + fspcstr)
    else
        sprintf("WARNING, NO FILES FOUND MATCHING INPUT PATHS OR PATH PATTERNS")
    end
    pth_all = [];
else
    pth_all = prioritize_mat(pth_prefix_all);
    check_for_duplicate_specifiers(pth_all)
    check_for_duplicate_filenames(pth_all);
end


end





function fspc = expand_fn_specifiers(match, recdate, fly, trial, suffix)

if ~iscell(recdate)==1
    recdate = {recdate};
end
if ~iscell(fly)==1
    fly = {fly};
end
if ~iscell(trial)==1
    trial = {trial};
end
if ~iscell(suffix)==1
    suffix = {suffix};
end

if strcmp(match, 'any')
    fspc = combinations(recdate, fly, trial, suffix);
elseif strcmp(match, 'each')
    specnums = [numel(recdate), numel(fly), numel(trial), numel(suffix)];
    uniquespecnums = unique(specnums);
    if numel(uniquespecnums(uniquespecnums~=1))>1
        error("for file matching style 'each' specifiers must have same length, or length 1")
    end
    maxspecnum = max(specnums);
    if numel(recdate)==1
        recdate = repelem(recdate, maxspecnum);
    end
    if numel(fly)==1
        fly = repelem(fly, maxspecnum);
    end
    if numel(trial)==1
        trial = repelem(trial, maxspecnum);
    end
    if numel(suffix)==1
        suffix = repelem(suffix, maxspecnum);
    end
    fspc.recdate = recdate;
    fspc.fly = fly;
    fspc.trial = trial;
    fspc.suffix = suffix;
end



end


function pth_parent = find_parent_path(pthparent_local, pthparent_o2)

pthparent_local = strrep(pthparent_local, '/', filesep);
pthparent_local = strrep(pthparent_local, '\', filesep);
if endsWith(pthparent_local, filesep)
    pthparent_local = pthparent_local(1:end-1);
end
[~, fldr_parent_local, ~] = fileparts(pthparent_local);

envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    if isempty(pthparent_o2)
        sprintf("O2 parent path not specified, using default path based on parent folder name")
        pthenv = getpathenv();
        spl = strsplit(pthenv, filesep);
        username = cell2mat(spl(find(contains(spl, 'home'))+1));
        if isempty(username)
            error("scopa may not be in your O2 home folder, make sure to git clone scopa into your O2 home folder")
        end
        pth_parent = fullfile('/', 'n', 'scratch', 'users', username(1), username, fldr_parent_local);
    else
        if endsWith(pthparent_o2, filesep)
            pth_parent = pthparent_o2(1:end-1);
        end
    end
else
    pth_parent = pthparent_local;
end

pth_parent = [pth_parent filesep];
if ~isfolder(pth_parent)
    error(sprintf("pth_parent '" + pth_parent + "' DOES NOT EXIST"))
end


end


function pth_prefix_all = filefind_onespec(recdate, fly, trial, suffix, pth_parent, validsuffix)


recdate = num2str(recdate); %just in case it's numeric, won't matter if not
fly = num2str(fly); %just in case it's numeric, won't matter if not
trial = num2str(trial); %just in case it's numeric, won't matter if not


%%SCOPA PATTERN, TIF AND MAT
fn_pattern_tif = [pth_parent '**' filesep recdate '_' fly '_' trial '_' suffix '_.tif']; %double asterisk is 0 or more directories
valid_tif_fns = strcat(validsuffix, '_.tif');
pth_all_tif = rdir(fn_pattern_tif);
pth_all_tif = pth_all_tif(contains({pth_all_tif.name}, valid_tif_fns)); %in case wildcard suffix returns unwanted files

valid_mat_fns = strcat(validsuffix, '_.mat');
fn_pattern_mat = [fn_pattern_tif(1:end-4) '.mat'];
pth_all_mat = rdir(fn_pattern_mat);
pth_all_mat = pth_all_mat(contains({pth_all_mat.name}, valid_mat_fns)); %in case wildcard suffix returns unwanted files


%%FLYG RAW PATTERN, TIF AND MAT
if strcmp(suffix, 'raw')
    if strcmp(trial, '*')
        fn_pattern_flyg_raw_tif = [pth_parent '**' filesep recdate '-' fly '_*_trial_*_*.tif']; %double asterisk is 0 or more directories
    else
        fn_pattern_flyg_raw_tif = [pth_parent '**' filesep recdate '-' fly '_*_trial_' sprintf( '%03s', trial ) '_*.tif']; %double asterisk is 0 or more directories
    end
    pth_all_flyg_raw_tif = rdir(fn_pattern_flyg_raw_tif);

    fn_pattern_flyg_raw_mat = [fn_pattern_flyg_raw_tif(1:end-4) '.mat'];
    pth_all_flyg_raw_mat = rdir(fn_pattern_flyg_raw_mat); %don't need to subset by validsuffix since flygraw pattern doesn't include suffix

else
    pth_all_flyg_raw_tif = [];
    pth_all_flyg_raw_mat = [];
end

pth_prefix_all = cat(1, pth_all_tif, pth_all_mat, pth_all_flyg_raw_tif, pth_all_flyg_raw_mat); %ALL POSSIBLE PATTERNS
pth_prefix_all = unique(cellfun(@(x) x(1:end-4), {pth_prefix_all(:).name}, 'UniformOutput', false)); %unique files, whether tif or mat (will not find duplicates with one scopa and one flyg filename)

end




function pth_all = prioritize_mat(pth_prefix_all)

pth_all = cell(1,numel(pth_prefix_all));
for k = 1:numel(pth_prefix_all)
    tmpmat = [pth_prefix_all{k} '.mat'];
    tmptif = [pth_prefix_all{k} '.tif'];
    if isfile(tmpmat)
        pth_all{k} = tmpmat;
    else
        if isfile(tmptif)
            pth_all{k} = tmptif;
        else
            error("there's might be a bug in filefind")
        end
    end
end


end



function check_for_duplicate_specifiers(pth_all)

for k = 1:numel(pth_all)
    id = idmake(pth_all{k});
    tmp{k} = [id.recdate '_' id.fly '_' id.trial '_' id.suffix];
end
if numel(tmp)~=numel(unique(tmp))
    error("there are at least two found files with the same extension and same specifiers (date, fly, trial, and suffix (which will be 'raw' for raw stack, whether named with flyg or scopa format")
end

end



function check_for_duplicate_filenames(pth_prefix_all)

error_on_repeat_filenames = 1;

pthscheck = cellfun(@(x,y) strsplit(x,y), pth_prefix_all, repelem({filesep}, numel(pth_prefix_all)), 'UniformOutput', false);
justfns = cellfun(@(x) x(end), pthscheck);
[jp, kp, kp2]=unique(justfns, 'stable');
yy = hist(kp2,unique(kp2));
jp = jp(yy>1);

if ~isempty(cell2mat(jp'))
    pthdupes = pth_prefix_all(contains(pth_prefix_all, jp));
    if error_on_repeat_filenames
        error(sprintf([sprintf('repeated filenames in different locations, move or rename or set error_on_repeat_filenames to 0 above') '\n' sprintf('%s \n', pthdupes{:})]))
    else
        sprintf([sprintf('repeated filenames in different locations, operating on the first of each repeat') '\n' sprintf('%s \n', pthdupes{:})])
        pth_prefix_all = pth_prefix_all(kp);
    end
end

end
