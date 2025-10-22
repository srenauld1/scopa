function o = oset_elno(o)


o.mn.do = ["sld", "daq", "roi", "bmp"];

rgname = {'el', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

%%%% BMP %%%%

bmpindv.vg.daq = ['*'];
bmpindv.vg.vnm = 'vh';

o.bmp.indv = bmpindv;

bmpdepv.vg.roi.rgname = 'el';
bmpdepv.vg.roi.mm.roiname = 'el3';
bmpdepv.vg.roi.domm = 1;
bmpdepv.vg.vnm = 'ts';
bmpdepv.vg.group = '1';

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
        o.roi.mm.roiname = 'el3';
        o.roi.ma.maskmake = 'nonzero';
        o.roi.ma.maskseg = 'torus';
        o.roi.ma.roirad = 3;
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.roiname = {'left2', 'right2'};
    end

    o = ofill(o, 'roi', rgname{m});

end


