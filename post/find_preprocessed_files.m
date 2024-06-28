function [pth_all, pth_grandparent] = find_preprocessed_files(opts)


envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    if isempty(opts.parent_folder_path_o2)
        sprintf("O2 parent path not specified, using default path based on parent folder name")
        fldr_parent = strsplit(opts.parent_folder_path_local, filesep);
        fldr_parent = fldr_parent{end};
        [pthenv, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename);
        spl = strsplit(pthenv, filesep);
        username = cell2mat(spl(find(contains(spl, 'home'))+1));
        if isempty(username)
            error("scopa may not be in your O2 home folder, make sure to git clone scopa into your O2 home folder")
        end
        pth_parent = ['/n/scratch/users/'  username(1) filesep username filesep fldr_parent filesep];
    else
        pth_parent = strsplit(opts.parent_folder_path_o2, filesep); %in case trailing filesep, or not
        if isempty(pth_parent{end})
            pth_parent = [strjoin(pth_parent(1:end-1), filesep) filesep];
        else
            pth_parent = [strjoin(pth_parent, filesep) filesep];
        end
    end
else
    pth_parent = strsplit(opts.parent_folder_path_local, filesep); %in case trailing filesep, or not
    if isempty(pth_parent{end})
        pth_parent = [strjoin(pth_parent(1:end-1), filesep) filesep];
    else
        pth_parent = [strjoin(pth_parent, filesep) filesep];
    end
end

fn_pattern_tif = [pth_parent '**' filesep opts.recdate '_' opts.fly '_' opts.trial '_' opts.suffix_analysis '_.tif'];
valid_tif_fns = {'raw_.tif', 'cmrg_.tif', 'dcdn_.tif'};
pth_all_tif = rdir(fn_pattern_tif);
pth_all_tif = pth_all_tif(contains({pth_all_tif.name}, valid_tif_fns)); %in case wildcard opts.suffix_analysis returns unwanted files

if strcmp(opts.trial, '*')
    fn_pattern_flyg_raw_tif = [pth_parent '**' filesep opts.recdate '-' opts.fly '_*_' opts.suffix_analysis '_.tif'];
else
    fn_pattern_flyg_raw_tif = [pth_parent '**' filesep opts.recdate '-' opts.fly '_' sprintf( '%03s', opts.trial ) '_' opts.suffix_analysis '_.tif'];
end
pth_all_flyg_raw_tif = rdir(fn_pattern_flyg_raw_tif);

valid_mat_fns = {'raw_.mat', 'cmrg_.mat', 'dcdn_.mat'};
fn_pattern_mat = [fn_pattern_tif(1:end-4) '.mat'];
pth_all_mat = rdir(fn_pattern_mat);
pth_all_mat = pth_all_mat(contains({pth_all_mat.name}, valid_mat_fns)); %in case wildcard opts.suffix_analysis returns unwanted files

pth_all = cat(1, pth_all_tif, pth_all_flyg_raw_tif, pth_all_mat);
pth_all = unique(cellfun(@(x) x(1:end-3), {pth_all(:).name}, 'UniformOutput', false)); %unique files, whether tif or mat (will not find duplicates with one scopa and one flyg filename)

pth_grandparent = strsplit(pth_parent, filesep); %in case trailing filesep, or not
pth_grandparent = [strjoin(pth_grandparent(1:end-2), filesep) filesep];
