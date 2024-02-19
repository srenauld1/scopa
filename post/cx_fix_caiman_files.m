

clear all
close all
clc

allcaiman = rdir('~/Documents/ambrose/leprechaunMat/20230627-2_D05_syt7f_018_syt7f/*3dex_rois_.mat');

for aci = 1:length(allcaiman)

    load(allcaiman(aci).name)

    C = single(C);
    dff = single(dff);
    dffr = single(dffr);
    S = single(S);
    roimasks = single(roimasks);
    roimasks_b = single(roimasks_b);
    rval = single(rval);
    snr = single(snr);
    YrA = single(YrA);

    save(allcaiman(aci).name, 'C', 'dff', 'dffr', 'roimasks', 'S', 'roimasks_b', 'snr', 'rval', 'YrA', '-v7.3', '-mat')

end
