function o = oset_noeb(o)

rgname = {'eb'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doroi = 1; 
o.mn.dofit = 1; 
% o.mn.fe = ["bmp"];


otmp.tg(1).roi.rgname = 'eb';
otmp.tg(1).roi.domm = 1;
otmp.tg(1).roi.mm.maskname = 'none';
otmp.tg(1).vnm = 'ts';
otmp.tg(1).it = 20:200;
otmp.tg(1).ic = 1;

otmp.tg(2).daq.useinds = 'none';
otmp.tg(2).daq.usefbl = 1;
otmp.tg(2).ii = 20:200;

o.mdl.indv = otmp;

otmp = [];
otmp.tg(1).roi.rgname = 'no';
otmp.tg(1).roi.domm = 1;
otmp.tg(1).group = '1';
o.mdl.depv = otmp;

o.mdl.lagsec = 1;
o.mdl.mdlname = 'svd_0.95';
o.mdl.lensec = 1.25;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;
o.bmp.mdl.nrmi = 'none';

o = odf(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois

    o.roi.nrm.post = {'rsc000100'};
    o.roi.nrm.degdtr = 2;

    if strcmp(rgname{m}, 'eb')
        o.roi.doma = 1; %do automated morph rois
        o.roi.ma.numroi = 32;
        o.roi.mm.maskname = 'none';
        o.roi.ma.maskmake = 'edge';
    elseif any(strcmp(rgname{m}, {'no'}))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.maskname = {'left', 'right'};
    end

    o = odf(o, 'roi', rgname{m});

end


