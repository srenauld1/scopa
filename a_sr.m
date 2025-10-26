
clearvars
clear glb
clear ofill
close all
clc

stackid = '20251006_7_1_or'; % stackid format is recdate_fly_trial_suffix, or end with * to make everything after the asterisk wildcard

o.dq.supprate = 60; %supplemental resampling rate (in addition to imaging rate); empty to skip supplemental resampling
o.dq.dvlensec = 0.4; % window length in seconds used to fit slope to each dq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in vecdv) to be as short as possible, given sample rate and dvord
o.dq.dvord = 2; % order of polynomial used to fit local slope
o.dq.dvlensec_supp = 0.1; % same as dvlensec but for supplemental resampling rate (supprate, if nonempty)
o.dq.dvord_supp = 2; 
o.dq.voltminhd = -pi;  %heading angle (radians) assigned to voltmin and voltmax

o.roi.domm = 1;
o.roi.roiname = {'none'};
o.roi.nrm.post = {'dff008000'};

o = ofill(o);

pthtmp = stackfind(stackid=stackid, err=1);
if ~iscell(pthtmp)
    pthtmp = {pthtmp};
end

for k = 1:numel(pthtmp)

    s = stackld(pthtmp{k});
    
    pthstackfld = idmake(s.pth, 'pthstackfld');
    glb(1, pthstackfld=pthstackfld) %set this global in glb because it gets used repeatedly in nested functions and we don't want to pass this around everywhere

    dq(k) = daqld(o.dq, pthstack=s.pth);

    roi(k) = roimake(o.roi, s=s);

end