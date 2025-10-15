function a_opto(roi, s, t)

cmap = lines(8);


%% 

ieb = fieldmatch(roi, {'rg.rgname', 'eb'}, {'mm.mmname', 'eb'}, lev=1);
inl = fieldmatch(roi, {'rg.rgname', 'no'}, {'mm.mmname', 'left'}, lev=1);
inr = fieldmatch(roi, {'rg.rgname', 'no'}, {'mm.mmname', 'right'}, lev=1);

eb_or = roi.(ieb).dat(1).ts;
nol_or = roi.(inl).dat(1).ts;
nor_or = roi.(inr).dat(1).ts;

stim_or = squeeze(mean(s.stack(:,:,:,:,2), [1:3]))';

%% 

id = idmake(s.pth);
pthraw = stackfind(stackid=[id.recid '_o']);
sraw = stackld(pthraw);

clear ofill
o.roi.rgname = 'eb';
o = ofill(o, mosfinal='roi');
o = o.roi;
roimask_ieb_or = {roi.(ieb).dat(1).mask, roi.(ieb).dat(2).mask};
roiraw_eb = roimake(o, s=sraw, roimask=roimask_ieb_or);


clear ofill
o.roi.rgname = 'no';
o = ofill(o, mosfinal='roi');
o = o.roi;
roimask_inl_or = {roi.(inl).dat(1).mask, roi.(inl).dat(2).mask};
roiraw_nol = roimake(o, s=sraw, roimask=roimask_inl_or);


clear ofill
o.roi.rgname = 'no';
o = ofill(o, mosfinal='roi');
o = o.roi;
roimask_inr_or = {roi.(inr).dat(1).mask, roi.(inr).dat(2).mask};
roiraw_nor = roimake(o, s=sraw, roimask=roimask_inr_or);


ieb_raw = fieldmatch(roiraw, {'rg.rgname', 'eb'}, {'mm.mmname', 'eb'}, lev=1);
inl_raw = fieldmatch(roiraw, {'rg.rgname', 'no'}, {'mm.mmname', 'left'}, lev=1);
inr_raw = fieldmatch(roiraw, {'rg.rgname', 'no'}, {'mm.mmname', 'right'}, lev=1);

eb_raw = roiraw_eb.dat(1).ts;
nol_raw = roiraw_nol.dat(1).ts;
nor_raw = roiraw_nor.dat(1).ts;

stim_raw = squeeze(mean(sraw.stack(:,:,:,:,2), [1:3]))';

%% 

stim_raw_sm = smoothdata(stim_raw, 2, 'gaussian', 30);
eb_raw_sm = smoothdata(eb_raw, 2, 'gaussian', 30);
nol_raw_sm = smoothdata(nol_raw, 2, 'gaussian', 30);
nor_raw_sm = smoothdata(nor_raw, 2, 'gaussian', 30);
figure; hold on;  plot(t, nol_raw_sm); hold on; plot(t, nor_raw_sm); yyaxis right; plot(t, stim_raw_sm);


figure; hold on;  plot(t, nol_raw_sm); hold on; plot(t, nor_raw_sm); yyaxis right; plot(t, stim_raw_sm);

%% 


stim_or_sm = smoothdata(stim_or, 2, 'gaussian', 30);
eb_or_sm = smoothdata(eb_or, 2, 'gaussian', 30);
nol_or_sm = smoothdata(nol_or, 2, 'gaussian', 30);
nor_or_sm = smoothdata(nor_or, 2, 'gaussian', 30);
figure; hold on;  plot(t, nol_or_sm); hold on; plot(t, nor_or_sm); yyaxis right; plot(t, stim_or_sm);

%% 

its = t2i([140:.1:170], t);
stackplt(sraw.stack, it=its, ic=1)

%% 


figure; hold on;  plot(nol_or); hold on; plot(nor_or); yyaxis right; plot(stim);
figure; hold on;  plot(nol_raw); hold on; plot(nor_raw); yyaxis right; plot(stim_raw);

ax = axarr([1,1]);
h = fg(szf=2);
h = axim(eb_or, h=h, ax=ax, notim=1, noax=0);
hold(h.im.ax{1}, "on")
h.im.pl{1}.XData = t;
plot(h.im.ax{1}, t, rescale(nol_or, 1, size(eb_or,1)), color=cmap(1,:), linestyle='-', linewidth=2);
plot(h.im.ax{1}, t, rescale(nor_or, 1, size(eb_or,1)), color=cmap(2,:), linestyle='-', linewidth=2);

xlim(lim_t)
title('eb (heatmap), gall left (blue), gall right (red), vish (yellow), ballh yaw (purple)')
numxtick = 20;
h.im.ax{1}.XTick = linspace(lim_t(1), lim_t(2), numxtick);
h.im.ax{1}.XTickLabel = h.im.ax{1}.XTick;
hold(h.im.ax{1}, "on")


%% 


end