function o = oset_t5(o)

rgname = {'t5', 'tm'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doroi = 1; 
o.mn.dofit = 1; 

o.mn.fe = ["fmf"]; 


o.sld.trm = [4,2];


mdlindv.tg.roi.rgname = 'tm';
mdlindv.tg.roi.domm = 1;
mdlindv.tg.roi.mm.maskname = 'ten';
mdlindv.tg.vnm = 'ts';

o.mdl.indv = mdlindv;

mdldepv.tg.roi.rgname = 't5';
mdldepv.tg.roi.domm = 1;
mdldepv.tg.group = '1';
mdldepv.tg.vnm = 'ts';

o.mdl.depv = mdldepv;

o.mdl.mdlname = 'svd_0.95';
o.mdl.lensec = 1.25;

o.fmf.stimtype = 'drone';
o.fmf.id = 'CON_51';
o.fmf.pthparent = '/Users/wienecke/ds/data/rec';
o.fmf.pthtemplate = '/Users/wienecke/ds/data/stimuli';

for m = 1:numel(rgname) 

    o.roi.rgname = rgname{m};
    o.roi.domm = 1;
    if strcmp(rgname{m}, 'tm')
        o.roi.doma = 0;
        o.roi.mm.maskname = 'ten';
        o.roi.ma.numroi = 1024;
    else
        o.roi.doma = 0;
    end
    o = odf(o, 'roi', rgname{m});

end


