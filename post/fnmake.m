function pth = fnmake(o)


%%set up filenames for a2p

id = o.id;

pthstack = o.id.pthstack;
recdatenum = id.recdatenum;
flynum = id.flynum;
trialnum = id.trialnum;
suffix = id.suffix;
recid = id.recid;
datefly_hyphen = id.datefly_hyphen;

regionex = fieldnames(o.roi);
dirtmp = o.mn.dirtmp;

%% files before roimake

[dirstack, ~, ~] = fileparts(pthstack);
dirstack = [dirstack filesep];

pth_prefix = [dirstack recid '_'];

tmp = strsplit(dirstack, filesep);
pth_parent = [strjoin(tmp(1:end-2), filesep) filesep];

pth_tmpfiles = [pth_parent dirtmp filesep];
if ~isfolder(pth_tmpfiles)
    mkdir(pth_tmpfiles)
end

pth_md = [dirstack recid '_mdsi_.txt'];
pth_mdflyg_pat = [dirstack datefly_hyphen '_metadata_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
pth_mdflyg = rdir(pth_mdflyg_pat);
if isempty(pth_mdflyg)
    pth_mdflyg = [];
else
    pth_mdflyg = pth_mdflyg.name;
end

pth_daq_pat = [dirstack datefly_hyphen '_daqData_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
pth_daq = rdir(pth_daq_pat);
if isempty(pth_daq)
    pth_daq = [];
else
    pth_daq = pth_daq.name;
end

pth_daqrs = [dirstack recid '_daqrs_.mat'];

% pth_ftvid_pat = [dirstack 'FicTracData' filesep 'fictrac-raw-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.avi']; %original ft video
pth_ftdat_pat = [dirstack 'FicTracData' filesep 'fictrac-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.dat']; %
pth_ftdat = rdir(pth_ftdat_pat);
if isempty(pth_ftdat)
    pth_ftdat = [];
else
    pth_ftdat = pth_ftdat.name;
end

pth_ftlog_pat = [dirstack 'FicTracData' filesep 'fictrac-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.log']; %
pth_ftlog = rdir(pth_ftlog_pat);
if isempty(pth_ftlog)
    pth_ftlog = [];
else
    pth_ftlog = pth_ftlog.name;
end


pth_ftvidlog_pat = [dirstack 'FicTracData' filesep 'fictrac-vidLogFrames-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.txt']; %
pth_ftvidlog = rdir(pth_ftvidlog_pat);
if isempty(pth_ftvidlog)
    pth_ftvidlog = [];
else
    pth_ftvidlog = pth_ftvidlog.name;
end

pth_ftvid_pat = [dirstack recid '_FTV_DS_.mat']; %downsampled ft video (downsampled in register.py)
pth_ftvid = rdir(pth_ftvid_pat);
if isempty(pth_ftvid)
    pth_ftvid = [];
    pth_ftvidrs = [];
else
    pth_ftvid = pth_ftvid.name;
    pth_ftvidrs = [pth_ftvid(1:end-4) 'RS_.mat'];
end

pth_epochinds = [dirstack recid '_epochinds_.bin'];
pth_epochinfo = [dirstack recid '_epochinfo_.mat'];


%% hires

fntmp = fieldnames(o.roi);
for k = 1:numel(fntmp)
    if isfield(o.roi.(fntmp{k}), 'ma')
        usehires(k) = o.roi.(fntmp{k}).ma.usehires; %gets updated to numeric struct, fieldname usehires
    else
        usehires(k) = 0;
    end
end

pth_hires_prefix = [];
pth_hires_mat_matreg = [];
pth_roif_hires = [];
if any(usehires) %for each recording, dohires if any regionex have usehires true (since we want to load/process hires once before looping over regionex)
    pthpat = [dirstack recid  '_hires_.tif'];
    pth_tmp = rdir(pthpat);
    if isempty(pth_tmp)
        pthpat = [pthpat(1:end-4) '.mat'];
        pth_tmp = rdir(pthpat);
        if isempty(pth_tmp)
            pthpat = [dirstack num2str(recdatenum) '_' num2str(flynum) '_hires_.tif']; %sometimes hires has no trial in filename (one hires for all trials)
            pth_tmp = rdir(pthpat);
            if isempty(pth_tmp)
                pthpat = [pthpat(1:end-4) '.mat'];
                pth_tmp = rdir(pthpat);
            end
        end
    end
    if isempty(pth_tmp)
        fprintf("WARNING, USER REQUESTED usehires FOR AT LEAST ONE REGIONEX BUT NO FILE WITH SUFFIX hires CAN BE FOUND" + newline)
    else
        pth_hires_prefix = pth_tmp.name(1:end-4);
        pth_hires_mat_matreg = [pth_hires_prefix 'hires_matreg_.mat'];
        pth_roif_hires = [pth_hires_prefix '_roishires_.mat'];
    end
end


%% files for roimake

for k = 1:numel(regionex)
    pth_roi.(regionex{k}) = [pthstack(1:end-4) regionex{k} '_roi_.mat'];
    pth_roif.(regionex{k}) = [pthstack(1:end-4) regionex{k} '_roif_.mat'];
    pth_roii.(regionex{k}) = [pthstack(1:end-4) regionex{k} '_roii_.mat'];
end

%% carl's old project

pth_feat_save = [dirstack o.carl.feat '_lin_ds_.mat'];
pthparent_feat = o.carl.pthparent_feat;
pth_template = o.carl.pth_template;


%% output

pth.prefix = pth_prefix;
pth.parent = pth_parent;
pth.dirstack = dirstack;
pth.stack = pthstack;
pth.md = pth_md;
pth.mdflyg = pth_mdflyg;
pth.tmpfiles = pth_tmpfiles;
pth.roi = pth_roi;
pth.roif_all = pth_roif;
pth.roi_interactive = pth_roii;
pth.daq = pth_daq;
pth.daqrs = pth_daqrs;
pth.ftdat = pth_ftdat;
pth.ftlog = pth_ftlog;
pth.ftvidlog = pth_ftvidlog;
pth.ftvid = pth_ftvid;
pth.ftvidrs = pth_ftvidrs;
pth.epochinds = pth_epochinds;
pth.epochinfo = pth_epochinfo;
pth.hires_prefix = pth_hires_prefix;
pth.hires_mat_matreg = pth_hires_mat_matreg;
pth.roif_hires = pth_roif_hires;
pth.featsave = pth_feat_save;
pth.parent_feat = pthparent_feat;
pth.template = pth_template;

pth = structsort(pth);




