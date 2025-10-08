
clearvars
clear glb
clear ofill
close all
clc

stackid = '20251004_4*'; % stackid format is recdate_fly_trial_suffix, or end with * to make everything after the asterisk wildcard

o.roi.domm = 1;
o.roi.mm.mmname = {'opto'};
o.roi.nrm.post = {'z'};

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
    % 
    % stackplt(stacksm(s.stack, method={'movmedian', 'gaussian'}, imrate=s.md.volrate, smlensec=1), ic=1, it=-30)
    % stackplt(stacksm(s.stack, method={'gaussian'}, imrate=s.md.volrate, smlensec=1), ic=1, it=-30)
    stack2 = stacksm(s.stack, method={'gaussian'}, imrate=s.md.volrate, smlensec=1, smlenpx=[3,3,0]);
    stackplt(stack2, ic=1, it=-100)
    s.stack = stack2;
    stack2 = [];

    roi(k) = roimake(o.roi, s=s);


%% 

t = linspace(0, 600, 25000);
eb = roi.dat(1).ts(1:8,:);
nol = roi.dat(1).ts(9,:);
nor = roi.dat(1).ts(10,:);
stim = squeeze(mean(s.stack(:,:,:,:,2), [1:3]));

figure; hold on;  plot(nol); hold on; plot(nor); yyaxis right; plot(stim);

ax = axarr([1,1]);
h = fg(szf=2);
h = axim(eb, h=h, ax=ax, notim=1, noax=0);
hold(h.im.ax{1}, "on")
h.im.pl{1}.XData = t;
plot(h.im.ax{1}, t, rescale(nol, 1, size(eb,1)), color=cmap(1,:), linestyle='-', linewidth=2);
plot(h.im.ax{1}, t, rescale(nor, 1, size(eb,1)), color=cmap(2,:), linestyle='-', linewidth=2);

xlim(lim_t)
title('eb (heatmap), gall left (blue), gall right (red), vish (yellow), ballh yaw (purple)')
numxtick = 20;
h.im.ax{1}.XTick = linspace(lim_t(1), lim_t(2), numxtick);
h.im.ax{1}.XTickLabel = h.im.ax{1}.XTick;
hold(h.im.ax{1}, "on")


%% 


end