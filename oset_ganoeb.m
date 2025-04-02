function o = oset_ganoeb(o)

rgname = {'eb', 'gal', 'gar', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doroi = 1; 
o.mn.dobmp = 1; 

o.daq.supprate = 60;
o.daq.slopelensec = 0.4; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in tsdv) to be as short as possible, given sample rate and slopeord
o.daq.slopeord = 2; % order of polynomial used to fit local slope
o.daq.slopelensec_supp = 0.1; % same as slopelensec but for supplemental resampling rate (supprate, if nonempty)
o.daq.slopeord_supp = 2; 

%%%% BMP %%%%

o.bmp.domtype = 'm';
o.bmp.rot = [90 0 0];

bmpindv.tg.daq = ['*'];
bmpindv.tg.vnm = 'vy';

o.bmp.indv = bmpindv;

bmpdepv.tg.roi.rgname = 'eb';
bmpdepv.tg.roi.domm = 1;
bmpdepv.tg.roi.ma.maskseg = 'ell';
bmpdepv.tg.vnm = 'ts';
bmpdepv.tg.group = '1';

o.bmp.depv = bmpdepv;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;

o = odf(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois

    o.roi.nrm.post = {'rsc000100'};
    o.roi.nrm.degdtr = 2;

    if strcmp(rgname{m}, 'eb')
        o.roi.doma = 1; %do automated morph rois
        o.roi.ma.numroi = 32;
        o.roi.mm.maskname = 'eb';
        o.roi.ma.maskmake = 'edge';
        o.roi.ma.maskseg = 'ell';
    elseif any(strcmp(rgname{m}, {'gal', 'gar'}))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.maskname = {'dorsal', 'ventral'};
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.maskname = {'left', 'right'};
    end

    o = odf(o, 'roi', rgname{m});

end


