% stim = struct2cell(load([pth.dirstack '20241218_3_2_wsraw_0001_sync.mat'], 'si_frame_direction'));
% stim = stim{1};
% lfit(stim, ts.roi.a2{1}, t=ts.t, doplt=1, pixfit=1, usesaved=1, roipx=roidat.a2{1}.roipx, lagsec=0, stack=stack, sortstyle='xyz', flypos=ts.flypos)


pthsync = rdir([pth.prenosuffix '*_sync.mat']);
indvp = struct2cell(load(pthsync.name, 'si_frame_direction'));
indvp = indvp{1};
depvp = ts.roi.a10{1}(1,:);
doplt = 0;

ts.fit = mfit(indvp, depvp, md.volrate, o.mf, doplt, pth.pre, ts.epochinds, stack, roidat.a10{1});
