function o = oset_312(o)

rgname = {'none'}; 

o.mn.doroi = 1; 

o.sld.ic = [];

for m = 1:numel(rgname) 

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; 

    if strcmp(rgname{m}, 'none')
        o.roi.doma = 1; 
        o.roi.ma.numroi = 128;
        o.roi.nrm.post = {'rsc000100'};
    end

    o = ofill(o, 'roi', rgname{m});

end



