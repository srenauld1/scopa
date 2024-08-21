function pth_prefix_all = find_preprocessed_files(parent_folder_path_local, parent_folder_path_o2, valid_fnsuffixes, recdate, fly, trial, fnsuffix, filespec_matching_style)

%todo: there can be duplicate files if one is flyg raw patern and one is scopa raw pattern, but this is unlikely, fix soon
%besides this, it will find duplicate filenames in different locations and will either error or continue with unique filenames only, depending on value of error_on_repeat_filenames



error_on_repeat_filenames = 1;

if ~exist('filespec_matching_style', 'var')
    filespec_matching_style = 'each';
end

fnspec = expand_fn_specifiers(filespec_matching_style, recdate, fly, trial, fnsuffix);

pth_parent = find_parent_path(parent_folder_path_local, parent_folder_path_o2);

pth_prefix_all = [];
for j = 1:numel(fnspec.recdate)
    pth_prefix_all_onespec = find_preprocessed_files_onespec(fnspec.recdate{j}, fnspec.fly{j}, fnspec.trial{j}, fnspec.fnsuffix{j}, pth_parent, valid_fnsuffixes);
    pth_prefix_all = cat(1, pth_prefix_all, vec(pth_prefix_all_onespec));
end

pth_prefix_all = unique(pth_prefix_all); %unique files, whether tif or mat (will not find duplicates with one scopa and one flyg filename)

pthscheck = cellfun(@(x,y) strsplit(x,y), pth_prefix_all, repelem({filesep}, numel(pth_prefix_all))', 'UniformOutput', false);
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





function fnspec = expand_fn_specifiers(filespec_matching_style, recdate, fly, trial, fnsuffix)

if ~iscell(recdate)==1
    recdate = {recdate};
end
if ~iscell(fly)==1
    fly = {fly};
end
if ~iscell(trial)==1
    trial = {trial};
end
if ~iscell(fnsuffix)==1
    fnsuffix = {fnsuffix};
end

if strcmp(filespec_matching_style, 'any')
    fnspec = combinations(recdate, fly, trial, fnsuffix);
elseif strcmp(filespec_matching_style, 'each')
    specnums = [numel(recdate), numel(fly), numel(trial), numel(fnsuffix)];
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
    if numel(fnsuffix)==1
        fnsuffix = repelem(fnsuffix, maxspecnum);
    end
    fnspec.recdate = recdate;
    fnspec.fly = fly;
    fnspec.trial = trial;
    fnspec.fnsuffix = fnsuffix;
end



end


function pth_parent = find_parent_path(parent_folder_path_local, parent_folder_path_o2)

envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    if isempty(parent_folder_path_o2)
        sprintf("O2 parent path not specified, using default path based on parent folder name")
        fldr_parent = strsplit(parent_folder_path_local, filesep);
        fldr_parent = fldr_parent{end};
        % [pthenv, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename); %fails on matlabengine for python bc no java, tried various startup options
        stk = dbstack('-completenames');
        [pthenv, ~, ~] = fileparts(stk(1).file);
        spl = strsplit(pthenv, filesep);
        username = cell2mat(spl(find(contains(spl, 'home'))+1));
        if isempty(username)
            error("scopa may not be in your O2 home folder, make sure to git clone scopa into your O2 home folder")
        end
        pth_parent = ['/n/scratch/users/'  username(1) filesep username filesep fldr_parent filesep];
    else
        pth_parent = strsplit(parent_folder_path_o2, filesep); %in case trailing filesep, or not
        if isempty(pth_parent{end})
            pth_parent = [strjoin(pth_parent(1:end-1), filesep) filesep];
        else
            pth_parent = [strjoin(pth_parent, filesep) filesep];
        end
    end
else
    pth_parent = strsplit(parent_folder_path_local, filesep); %in case trailing filesep, or not
    if isempty(pth_parent{end})
        pth_parent = [strjoin(pth_parent(1:end-1), filesep) filesep];
    else
        pth_parent = [strjoin(pth_parent, filesep) filesep];
    end
end


end


function pth_prefix_all = find_preprocessed_files_onespec(recdate, fly, trial, fnsuffix, pth_parent, valid_fnsuffixes)


recdate = num2str(recdate); %just in case it's numeric, won't matter if not
fly = num2str(fly); %just in case it's numeric, won't matter if not
trial = num2str(trial); %just in case it's numeric, won't matter if not


%%SCOPA PATTERN, TIF AND MAT
fn_pattern_tif = [pth_parent '**' filesep recdate '_' fly '_' trial '_' fnsuffix '_.tif']; %double asterisk is 0 or more directories
valid_tif_fns = strcat(valid_fnsuffixes, '_.tif');
pth_all_tif = rdir(fn_pattern_tif);
pth_all_tif = pth_all_tif(contains({pth_all_tif.name}, valid_tif_fns)); %in case wildcard fnsuffix returns unwanted files

valid_mat_fns = strcat(valid_fnsuffixes, '_.mat');
fn_pattern_mat = [fn_pattern_tif(1:end-4) '.mat'];
pth_all_mat = rdir(fn_pattern_mat);
pth_all_mat = pth_all_mat(contains({pth_all_mat.name}, valid_mat_fns)); %in case wildcard fnsuffix returns unwanted files


%%FLYG RAW PATTERN, TIF AND MAT
if strcmp(fnsuffix, 'raw')
    if strcmp(trial, '*')
        fn_pattern_flyg_raw_tif = [pth_parent '**' filesep recdate '-' fly '_*_trial_*_*.tif']; %double asterisk is 0 or more directories
    else
        fn_pattern_flyg_raw_tif = [pth_parent '**' filesep recdate '-' fly '_*_trial_' sprintf( '%03s', trial ) '_*.tif']; %double asterisk is 0 or more directories
    end
    pth_all_flyg_raw_tif = rdir(fn_pattern_flyg_raw_tif);

    fn_pattern_flyg_raw_mat = [fn_pattern_flyg_raw_tif(1:end-4) '.mat'];
    pth_all_flyg_raw_mat = rdir(fn_pattern_flyg_raw_mat); %don't need to subset by valid_fnsuffixes since flygraw pattern doesn't include fnsuffix

else
    pth_all_flyg_raw_tif = [];
    pth_all_flyg_raw_mat = [];
end


pth_prefix_all = cat(1, pth_all_tif, pth_all_mat, pth_all_flyg_raw_tif, pth_all_flyg_raw_mat); %ALL POSSIBLE PATTERNS
pth_prefix_all = unique(cellfun(@(x) x(1:end-4), {pth_prefix_all(:).name}, 'UniformOutput', false)); %unique files, whether tif or mat (will not find duplicates with one scopa and one flyg filename)


end
