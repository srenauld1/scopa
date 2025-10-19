function o = oset_ebgano(o)


do = {'sld', 'daq', 'roi', 'bmp'};

rgname = {'eb', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.daq.slopelensec = .49;

%%%% BMP %%%%

o.bmp.domtype = 'm';

bmpindv.vg.daq = ['*'];
bmpindv.vg.vnm = 'by';
% bmpindv.vg.optid = 'a8';

o.bmp.indv = bmpindv;

bmpdepv.vg.roi.rgname = 'eb';
bmpdepv.vg.roi.mm.mmname = 'eb';
bmpdepv.vg.roi.ma.maskseg = 'torus';
bmpdepv.vg.roi.nrm.post = 'f';
bmpdepv.vg.vnm = 'ts';
% bmpdepv.vg.optid = 'a76';
bmpdepv.vg.group = '1';

o.bmp.depv = bmpdepv;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;

o = ofill(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    % o.roi.nrm.post = {'z'};
    % o.roi.nrm.degdtr = 3;

    if strcmp(rgname{m}, 'eb')
        o.roi.mm.mmname = 'eb';
        o.roi.ma.numroi = {32, 64};
        o.roi.ma.maskmake = 'nonzero';
        o.roi.ma.maskseg = 'torus';
        o.roi.ma.roirad = 1.5;
    elseif any(strcmp(rgname{m}, {'gal', 'gar'}))
        o.roi.mm.mmname = {'dorsal', 'ventral'};
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.mm.mmname = {'left', 'right'};
    end

    o = ofill(o, mosc={'roi', rgname{m}});

end

o = ofill(o, mosfinal=do);


