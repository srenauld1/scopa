function o = oset_sophia()

do = ["sld", "daq", "roi"];

o.daq.supprate = 60; %supplemental resampling rate (in addition to imaging rate); empty to skip supplemental resampling
o.daq.slopelensec = 0.4; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in tsdv) to be as short as possible, given sample rate and slopeord
o.daq.slopeord = 2; % order of polynomial used to fit local slope
o.daq.slopelensec_supp = 0.1; % same as slopelensec but for supplemental resampling rate (supprate, if nonempty)
o.daq.slopeord_supp = 2; 

o = ofill(o);

rgname = {'none'}; % use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;
for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};
    
    if strcmp(rgname{m}, 'none')
        o.roi.mm.mmname = {'none'};
        o.roi.nrm.post = {'dff008000'};
    end

    o = ofill(o, mosc={'roi', rgname{k}});

end

o = ofill(o, mosfinal=do); % mosfinal final ofill call to strip o to only 'mos' listed in input 'do'
