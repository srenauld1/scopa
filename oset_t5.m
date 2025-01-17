function o = oset_t5(o)

regionex = {'t5', 'tm'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any regionex you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mfit) or interactive plots (pltx); if regionex is not 'none', regionex can be, but do not have to be cuboid subregions of fov; regionex can but do not have to be unique regions of fov, although the user is prompted with that option;

o.mn.oldcarl = 1;
o.mn.dodaq = 0; 
o.mn.doftv = 0; 
o.mn.doroi = 1; 
o.mn.dobmp = 0; 
o.mn.dofit = 0; 
o.mn.dopltx = 0; 
o.mn.plt = [""]; 
o.mn.pltvis = 1; 

o.sld.tcrop = [4,2];
o.mf.mdl_lag_sec = 1;
o.mf.mdl_length_sec = 1.25;
o.carl.stimtype = 'drone';
o.carl.feat = 'CON_51';

for m = 1:numel(regionex) 

    o.roi.regionex = regionex{m};
    o.roi.domm = 1; 
    o = odf(o, 'roi', regionex{m});

end


o = odf(o, fill=1); %make sure o is filled

