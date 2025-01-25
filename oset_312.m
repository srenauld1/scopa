function o = oset_312(o)

regionex = {'none'}; 

o.mn.doftv = 0; 
o.mn.doroi = 1; 
o.mn.dobmp = 0; 
o.mn.dofit = 0; 
o.mn.dopltx = 0; 
o.mn.plt = ["spr"]; 
o.mn.pltvis = 1; 

o.daq.use_carls_epochs = 1;

o.spr.sld.ic = [];

for m = 1:numel(regionex) 

    o.roi.regionex = regionex{m};

    o.roi.domm = 1; 

    if strcmp(regionex{m}, 'none')
        o.roi.doma = 1; 
        o.roi.ma.numroi = 128;
        o.roi.nrm.post = {'rsc000100'};
    end

    o = odf(o, 'roi', regionex{m});

end



