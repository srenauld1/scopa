function o = oset_elno(o)

rgname = {'el', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doroi = 1; 
o.mn.dobmp = 1; 


%%%% BMP %%%%

bmpindv.tg.daq = ['*'];
bmpindv.tg.vnm = 'vy';

o.bmp.indv = bmpindv;

bmpdepv.tg.roi.rgname = 'el';
bmpdepv.tg.roi.mm.mmname = 'el3';
bmpdepv.tg.roi.domm = 1;
bmpdepv.tg.vnm = 'ts';
bmpdepv.tg.group = '1';

o.bmp.depv = bmpdepv;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;

% o.bmp.mdl.opl.MaxFunctionEvaluations = Inf; %3000;
% o.bmp.mdl.opl.MaxIterations = 5000; %1000    else

o = ofill(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois

    % o.roi.nrm.post = {'f'};
    % o.roi.nrm.degdtr = 2;

    if strcmp(rgname{m}, 'el')
        o.roi.doma = 1; %do automated morph rois
        o.roi.ma.numroi = 32;
        o.roi.mm.mmname = 'el3';
        o.roi.ma.maskmake = 'nonzero';
        o.roi.ma.maskseg = 'torus';
        o.roi.ma.roirad = 3;
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.mmname = {'left2', 'right2'};
    end

    o = ofill(o, 'roi', rgname{m});

end


