
clearvars
clear glb
clear ofill
close all
clc

stackid = '20251007_*'; % stackid format is recdate_fly_trial_suffix, or end with * to make everything after the asterisk wildcard

o.roi.domm = 1;
o.roi.mm.mmname = {'opto'};
o.roi.nrm.post = {'f'};

o = ofill(o);

pthtmp = stackfind(stackid=stackid, err=1);
if ~iscell(pthtmp)
    pthtmp = {pthtmp};
end

for k = 1:numel(pthtmp)

    s = stackld(pthtmp{k});
    
    id = idmake(s.pth);
    glb(1, pthstackdir=id.pthstackdir) %set this global in glb because it gets used repeatedly in nested functions and we don't want to pass this around everywhere

    % daq = daqld(o.daq, pthstack=s.pth);

    stackplt(stacksm(s.stack, method={'movmedian', 'gaussian'}, imrate=s.md.volrate, smlensec=1), ic=1, it=-100)
    % stack2 = stacksm(s.stack, method={'gaussian', 'movmedian'}, imrate=s.md.volrate, smlensec=1);
    % stackplt(stack2, ic=1, it=-100)

    % roi(k) = roimake(o.roi, s=s);

end