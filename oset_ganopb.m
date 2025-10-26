function o = oset_ganopb(o)

o.mn.do = ["sld", "dq", "roi"];

% rgname = {'ga', 'no', 'pb'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;
rgname = {'pb'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;


if str2double(o.id.recdate)<20231100
    o.dq.dvlensec = 0.8;
    fprintf("WARNING THIS IS A LOW VOLRATE RECORDING, dvlensec IS 0.8 SEC" + newline)
end

o = ofill(o);

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; %do draw rois
    
    if strcmp(rgname{m}, 'pb')
        o.roi.doma = 1; %do automated morph rois
        o.roi.docm = 1; %do draw rois
        o.roi.ma.numroi = 613;
        o.roi.ma.maskmake = 'edge';
        o.roi.nrm.post = {'rsc000100'};
        o.bmp.mdl.mdlname = 'fnet_v';
        o.bmp.mdl.lensec = 0;
        o.bmp.mdl.epochnum = 4;
        % o.bmp.mdl.opl.MaxFunctionEvaluations = Inf; %3000;
        % o.bmp.mdl.opl.MaxIterations = 5000; %1000    else
    elseif any(strcmp(rgname{m}, {'no', 'ga'}))
        o.roi.roiname = {'left', 'right'};
    end

    o = ofill(o, 'roi', rgname{m});

end

