function o = oset_opto()


do = {'sld', 'daq', 'roi'}; %string of char or cell of char; list of mos to populate in options struct (ie list of a2p modules to enter)

o.sld.ic = [1 2];

o.daq.slopelensec = .3;

o.bmp.domtype = 'm';

bmpindv.tg.daq = ['*'];
bmpindv.tg.vnm = 'vh';
% bmpindv.tg.optid = 'a8';

o.bmp.indv = bmpindv;

bmpdepv.tg.roi.rgname = 'eb';
bmpdepv.tg.roi.mm.mmname = 'eb';
bmpdepv.tg.roi.domm = 1;
bmpdepv.tg.roi.ma.maskseg = 'torus';
bmpdepv.tg.roi.nrm.post = 'f';
bmpdepv.tg.vnm = 'ts';
% bmpdepv.tg.optid = 'a76';
bmpdepv.tg.group = '1';

o.bmp.depv = bmpdepv;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;

rgname = {'eb', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1;

    % o.roi.nrm.post = {'z'};
    % o.roi.nrm.degdtr = 3;

    if strcmp(rgname{m}, 'eb')
        o.roi.mm.mmname = 'eb';
        o.roi.doma = 1; %do automated morph rois
        o.roi.ma.numroi = 32;
        o.roi.ma.maskmake = 'nonzero';
        o.roi.ma.maskseg = 'torus';
        o.roi.ma.roirad = 1.5;
    elseif any(strcmp(rgname{m}, {'gal', 'gar'}))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.mmname = {'dorsal', 'ventral'};
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.mmname = {'left', 'right'};
    end

    o = ofill(o, 'roi');

end


o = ofill(o, mosfinal=do); % mosfinal final ofill call to strip o to only 'mos' listed in input 'do'
