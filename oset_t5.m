function o = oset_t5(o)

rgname = {'t5', 'tm'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doftv = 0; 
o.mn.dofeat = 1; 
o.mn.doroi = 1; 
o.mn.dobmp = 0; 
o.mn.dofit = 1; 
o.mn.dopltx = 0; 
o.mn.plt = [""]; 
o.mn.pltvis = 1; 

o.spr.sld.trm = [4,2];
o.mdl.lagsec = 0;
o.mdl.mdlname = 'svd_0.7';
o.mdl.lensec = 1.25;
o.feat.stimtype = 'drone';
o.feat.id = 'CON_51';
o.feat.pthparent = '/Users/wienecke/ds/data/rec';
o.feat.pthtemplate = '/Users/wienecke/ds/data/stimuli';

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


