function o = oset_ebno(o)


o.mn.do = ["sld", "daq", "roi", "bmp"];

rgname = {'eb', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

%%%% DAQ %%%%

o.daq.slopelensec = 0.4;

%%%% BMP %%%%


o.bmp.slopelensec = 0.4;
o.bmp.domtype = 'f';

bmpindv.vg.daq = ['*'];
bmpindv.vg.vnm = 'by';

o.bmp.indv = bmpindv;

bmpdepv.vg.roi.rgname = 'eb';
bmpdepv.vg.roi.domm = 1;
bmpdepv.vg.roi.ma.maskseg = 'torus';
bmpdepv.vg.roi.ma.numroi = 16;
bmpdepv.vg.roi.nrm.post = 'f';
bmpdepv.vg.vnm = 'ts';
bmpdepv.vg.group = '1';

o.bmp.depv = bmpdepv;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;


%%%% MDL %%%%

mdlindv.vg.bmp = ['*'];
mdlindv.vg.vnm = 'vel';
mdlindv.vg.group2 = '1';
mdlindv.vg(2).daq = ['*'];
mdlindv.vg(2).vnm = 'bvy';

o.mdl.indv = mdlindv;

mdldepv.vg.roi.rgname = 'no';
mdldepv.vg.group = '3';
mdldepv.vg.vnm = 'ts';

o.mdl.depv = mdldepv;

o.mdl.mdlname = {'svd_0.95', 'svd_0.7'};
o.mdl.lensec = {0.5, 1, 1.5, 2};

o = ofill(o);

%%%% ROI %%%%

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois

    % o.roi.nrm.post = {'z'};
    % o.roi.nrm.degdtr = [];

    if strcmp(rgname{m}, 'eb')
        o.roi.doma = 1; %do automated morph rois
        o.roi.ma.numroi = 16;
        o.roi.roiname = 'eb';
        o.roi.ma.maskmake = 'nonzero';
        o.roi.ma.maskseg = 'torus';
        o.roi.ma.roirad = 3;
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.doma = 0; %do automated morph rois
        o.roi.roiname = {'left', 'right'};
    end

    o = ofill(o, 'roi', rgname{m});

end


