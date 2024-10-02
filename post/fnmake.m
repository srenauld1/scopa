function [pth, parstr] = fnmake(ui, ids, pthstack)


%%set up filenames for a2p 


recdatenum = ids.recdatenum; 
flynum = ids.flynum; 
trialnum = ids.trialnum; 
suffix = ids.suffix; 
recid = ids.recid;
datefly_hyphen = ids.datefly_hyphen;


regionex_all = ui.mn.regionex_all;
tmp_folder_name = ui.mn.tmp_folder_name;
use_caiman_on_hires = ui.hires.use_caiman_on_hires;
use_hires = ui.mroi.auto.use_hires; %gets updated to numeric struct, fieldname use_hires
use_drawn_rois = ui.mroi.use_drawn_rois; %gets updated to numeric struct, fieldname use_drawn_rois
num_mroi_auto = ui.mroi.auto.num_mroi_auto; %gets updated to numeric struct, fieldname num_mroi_auto
caiman_lr_str = ui.froi.caiman_lr_str;
numcluster_for_bump_domain_resample = ui.pf.bump.numcluster_for_bump_domain_resample; %gets updated to numeric struct, fieldname numcluster_for_bump_domain_resample
caiman_hr_str = ui.hires.caiman_hr_str;

%% variables for all regionex


[pth_fldr, ~, ~] = fileparts(pthstack);
pth_fldr = [pth_fldr filesep];

pth_prefix = [pth_fldr recid '_'];


pth_md = [pth_fldr recid '_mdsi_.txt'];
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

pth_daqrs = [pth_fldr recid '_daqrs_.mat']; 

% pth_ftvid_pat = [pth_fldr 'FicTracData' filesep 'fictrac-raw-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.avi']; %original ft video
pth_ftdat_pat = [pth_fldr 'FicTracData' filesep 'fictrac-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.dat']; %
pth_ftdat = rdir(pth_ftdat_pat);
if isempty(pth_ftdat)
    pth_ftdat = [];
else
    pth_ftdat = pth_ftdat.name;
end

pth_ftlog_pat = [pth_fldr 'FicTracData' filesep 'fictrac-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.log']; %
pth_ftlog = rdir(pth_ftlog_pat);
if isempty(pth_ftlog)
    pth_ftlog = [];
else
    pth_ftlog = pth_ftlog.name;
end


pth_ftvidlog_pat = [pth_fldr 'FicTracData' filesep 'fictrac-vidLogFrames-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.txt']; %
pth_ftvidlog = rdir(pth_ftvidlog_pat);
if isempty(pth_ftvidlog)
    pth_ftvidlog = [];
else
    pth_ftvidlog = pth_ftvidlog.name;
end

pth_ftvid_pat = [pth_fldr recid '_FTV_DS_.mat']; %downsampled ft video (downsampled in register.py)
pth_ftvid = rdir(pth_ftvid_pat);
if isempty(pth_ftvid)
    pth_ftvid = [];
    pth_ftvidrs = [];
else
    pth_ftvid = pth_ftvid.name;
    pth_ftvidrs = [pth_ftvid(1:end-4) 'RS_.mat'];
end

pth_epochinds = [pth_fldr recid '_epochinds_.bin'];
pth_epochinfo = [pth_fldr recid '_epochinfo_.mat'];

pth_grandparent = strsplit(pth_fldr, filesep); %in case trailing filesep, or not
pth_grandparent = [strjoin(pth_grandparent(1:end-2), filesep) filesep];

pth_tmpfiles = [pth_grandparent tmp_folder_name filesep];
if ~isdir(pth_tmpfiles)
    mkdir(pth_tmpfiles)
end

%% variables for each regionex


if isempty(cell2mat(regionex_all))
    numregions = 0;
else
    numregions = numel(regionex_all);
end

parstr = '';
for k = 1:numregions

    regionex = regionex_all{k};
    spl = strsplit(regionex, '_');
    regionex_nounderscore = spl{1}; %anything after an underscore defines a region within the prefix regionex cuboid from python preprocessing

    [~, croplimstr] = load_croplim(pth_fldr, recid, regionex_nounderscore ); %if no croplim exists, 'nocroplimhold' is temporary string insert that gets replaced when user creates croplim

    paramstr = ['moex_' num2str(use_hires.(regionex)) '_' num2str(use_drawn_rois.(regionex)) '_' num2str(num_mroi_auto.(regionex))];
    parstr.mroi.(regionex) = paramstr;

    pth_mroi.(regionex) = [pthstack(1:end-4) regionex '_' croplimstr '_' paramstr '_rois_morph_.mat'];
    pth_mroi_interactive.(regionex) = [pthstack(1:end-4) regionex '_' croplimstr '_interactive_rois_morph_.mat'];
    pth_roi_allmethods.(regionex){1} = pth_mroi.(regionex);

    pth_froi_all_tmp = [];
    for csi = 1:length(caiman_lr_str)
        pth_froi_pat = [pth_fldr recid '_' suffix '_' regionex_nounderscore '_*_cmex_' caiman_lr_str{csi} '_rois_.mat'];
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

    paramstr = [paramstr '_' num2str(numcluster_for_bump_domain_resample.(regionex))];

    % if use_hires(k)
    %     paramstr = [paramstr '_hr_moex_paramtbd_'];
    %     parstr.mroi.(regionex) = [parstr.mroi.(regionex) '_hr_moex_paramtbd'];
    %     if use_caiman_on_hires(k)
    %         paramstr = [paramstr '_hr_cmex_' caiman_hr_str];
    %     end
    % end

    pth_savedata_oneregion.(regionex) = [pth_fldr recid '_' suffix '_' paramstr '_' regionex '_savedata_.mat'];

    pth_caimanfails = [pth_fldr recid '_*_' regionex_nounderscore '_*_cmex_*_FAILURE_.mat'];
    pth_caimanfails2 = [pth_fldr recid '_*_' regionex_nounderscore '_*_cmex_*_NOROIS_.mat'];
    delete_caiman_fails(pth_caimanfails, pth_fldr, regionex_nounderscore)
    delete_caiman_fails(pth_caimanfails2, pth_fldr, regionex_nounderscore)

end


%% hires

pthpat = [pth_fldr recid  '_hires_.tif'];
pth_tmp = rdir(pthpat);
if isempty(pth_tmp)
    pthpat = [pthpat(1:end-4) '.mat'];
    pth_tmp = rdir(pthpat);
    if isempty(pth_tmp)
        pthpat = [pth_fldr num2str(recdatenum) '_' num2str(flynum) '_hires_.tif']; %sometimes hires has no trial in filename (one hires for all trials)
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

pffn = fieldnames(ui.pf);
for pfi = 1:numel(pffn)
    pth.tsuse_nms_prefix.(pffn{pfi}) = [pth_fldr 'tsuse_' pffn{pfi}];
end

pth.tsuse_nms_prefix.mfit = [pth_fldr 'tsuse_finfits_'];
pth.tsuse_nms_prefix.scat = [pth_fldr 'tsuse_finscatter_'];
pth.tsuse_nms_prefix.pltx = [pth_fldr 'tsuse_finpltexp_'];

%% carl's old project 

pth_feat_save = [pth_fldr ui.carl.feat '_lin_ds_.mat'];
pthparent_feat = ui.carl.pthparent_feat;
pth_template = ui.carl.pth_template;

%% assign to struct



pth.prefix = pth_prefix;
pth.fldr = pth_fldr;
pth.stack = pthstack;
pth.hires_prefix = pth_hires_prefix;
pth.hires_mat_matreg = pth_hires_mat_matreg;
pth.froi_hires = pth_froi_hires;
pth.md = pth_md;
pth.flyg_md = pth_flyg_md;
if numregions>0
    pth.mroi = pth_mroi;
    pth.mroi_interactive = pth_mroi_interactive;
    pth.froi_all = pth_froi_all;
    pth.roi_allmethods = pth_roi_allmethods;
    pth.savedata_oneregion = pth_savedata_oneregion;
end
pth.daq = pth_daq;
pth.daqrs = pth_daqrs;
pth.ft.dat = pth_ftdat;
pth.ft.log = pth_ftlog;
pth.ft.vidlog = pth_ftvidlog;
pth.ft.vid = pth_ftvid;
pth.ft.vidrs = pth_ftvidrs;
pth.epochinds = pth_epochinds;
pth.epochinfo = pth_epochinfo;
pth.tmpfiles = pth_tmpfiles;
pth.featsave = pth_feat_save;
pth.parent_feat = pthparent_feat;
pth.template = pth_template;

pth = orderfields_recursive(pth);




