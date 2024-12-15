function [wcoh, wcs] = wcoherence_cw(wsstx, wssty, scales, nov)

Nscale = fix(size(wsstx,1)/2);
numscales_to_smooth = min(floor(numel(scales)/2),nov);

validateattributes(numscales_to_smooth,{'numeric'},{'scalar','integer','positive','<=',...
    Nscale},'wcoherence','NumScalesToSmooth');
cfs1 = smoothCFS_cw(abs(wsstx).^2,scales,numscales_to_smooth);
cfs2 = smoothCFS_cw(abs(wssty).^2,scales,numscales_to_smooth);
crossCFS = wsstx.*conj(wssty);
crossCFS = smoothCFS_cw(crossCFS,scales,numscales_to_smooth);
wcs = crossCFS./(sqrt(cfs1).*sqrt(cfs2));
wcoh = abs(crossCFS).^2./(cfs1.*cfs2);
wcoh = min(wcoh,1,'includenan');

end