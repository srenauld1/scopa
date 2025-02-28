function o = oset_mito(o)

rgname = {'none'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doroi = 1; 
o.mn.dofit = 1; %fit model?

o = odf(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois
    o.roi.mm.maskname = {'lo'};
    
    o.roi.doma = 1; %do automated morph rois
    o.roi.ma.numroi = 1024;
    % o.roi.ma.maskmake = 'edge';

    o.roi.nrm.post = {'f'};
    
    o.mdl.mdlname = 'fnet_v';
    o.mdl.lensec = 0;
    o.mdl.epochnum = 1;
    o.mdl.nrmi = 'none';
    % o.mdl.opl.MaxFunctionEvaluations = Inf; %3000;
    % o.mdl.opl.MaxIterations = 5000; %1000    else

    o = odf(o, 'roi', rgname{m});

end

