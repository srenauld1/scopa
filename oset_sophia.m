function o = oset_sophia(o)

rgname = {'none'}; % use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;


o = odf(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois
    
    if strcmp(rgname{m}, 'none')
        o.roi.mm.maskname = {'none'};
        o.roi.nrm.post = {'dff008000'};
    end

    o = odf(o, 'roi', rgname{m});

end

