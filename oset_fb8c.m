function o = oset_fb8c(o)

o.mn.do = ["sld", "dq", "roi"];

rgname = {'fb8c'}; 


for m = 1:numel(rgname) 

    o.roi.rgname = rgname{m};

    o.roi.domm = 1; 

    if strcmp(rgname{m}, 'fb8c')
        o.roi.doma = 1; 
        o.roi.ma.numroi = {12, 13, 14, 15};
        o.roi.nrm.post = {'rsc000100'};
    end

    o = ofill(o, 'roi', rgname{m});

end


