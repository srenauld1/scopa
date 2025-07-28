function pth = pthmake(pthstack)


%%paths for a2p; several a2p filenames are set here for convenience (should they all be? or none of them? some are not passed into their functions and instead set inside functions)

id = idmake(pthstack);

%% files before roimake

[pthstackdir, ~, ~] = fileparts(id.pthstack);
pthstackdir = [pthstackdir filesep];

pth_prefix = erase(id.pthstack, '.mat');
pth_recid = [pthstackdir id.recid '_'];


pthmd = [pthstackdir id.recid '_mdsi_.txt'];
pthmd_flyg_pat = [pthstackdir id.recdate '-' id.fly '_metadata_*_trial_' sprintf( '%03d', id.trialnum ) '.mat'];
pthmd_flyg = rdir(pthmd_flyg_pat);
if isempty(pthmd_flyg)
    pthmd_flyg = [];
else
    pthmd_flyg = pthmd_flyg.name;
end

pth_daq_pat = [pthstackdir id.recdate '-' id.fly  '_daqData_*_trial_' sprintf( '%03d', id.trialnum ) '.mat'];
pth_daq = rdir(pth_daq_pat);
if isempty(pth_daq)
    pth_daq = [];
else
    pth_daq = pth_daq.name;
end

pth_daqrs = [pthstackdir id.recid '_daq_.mat'];

% pth_ftvid_pat = [pthstackdir 'FicTracData' filesep 'fictrac-raw-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.avi']; %original ft video
pth_ftdat_pat = [pthstackdir 'FicTracData' filesep 'fictrac-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.dat']; %
pth_ftdat = rdir(pth_ftdat_pat);
if isempty(pth_ftdat)
    pth_ftdat = [];
else
    pth_ftdat = pth_ftdat.name;
end

pth_ftlog_pat = [pthstackdir 'FicTracData' filesep 'fictrac-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.log']; %
pth_ftlog = rdir(pth_ftlog_pat);
if isempty(pth_ftlog)
    pth_ftlog = [];
else
    pth_ftlog = pth_ftlog.name;
end


pth_ftvidlog_pat = [pthstackdir 'FicTracData' filesep 'fictrac-vidLogFrames-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.txt']; %
pth_ftvidlog = rdir(pth_ftvidlog_pat);
if isempty(pth_ftvidlog)
    pth_ftvidlog = [];
else
    pth_ftvidlog = pth_ftvidlog.name;
end

pth_ftvid_pat = [pthstackdir id.recid '_FTV_DS_.mat']; %downsampled ft video (downsampled in register.py)
pth_ftvid = rdir(pth_ftvid_pat);
if isempty(pth_ftvid)
    pth_ftvid = [];
    pth_ftvidrs = [];
else
    pth_ftvid = pth_ftvid.name;
    pth_ftvidrs = [pth_ftvid(1:end-4) 'RS_.mat'];
end




%% output

pth.pre = pth_prefix;
pth.recid = pth_recid;
pth.stackdir = pthstackdir;
pth.stack = id.pthstack;
pth.md = pthmd;
pth.mdflyg = pthmd_flyg;
pth.daq = pth_daq;
pth.daqrs = pth_daqrs;
pth.ftdat = pth_ftdat;
pth.ftlog = pth_ftlog;
pth.ftvidlog = pth_ftvidlog;
pth.ftvid = pth_ftvid;
pth.ftvidrs = pth_ftvidrs;

pth = structsort(pth);




