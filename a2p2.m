

clear all
close all
clc
stackid = '20250920_1_3_or';
pthstack = stackfind(stackid=stackid);
s = stackld(pthstack);
o.roi.ma.numroi = {32,64};
optma = ofill(o, 'roi.ma');
roimake(s, rgname={'gal', 'gar'}, roiname='fool', dodraw=1);