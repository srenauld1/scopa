function [opt, pth, croplim_all, parstr, ids] = filenames_a2p(opt, pth_usefile_prefix)

%% params


pth_grandparent = opt.mn.pth_grandparent;
% suffix_analysis = opt.mn.suffix_analysis;
regionex_all = opt.mn.regionex_all;
tmp_folder_name = opt.mn.tmp_folder_name;
use_caiman_on_hires = opt.hires.use_caiman_on_hires;
suffixes_plot = opt.ld.gif.suffixes_plot;
use_hires = opt.mroi.use_hires_str; %gets updated to numeric struct, fieldname use_hires
use_drawn_rois = opt.mroi.use_drawn_rois_str; %gets updated to numeric struct, fieldname use_drawn_rois
num_mroi_auto = opt.mroi.num_mroi_auto_str; %gets updated to numeric struct, fieldname num_mroi_auto
caiman_lr_str = opt.froi.caiman_lr_str;
numcluster_for_bump_domain_resample = opt.pf.bump.numcluster_for_bump_domain_resample_str; %gets updated to numeric struct, fieldname numcluster_for_bump_domain_resample
caiman_hr_str = opt.hires.caiman_hr_str;

%% variables for all regionex

[pth_fldr, fn_input, ~] = fileparts(pth_usefile_prefix);
pth_fldr = [pth_fldr filesep];
spl = strjoin(strsplit(fn_input, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
spl = strsplit(spl, '_'); %then separate by underscore

datenum = str2double(spl{1});
flynum = str2double(spl{2});
trialnum = str2double(spl{3});    % trialnum = str2double(spl(find(strcmp(spl, 'trial'))+1));
suffix_analysis = strjoin(spl(4:end), '_');
if strcmp(suffix_analysis(end), '_')
    suffix_analysis = suffix_analysis(1:end-1);
end

datefly_hyphen = [num2str(datenum) '-' num2str(flynum)];
recid_underscore = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];

pth_stack_analysis = [pth_fldr recid_underscore '_' suffix_analysis '_.mat'];

pth_md = [pth_fldr recid_underscore '_metadatanew_.mat'];
pth_flyg_md_pat = [pth_fldr datefly_hyphen '_metadata_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
pth_flyg_md = rdir(pth_flyg_md_pat);
if isempty(pth_flyg_md)
    pth_flyg_md = [];
else
    pth_flyg_md = pth_flyg_md.name;
end

pth_daq_pat = [pth_fldr datefly_hyphen '_daqData_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
pth_daq = rdir(pth_daq_pat);
if isempty(pth_daq)
    pth_daq = [];
else
    pth_daq = pth_daq.name;
end
pth_daq_resamp = [pth_fldr recid_underscore '_daqdata_resamp_.mat']; %keep hyphen for compatibility with flyg

pth_ftvid_pat = [pth_fldr 'FicTracData' filesep 'fictrac-raw-' num2str(datenum) '*_trial_' sprintf( '%03d', trialnum ) '.avi'];
pth_ftvid = rdir(pth_ftvid_pat);
if isempty(pth_ftvid)
    pth_ftvid = [];
else
    pth_ftvid = pth_ftvid.name;
end

pth_epochinds = [pth_fldr recid_underscore '_epochinds_.bin'];
pth_epochinfo = [pth_fldr recid_underscore '_epochinfo_.mat'];

pth_tmpfiles = [pth_grandparent tmp_folder_name filesep];
if ~isdir(pth_tmpfiles)
    mkdir(pth_tmpfiles)
end

%% variables for each regionex

croplim_all.backupdefault = 'backupdefault'; %make this field available when regionex are not available 

for i = 1:length(regionex_all)

    regionex = regionex_all{i};
    spl = strsplit(regionex, '_');
    regionex_nounderscore = spl{1}; %anything after an underscore defines a region within the prefix regionex cuboid from python preprocessing

    [croplim_all.(regionex), croplimstr] = load_croplim(pth_fldr, recid_underscore, regionex_nounderscore );

    tmpnum = 0;
    if any(strcmp(regionex, use_hires))
        tmpnum = 1;
    end
    flag_hires = num2str(tmpnum);
    use_hires_new.(regionex) = tmpnum;

    tmpnum = 0;
    if any(strcmp(regionex, use_drawn_rois))
        tmpnum = 1;
    end
    flag_use_drawn_rois = num2str(tmpnum);
    use_drawn_rois_new.(regionex) = tmpnum;

    tmpnum = 0;
    tmpind = find(~cellfun(@isempty, regexp(num_mroi_auto, [regionex '-\d*'])));
    if tmpind
        tmpnum = sscanf(num_mroi_auto{tmpind},[regionex '-%d']);
    end
    flag_num_mroi_auto = num2str(tmpnum);
    num_mroi_auto_new.(regionex) = tmpnum;

    paramstr = ['moex_' flag_hires '_' flag_use_drawn_rois '_' flag_num_mroi_auto];
    parstr.mroi.(regionex) = paramstr;

    pth_mroi.(regionex) = [pth_stack_analysis(1:end-4) regionex '_' croplimstr '_' paramstr '_rois_morph_.mat'];
    pth_roi_allmethods.(regionex){1} = pth_mroi.(regionex);

    pth_froi_all_tmp = [];
    for csi = 1:length(caiman_lr_str)
        pth_froi_pat = [pth_fldr recid_underscore '_' suffix_analysis '_' regionex_nounderscore '_*_cmex_' caiman_lr_str{csi} '_rois_.mat'];
        tmp = rdir(pth_froi_pat);
        pth_froi_all_tmp = cat(1, pth_froi_all_tmp, tmp);
    end

    if ~isempty(pth_froi_all_tmp) %if caiman file(s) do exist . . .

        pth_froi_all_tmp = unique({pth_froi_all_tmp.name});
        pth_froi_all_tmp = natsortfiles(pth_froi_all_tmp);

        for ci = 1:length(pth_froi_all_tmp)
            [~, fncr, ~] = fileparts(pth_froi_all_tmp{ci});
            spl = strsplit(fncr, '_');
            insloc = find(strcmp(spl, regionex_nounderscore));
            croplimstr_check{ci} = strjoin(spl(insloc+1:insloc+8), '_');

            cpatmp = strjoin(spl(find(strcmp(spl, 'cmex')):end-2), '_'); %everything in filename after 'cmex'
            parstr.froi.(regionex){ci,1} = strrep(cpatmp, '.', 'p'); %replace period with p
            pth_froi_all.(regionex){ci,1} = pth_froi_all_tmp{ci};

        end
        if numel(unique(croplimstr_check))>1
            error("a regionex has different croplim (FOV coordinates) across extraction runs, should be the same across runs")
        end
        pth_roi_allmethods.(regionex) = cat(1, pth_roi_allmethods.(regionex), pth_froi_all.(regionex));
        paramstr = [paramstr '_cmex_' caiman_lr_str];

    else
        parstr.froi.(regionex) = [];
        pth_froi_all.(regionex) = [];
    end


    tmpnum = 0;
    tmpind = find(~cellfun(@isempty, regexp(numcluster_for_bump_domain_resample, [regionex '-\d*'])));
    if tmpind
        tmpnum = sscanf(numcluster_for_bump_domain_resample{tmpind},[regionex '-%d']);
    end
    flag_numcluster_for_bump_domain_resample = num2str(tmpnum);
    numcluster_for_bump_domain_resample_new.(regionex) = tmpnum;


    paramstr = [paramstr '_' flag_numcluster_for_bump_domain_resample];

    % if use_hires(i)
    %     paramstr = [paramstr '_hr_moex_paramtbd_'];
    %     parstr.mroi.(regionex) = [parstr.mroi.(regionex) '_hr_moex_paramtbd'];
    %     if use_caiman_on_hires(i)
    %         paramstr = [paramstr '_hr_cmex_' caiman_hr_str];
    %     end
    % end

    pth_savedata_oneregion.(regionex) = [pth_fldr recid_underscore '_' suffix_analysis '_' paramstr '_' regionex '_savedata_.mat'];

    pth_caimanfails = [pth_fldr recid_underscore '_*_' regionex_nounderscore '_*_cmex_*_FAILURE_.mat'];
    pth_caimanfails2 = [pth_fldr recid_underscore '_*_' regionex_nounderscore '_*_cmex_*_NOROIS_.mat'];
    delete_caiman_fails(pth_caimanfails, pth_fldr, regionex_nounderscore)
    delete_caiman_fails(pth_caimanfails2, pth_fldr, regionex_nounderscore)

end


%% do flags


pffn = fieldnames(opt.pf);
for pfi = 1:numel(pffn)
    if all(cellfun(@isempty, [opt.pf.(pffn{pfi}).fitm.vars.depvpre_str]))
        opt.pf.(pffn{pfi}).do = 0;
    end
end

if all(cellfun(@isempty, [opt.fitm.vars.depvpre_str]))
    opt.fitm.do_predict = 0;
end

%% gif in load_stacks

if isempty(suffixes_plot)
    plot_stack_gif = 0;
else
    plot_stack_gif = 1;
end

if ~ismember(suffix_analysis, suffixes_plot)
    "suffixes_plot DOES NOT CONTAIN suffix_analysis, ADDING IT TO suffixes_plot NOW"
    suffixes_plot{end+1} = suffix_analysis;
end
suffixes_plot = unique(suffixes_plot, 'stable'); %make sure there aren't accidental repeats
suffixes_plot = cat(2, setxor(suffix_analysis, suffixes_plot), suffix_analysis); %make suffix_analysis the last one so it can be output from load_stack with minimal memory

[~, plot_stack_order] = sort(cellfun(@length, suffixes_plot)); %default plot order is shortest to longest suffix (least to most processed, since additional suffixes are added at each stage)


pth_stacks_prefix = cell(length(suffixes_plot), 1);
for spi = 1:length(suffixes_plot)

    pthpat = [pth_fldr recid_underscore '_' suffixes_plot{spi} '_.tif'];
    pth_tmp = rdir(pthpat);
    if isempty(pth_tmp)
        pthpat = [pthpat(1:end-4) '.mat'];
        pth_tmp = rdir(pthpat);
    end

    if ~isempty(pth_tmp)
        pth_stacks_prefix{spi} = pth_tmp.name(1:end-4);
    else
        sprintf(['WARNING, NEITHER TIF NOR MAT FOUND FOR' newline pthpat(1:end-4) newline 'SKIPPING IT FOR PLOT'])
    end

end

%% hires

pthpat = [pth_fldr recid_underscore  '_hires_.tif'];
pth_tmp = rdir(pthpat);
if isempty(pth_tmp)
    pthpat = [pthpat(1:end-4) '.mat'];
    pth_tmp = rdir(pthpat);
    if isempty(pth_tmp)
        pthpat = [pth_fldr num2str(datenum) '_' num2str(flynum) '_hires_.tif']; %sometimes hires has no trial in filename (one hires for all trials)
        pth_tmp = rdir(pthpat);
        if isempty(pth_tmp)
            pthpat = [pthpat(1:end-4) '.mat'];
            pth_tmp = rdir(pthpat);
        end
    end
end
if ~isempty(pth_tmp)
    pth_hires_prefix = pth_tmp.name(1:end-4);
    pth_hires_mat_matreg = [pth_hires_prefix 'hires_matreg_.mat'];
    pth_froi_hires = [pth_hires_prefix 'caiman' caiman_hr_str '_roishires_.mat'];
else
    pth_hires_prefix = [];
    pth_hires_mat_matreg = [];
    pth_froi_hires = [];
end

pffn = fieldnames(opt.pf);
for pfi = 1:numel(pffn)
    pth.tsuse.(pffn{pfi}) = [pth_fldr 'tsuse_' pffn{pfi} '_.mat'];
end

pth.tsuse.fitm = [pth_fldr 'tsuse_finfits_.mat'];
pth.tsuse.scat = [pth_fldr 'tsuse_finscatter_.mat'];
pth.tsuse.pltexp = [pth_fldr 'tsuse_finpltexp_.mat'];

%% assign to struct

ids.datenum = datenum;
ids.flynum = flynum;
ids.trialnum = trialnum;
ids.recid = recid_underscore;
ids.datefly_hyphen = datefly_hyphen; %for some flyg files

pth.fldr = pth_fldr;
pth.stack_analysis = pth_stack_analysis;
pth.stacks_prefix = pth_stacks_prefix;
pth.hires_prefix = pth_hires_prefix;
pth.hires_mat_matreg = pth_hires_mat_matreg;
pth.froi_hires = pth_froi_hires;
pth.md = pth_md;
pth.flyg_md = pth_flyg_md;
pth.mroi = pth_mroi;
pth.froi_all = pth_froi_all;
pth.roi_allmethods = pth_roi_allmethods;
pth.daq = pth_daq;
pth.daq_resamp = pth_daq_resamp;
pth.ftvid = pth_ftvid;
pth.epochinds = pth_epochinds;
pth.epochinfo = pth_epochinfo;
pth.savedata_oneregion = pth_savedata_oneregion;
pth.tmpfiles = pth_tmpfiles;

opt.pf.bump.numcluster_for_bump_domain_resample = numcluster_for_bump_domain_resample_new; %update field, change from user input formatting

opt.mroi.use_drawn_rois = use_drawn_rois_new; %update field, change from user input formatting
opt.mroi.num_mroi_auto = num_mroi_auto_new; %update field, change from user input formatting
opt.mroi.use_hires = use_hires_new; %update field, change from user input formatting

opt.ld.gif.plot_stack_order = plot_stack_order;
opt.ld.gif.plot_stack_gif = plot_stack_gif;

