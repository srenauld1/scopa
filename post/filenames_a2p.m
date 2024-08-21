function [opt, pth, croplim_all, parstr, ids] = filenames_a2p(opt, pth_usefile_prefix)

%% params


valid_fnsuffixes = opt.mn.valid_fnsuffixes;
parent_folder_path_o2 = opt.mn.parent_folder_path_o2;
regionex_all = opt.mn.regionex_all;
tmp_folder_name = opt.mn.tmp_folder_name;
use_caiman_on_hires = opt.hires.use_caiman_on_hires;
display_range_in = opt.ld.gif.display_range_in;
suffixes_plot_in = opt.ld.gif.suffixes_plot_in;
use_hires = opt.mroi.auto.use_hires_str; %gets updated to numeric struct, fieldname use_hires
use_drawn_rois = opt.mroi.use_drawn_rois_str; %gets updated to numeric struct, fieldname use_drawn_rois
num_mroi_auto = opt.mroi.auto.num_mroi_auto_str; %gets updated to numeric struct, fieldname num_mroi_auto
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

if ~any(strcmp(suffix_analysis, valid_fnsuffixes)) %if it's a flyg pattern raw file, trial will be read incorrectly 
    trialnum = str2double(spl(find(strcmp(spl, 'trial'))+1));
end

datefly_hyphen = [num2str(datenum) '-' num2str(flynum)];
recid_underscore = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];

pth_prefix = [pth_fldr recid_underscore '_'];

if ~any(strcmp(suffix_analysis, valid_fnsuffixes)) %if it's a flyg pattern raw file, none will match 
    suffix_analysis = 'raw';
    pth_stack_analysis = [pth_usefile_prefix(1:end-1) '_.mat']; %remove dot, insert '_.mat'
else
    pth_stack_analysis = [pth_fldr recid_underscore '_' suffix_analysis '_.mat'];
end

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

pth_daqrs = [pth_fldr recid_underscore '_daqrs_.mat']; %keep hyphen for compatibility with flyg
pth_daqinds = [pth_fldr recid_underscore '_daqinds_.mat'];

% pth_ftvid_pat = [pth_fldr 'FicTracData' filesep 'fictrac-raw-' num2str(datenum) '*_trial_' sprintf( '%03d', trialnum ) '.avi']; %original ft video
pth_ftdat_pat = [pth_fldr 'FicTracData' filesep 'fictrac-' num2str(datenum) '*_trial_' sprintf( '%03d', trialnum ) '.dat']; %
pth_ftdat = rdir(pth_ftdat_pat);
if isempty(pth_ftdat)
    pth_ftdat = [];
else
    pth_ftdat = pth_ftdat.name;
end

pth_ftlog_pat = [pth_fldr 'FicTracData' filesep 'fictrac-' num2str(datenum) '*_trial_' sprintf( '%03d', trialnum ) '.log']; %
pth_ftlog = rdir(pth_ftlog_pat);
if isempty(pth_ftlog)
    pth_ftlog = [];
else
    pth_ftlog = pth_ftlog.name;
end


pth_ftvidlog_pat = [pth_fldr 'FicTracData' filesep 'fictrac-vidLogFrames-' num2str(datenum) '*_trial_' sprintf( '%03d', trialnum ) '.txt']; %
pth_ftvidlog = rdir(pth_ftvidlog_pat);
if isempty(pth_ftvidlog)
    pth_ftvidlog = [];
else
    pth_ftvidlog = pth_ftvidlog.name;
end

pth_ftvid_pat = [pth_fldr recid_underscore '_FTV_DS_.mat']; %downsampled ft video (downsampled in register.py)
pth_ftvid = rdir(pth_ftvid_pat);
if isempty(pth_ftvid)
    pth_ftvid = [];
    pth_ftvidrs = [];
else
    pth_ftvid = pth_ftvid.name;
    pth_ftvidrs = [pth_ftvid(1:end-4) 'RS_.mat'];
end

pth_epochinds = [pth_fldr recid_underscore '_epochinds_.bin'];
pth_epochinfo = [pth_fldr recid_underscore '_epochinfo_.mat'];

pth_grandparent = strsplit(pth_fldr, filesep); %in case trailing filesep, or not
pth_grandparent = [strjoin(pth_grandparent(1:end-2), filesep) filesep];

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
    pth_mroi_interactive.(regionex) = [pth_stack_analysis(1:end-4) regionex '_' croplimstr '_interactive_rois_morph_.mat'];
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
    if all(cellfun(@isempty, [opt.pf.(pffn{pfi}).fitm.varnms.depvpre]))
        opt.pf.(pffn{pfi}).do = 0;
    end
end

if all(cellfun(@isempty, [opt.fitm.varnms.depvpre]))
    opt.fitm.do_predict = 0;
end

%% gif in load_stacks

if isempty(suffixes_plot_in)
    plot_stack_gif = 0;
else
    plot_stack_gif = 1;
end

if ~ismember(suffix_analysis, suffixes_plot_in)
    "suffixes_plot_in DOES NOT CONTAIN suffix_analysis, ADDING IT TO suffixes_plot_in NOW"
    suffixes_plot_in{end+1} = suffix_analysis;
end
suffixes_plot_in = unique(suffixes_plot_in, 'stable'); %make sure there aren't accidental repeats
suffixes_plot_in = cat(2, setxor(suffix_analysis, suffixes_plot_in, 'stable'), suffix_analysis); %make suffix_analysis the last one so it can be output from load_stack with minimal memory

[~, plot_stack_order] = sort(cellfun(@length, suffixes_plot_in)); %default plot order is shortest to longest suffix (least to most processed, since additional suffixes are added at each stage)


pth_stacks_prefix = cell(length(suffixes_plot_in), 1);
suffixes_plot_new = cell(length(suffixes_plot_in), 1);
display_range_new = cell(length(suffixes_plot_in), 1);
for spi = 1:length(suffixes_plot_in)

    pth_tmp = find_preprocessed_files(pth_fldr, parent_folder_path_o2, valid_fnsuffixes, datenum, flynum, trialnum, suffixes_plot_in{spi});

    if ~isempty(pth_tmp)
        if numel(pth_tmp)>1
            error("multiple files found with same suffixes_plot_in")
        end
        pth_stacks_prefix{spi} = pth_tmp{1};
        suffixes_plot_new{spi} = suffixes_plot_in{spi};
        display_range_new{spi} = display_range_in.(suffixes_plot_in{spi});
    else
        fnspec = ['pth_fldr:' pth_fldr, 'recdate:' num2str(datenum), 'fly:' num2str(flynum), 'trial:' num2str(trialnum), 'suffix:' suffixes_plot_in{spi}];
        sprintf(['WARNING, NEITHER TIF NOR MAT FOUND FOR FILENAME SPECIFIERS:' newline fnspec newline 'SKIPPING IT FOR PLOT'])
    end

end

display_range_new = display_range_new(~cellfun(@isempty, display_range_new));

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
    pth.tsuse_nms_prefix.(pffn{pfi}) = [pth_fldr 'tsuse_' pffn{pfi}];
end

pth.tsuse_nms_prefix.fitm = [pth_fldr 'tsuse_finfits_'];
pth.tsuse_nms_prefix.scat = [pth_fldr 'tsuse_finscatter_'];
pth.tsuse_nms_prefix.pltexp = [pth_fldr 'tsuse_finpltexp_'];

%% assign to struct

ids.datenum = datenum;
ids.flynum = flynum;
ids.trialnum = trialnum;
ids.recid = recid_underscore;
ids.datefly_hyphen = datefly_hyphen; %for some flyg files

pth.prefix = pth_prefix;
pth.fldr = pth_fldr;
pth.stack_analysis = pth_stack_analysis;
pth.stacks_prefix = pth_stacks_prefix;
pth.hires_prefix = pth_hires_prefix;
pth.hires_mat_matreg = pth_hires_mat_matreg;
pth.froi_hires = pth_froi_hires;
pth.md = pth_md;
pth.flyg_md = pth_flyg_md;
pth.mroi = pth_mroi;
pth.mroi_interactive = pth_mroi_interactive;
pth.froi_all = pth_froi_all;
pth.roi_allmethods = pth_roi_allmethods;
pth.daq = pth_daq;
pth.daqrs = pth_daqrs;
pth.daqinds = pth_daqinds;
pth.ft.dat = pth_ftdat;
pth.ft.log = pth_ftlog;
pth.ft.vidlog = pth_ftvidlog;
pth.ft.vid = pth_ftvid;
pth.ft.vidrs = pth_ftvidrs;
pth.epochinds = pth_epochinds;
pth.epochinfo = pth_epochinfo;
pth.savedata_oneregion = pth_savedata_oneregion;
pth.tmpfiles = pth_tmpfiles;

opt.pf.bump.numcluster_for_bump_domain_resample = numcluster_for_bump_domain_resample_new; %update field, change from user input formatting

opt.mroi.use_drawn_rois = use_drawn_rois_new; %update field, change from user input formatting
opt.mroi.auto.num_mroi_auto = num_mroi_auto_new; %update field, change from user input formatting
opt.mroi.auto.use_hires = use_hires_new; %update field, change from user input formatting

opt.ld.gif.plot_stack_order = plot_stack_order;
opt.ld.gif.plot_stack_gif = plot_stack_gif;
opt.ld.gif.suffixes_plot = suffixes_plot_new;
opt.ld.gif.display_range = display_range_new;

