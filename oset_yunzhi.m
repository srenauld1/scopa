function o = oset_yunzhi(o)

o.mn.do = ["s", "dq", "roi"];

o.roi.domm = 1; %do draw rois (since doma=1, you will be limited to drawing one roi; morphological segmentation will occur within this drawn roi)
o.roi.roiname = 'fb8c'; %name of drawn roi, for filename
o.roi.doma = 1; %do automated morphological roi segmentation (if you make this zero, you can draw more rois)
o.roi.ma.numroi = 128; %number auto-rois; must be power of 2

o = ofill(o);

