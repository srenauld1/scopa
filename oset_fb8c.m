function o = oset_fb8c(o)

rgname = {'fb8c'}; 

o.mn.doftv = 0; 
o.mn.doroi = 1; 
o.mn.dobmp = 0; 
o.mn.dofit = 0; 
o.mn.dopltx = 0; 
o.mn.plt = [""]; 
o.mn.pltvis = 1; 

for m = 1:numel(rgname) 

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; 

    if strcmp(rgname{m}, 'fb8c')
        o.roi.doma = 1; 
        o.roi.ma.numroi = {12, 13, 14, 15};
        o.roi.nrm.post = {'rsc000100'};
    end

    o = odf(o, 'roi', rgname{m});

end


