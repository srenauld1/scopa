
clearvars
clear glb
clear ofill
close all
clc

stackid = '20251006_7_1_or'; % stackid format is recdate_fly_trial_suffix, or end with * to make everything after the asterisk wildcard

do = {'sld', 'dq', 'roi'}; %modules to run

o.dq.dvlensec = 0.4; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in vecdv) to be as short as possible, given sample rate and dvord
o.dq.dvord = 2; % order of polynomial used to fit local slope
o.dq.voltminhd = glbfile('voltminhd_flyclock_berg2')/12 * 2*pi; %glbfile('voltminhd_flyclock_berg2') is 6 (o clock), so voltminhd is -pi; voltminhd is heading angle (radians) assigned to voltmin and voltmax

o.roi.dodraw = 1;
o.roi.roiname = {'ves041'};
o.roi.nrm.nrmstr = {'dff008000'};

o = ofill(o, mosfinal=do); % mosfinal final ofill call to strip o to only 'mos' listed in input 'do'

pthtmp = stackfind(stackid=stackid, err=1);
if ~iscell(pthtmp)
    pthtmp = {pthtmp};
end

for m = 1:numel(pthtmp)

    prs = struct2pairs(o.sld(m));
    s(m) = stackld(pthtmp{m}, prs{:}, doplt=0);

    glb(1, pthsvdir=idmake(s.pth, 'pthstackfld')) %set this global in glb because it gets used repeatedly in nested functions and we don't want to pass this around everywhere

    prs = struct2pairs(o.dq(m));
    dq(m) = daqld(o.id.pthdaq, prs{:}, doplt=0);

    prs = struct2pairs(o.roi(m));
    roi(m) = roimake(s, prs{:}, doplt=0);

end