function o = oset_jingxuan(o)

rgname = {'none'}; % use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;


o.daq.slopelensec = 0.43; %this works for sample rate 5.8251; make this as short as possible while window_is_too_short is still false, where slopeord is always 2, and samprate is the voluem rate if volumetric, or framerate if non-volumetric; slopeord = 2; slopelen = round(o.daq.slopelensec / (1/samprate)); window_is_too_short = slopelen<slopeord+1

o = ofill(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};


    if strcmp(rgname{m}, 'none')
        o.roi.mm.roiname = {'none'};
        o.roi.nrm.post = {'dff008000'};
    end

    o = ofill(o, 'roi', rgname{m});

end

