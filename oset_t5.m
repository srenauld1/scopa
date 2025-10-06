function o = oset_t5(o)

rgname = {'t5', 'tm'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.do = ["sld", "roi", "fmf", "mdl"];


o.sld.trm = [4,2];


mdlindv.tg.roi.rgname = 'tm';
mdlindv.tg.roi.mm.mmname = 'eleven';
mdlindv.tg.roi.nrm.post = 'dff015020';
mdlindv.tg.vnm = 'ts';
mdlindv.tg.group = '1';

o.mdl.indv = mdlindv;

mdldepv.tg.roi.rgname = 't5';
mdldepv.tg.roi.mm.mmname = 'none';
mdldepv.tg.roi.nrm.post = 'dff015020';
mdldepv.tg.vnm = 'ts';
mdldepv.tg.group = '3';

o.mdl.depv = mdldepv;

o.mdl.mdlname = 'svd_0.95';
o.mdl.lensec = 1.25;

o.fmf.stimtype = 'drone';
o.fmf.id = 'CON_51';
o.fmf.pthpar = '/Users/wienecke/ds/data/rec';
o.fmf.pthtemplate = '/Users/wienecke/ds/data/stimuli';

for m = 1:numel(rgname) 

    o.roi.rgname = rgname{m};
    o.roi.domm = 1;
    if strcmp(rgname{m}, 'tm')
        o.roi.mm.mmname = 'eleven2';
        o.roi.doma = 0;
        o.roi.ma.numroi = 1024;
    elseif strcmp(rgname{m}, 't5')
        o.roi.mm.mmname = 'newrois';
        o.roi.doma = 0;
    end
    o.roi.nrm.post = 'dff015020';
    o = ofill(o, 'roi');
    % o = ofill(o, 'roi', rgname{m});

end


