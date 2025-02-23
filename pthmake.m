function pth = pthmake(o)


%%set up filenames for a2p; most a2p filenames are set here for convenience (should they all be? all required files are here i think)

id = o.id;

pthstack = o.id.pthstack;
recdatenum = id.recdatenum;
flynum = id.flynum;
trialnum = id.trialnum;
suffix = id.suffix;
recid = id.recid;
datefly_hyphen = id.datefly_hyphen;

rgname = fieldnames(o.roi);
dirtmp = o.mn.dirtmp;

%% files before roimake

[pthstackdir, ~, ~] = fileparts(pthstack);
pthstackdir = [pthstackdir filesep];

pth_prefix = erase(pthstack, '.mat');
pth_recid = [pthstackdir recid '_'];

pth_py = o.mn.pthpy;


pthmd = [pthstackdir recid '_mdsi_.txt'];
pthmd_flyg_pat = [pthstackdir datefly_hyphen '_metadata_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
pthmd_flyg = rdir(pthmd_flyg_pat);
if isempty(pthmd_flyg)
    pthmd_flyg = [];
else
    pthmd_flyg = pthmd_flyg.name;
end

pth_daq_pat = [pthstackdir datefly_hyphen '_daqData_*_trial_' sprintf( '%03d', trialnum ) '.mat'];
pth_daq = rdir(pth_daq_pat);
if isempty(pth_daq)
    pth_daq = [];
else
    pth_daq = pth_daq.name;
end

pth_daqrs = [pthstackdir recid '_daqrs_.mat'];

% pth_ftvid_pat = [pthstackdir 'FicTracData' filesep 'fictrac-raw-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.avi']; %original ft video
pth_ftdat_pat = [pthstackdir 'FicTracData' filesep 'fictrac-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.dat']; %
pth_ftdat = rdir(pth_ftdat_pat);
if isempty(pth_ftdat)
    pth_ftdat = [];
else
    pth_ftdat = pth_ftdat.name;
end

pth_ftlog_pat = [pthstackdir 'FicTracData' filesep 'fictrac-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.log']; %
pth_ftlog = rdir(pth_ftlog_pat);
if isempty(pth_ftlog)
    pth_ftlog = [];
else
    pth_ftlog = pth_ftlog.name;
end


pth_ftvidlog_pat = [pthstackdir 'FicTracData' filesep 'fictrac-vidLogFrames-' num2str(recdatenum) '*_trial_' sprintf( '%03d', trialnum ) '.txt']; %
pth_ftvidlog = rdir(pth_ftvidlog_pat);
if isempty(pth_ftvidlog)
    pth_ftvidlog = [];
else
    pth_ftvidlog = pth_ftvidlog.name;
end

pth_ftvid_pat = [pthstackdir recid '_FTV_DS_.mat']; %downsampled ft video (downsampled in register.py)
pth_ftvid = rdir(pth_ftvid_pat);
if isempty(pth_ftvid)
    pth_ftvid = [];
    pth_ftvidrs = [];
else
    pth_ftvid = pth_ftvid.name;
    pth_ftvidrs = [pth_ftvid(1:end-4) 'RS_.mat'];
end

pth_ts = [pthstackdir recid '_ts_.mat'];

%% carl's old project

pth_feat_save = [pthstackdir o.feat.id '_lin_ds_.mat'];
pthparentfeat = o.feat.pthparent;
pthtemplate = o.feat.pthtemplate;


%% output

pth.pre = pth_prefix;
pth.recid = pth_recid;
pth.py = pth_py;
pth.pthstackdir = pthstackdir;
pth.stack = pthstack;
pth.md = pthmd;
pth.mdflyg = pthmd_flyg;
pth.daq = pth_daq;
pth.daqrs = pth_daqrs;
pth.ftdat = pth_ftdat;
pth.ftlog = pth_ftlog;
pth.ftvidlog = pth_ftvidlog;
pth.ftvid = pth_ftvid;
pth.ftvidrs = pth_ftvidrs;
pth.ts = pth_ts;
pth.featsave = pth_feat_save;
pth.featparent = pthparentfeat;
pth.template = pthtemplate;

pth = structsort(pth);




