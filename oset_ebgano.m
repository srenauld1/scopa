function o = oset_ebgano(o)


do = {'sld', 'dq', 'roi', 'bmp'};

rgname = {'eb', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.dq.dvlensec = .49;

%%%% BMP %%%%

o.bmp.domtype = 'm';

o.bmp.indv.vg.dq = ['*'];
o.bmp.indv.vg.vnm = 'by';
% o.bmp.indv.vg.optid = 'a8';

o.bmp.depv.vg.roi.rgname = 'eb';
o.bmp.depv.vg.roi.roiname = 'eb';
o.bmp.depv.vg.roi.ma.maskseg = 'torus';
o.bmp.depv.vg.roi.nrm.post = 'f';
o.bmp.depv.vg.vnm = 'ts';
% o.bmp.depv.vg.optid = 'a76';
o.bmp.depv.vg.group = '1';

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;

o = ofill(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    % o.roi.nrm.post = {'z'};
    % o.roi.nrm.degdtr = 3;

    if strcmp(rgname{m}, 'eb')
        o.roi.roiname = 'eb';
        o.roi.dodraw = 1;
        o.roi.ma.numroi = {32, 64};
        o.roi.ma.maskmake = 'nonzero';
        o.roi.ma.maskseg = 'torus';
        o.roi.ma.roirad = 1.5;
    elseif any(strcmp(rgname{m}, {'gal', 'gar'}))
        o.roi.roiname = {'dorsal', 'ventral'};
        o.roi.dodraw = 1;
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.roiname = {'left', 'right'};
        o.roi.dodraw = 1;
    end

    o = ofill(o, mosc={'roi', rgname{m}});

end

o = ofill(o, mosfinal=do);


