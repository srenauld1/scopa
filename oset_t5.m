function o = oset_t5(o)

%NOTE: deprecated argument trm was trm = [4,2], how many samples to remove from [start, end] of stack/responses; remember variable 'cropdata' in function 'rec6' (also applied in function 'metrics2' without variable name 'cropdata'), which cropped first 4 and last 2 imaging frames (stimulus features, and deprecated variable 'responses', have been extracted with this cropping in function 'rec6')


rgname = {'t5', 'tm'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.do = ["sld", "roi", "fmf", "mdl"];


mdlindv.vg.roi.rgname = 'tm';
mdlindv.vg.roi.mm.roiname = 'eleven';
mdlindv.vg.roi.nrm.post = 'dff015020';
mdlindv.vg.vnm = 'ts';
mdlindv.vg.group = '1';

o.mdl.indv = mdlindv;

mdldepv.vg.roi.rgname = 't5';
mdldepv.vg.roi.mm.roiname = 'none';
mdldepv.vg.roi.nrm.post = 'dff015020';
mdldepv.vg.vnm = 'ts';
mdldepv.vg.group = '3';

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
        o.roi.mm.roiname = 'eleven2';
        o.roi.doma = 0;
        o.roi.ma.numroi = 1024;
    elseif strcmp(rgname{m}, 't5')
        o.roi.mm.roiname = 'newrois';
        o.roi.doma = 0;
    end
    o.roi.nrm.post = 'dff015020';
    o = ofill(o, 'roi');
    % o = ofill(o, 'roi', rgname{m});

end


