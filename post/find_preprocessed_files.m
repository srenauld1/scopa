function pth_all = find_preprocessed_files(opts)

currdir = split(pwd, filesep);
currdir = currdir{end};
envname = getenv('HOSTNAME');
if ~isempty(regexp( envname, 'compute-', 'once' ))
    pth_parent = ['/n/scratch/users/'  currdir(1) filesep currdir filesep opts.parent_folder_path filesep];
else
    pth_parent = strsplit(opts.parent_folder_path, filesep); %in case trailing filesep, or not
    pth_parent = [strjoin(pth_parent(1:2), filesep) filesep];
end

fn_pattern_tif = [pth_parent '**' filesep opts.recdate '_' opts.fly '_' opts.trial '_' opts.suffix_analysis '_.tif'];
pthz_all_tif = rdir(fn_pattern_tif);
fn_pattern_mat = [fn_pattern_tif(1:end-4) '.mat'];
pth_all_mat = rdir(fn_pattern_mat);
pth_all = cat(1, pthz_all_tif, pth_all_mat);
pth_all = unique(cellfun(@(x) x(1:end-3), {pth_all(:).name}, 'UniformOutput', false)); %unique files, whether tif or mat
