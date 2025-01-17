function o = oset_fb8c(o)

regionex = {'fb8c'}; 

o.mn.dodaq = 1; 
o.mn.doftv = 0; 
o.mn.doroi = 1; 
o.mn.dobmp = 0; 
o.mn.dofit = 0; 
o.mn.dopltx = 0; 
o.mn.plt = [""]; 
o.mn.pltvis = 1; 

o.daq.use_carls_epochs = 1;

for m = 1:numel(regionex) 

    o.roi.regionex = regionex{m};

    o.roi.domm = 1; 

    if strcmp(regionex{m}, 'fb8c')
        o.roi.doma = 1; 
        o.roi.ma.numroi = {12, 13, 14, 15};
        o.roi.nrm.post = {'rsc000100'};
    end

    o = odf(o, 'roi', regionex{m});

end


o = odf(o, fill=1); %make sure o is filled
