function o = oset_ganoeb(o)

regionex = {'eb', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any regionex you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if regionex is not 'none', regionex can be, but do not have to be cuboid subregions of fov; regionex can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.doftv = 0; %process fictrac video?
o.mn.doroi = 1; %make/load/process rois?
o.mn.dobmp = 1; %compute bump?
o.mn.dofit = 0; %fit model?
o.mn.dopltx = 0; %enter pltx for summary interactive plots?
o.mn.plt = [""]; %string array of subroutines that get plots; default is all of them, ["daq", "spr", "ftv", "roi", "bmp", "mdl"], so keep this commented if you want all plots; if you want none, do empty string array [""]
o.mn.pltvis = 1; %1 shows requested plots (o.mn.plt) and saves them, 0 saves but does not show them

o.daq.use_carls_epochs = 1;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;
o.bmp.mdl.nrmi = 'none';
% o.bmp.mdl.opl.MaxFunctionEvaluations = Inf; %3000;
% o.bmp.mdl.opl.MaxIterations = 5000; %1000    else

o = odf(o);

for m = 1:numel(regionex) %create different copybin within o.roi for each regionex, to analyze them differently

    o.roi.regionex = regionex{m};

    o.roi.domm = 1; %do draw rois

    o.roi.nrm.post = {'rsc000100'};
    o.roi.nrm.degdtr = 2;

    if strcmp(regionex{m}, 'eb')
        o.roi.doma = 1; %do automated morph rois
        o.roi.ma.numroi = 33;
        o.roi.mm.maskname = 'none';
        o.roi.ma.maskmake = 'nonzero';
    elseif any(strcmp(regionex{m}, {'no'}))
        o.roi.doma = 0; %do automated morph rois
        o.roi.mm.maskname = {'left', 'right'};
    end

    o = odf(o, 'roi', regionex{m});

end


