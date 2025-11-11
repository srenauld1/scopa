function o = oset_ebgano(o)


do = {'s', 'dq', 'roi', 'bmp'};

rgname = {'eb', 'gal', 'gar', 'no'}; %use 'none' to skip prompt to define substack (will enter roi code with full fov), otherwise list any rgname you want to define for independent roi analysis, which will be associated with unique timeseries available for model fitting (mdlmake) or interactive plots (pltx); if rgname is not 'none', rgname can be, but do not have to be cuboid subregions of fov; rgname can but do not have to be unique regions of fov, although the user is prompted with that option;


% o.s.smlensec = 0.3;
% o.s.smlenpx = [3,3,0];
 
o.dq.rskey = {0, -17};


o.bmp.domtype = 'm';
o.bmp.dvord = 3;
o.bmp.smlensec = {2,4,6};

o.bmp.indv.vg.dq = ['*'];
o.bmp.indv.vg.vnm = 'bh';
% o.bmp.indv.vg.optid = 'a8';

o.bmp.depv.vg.roi.rgname = 'eb';
o.bmp.depv.vg.roi.roiname = {'eb', 'no'};
o.bmp.depv.vg.roi.ma.maskseg = 'torus';
o.bmp.depv.vg.vnm = 'ts';
% o.bmp.depv.vg.optid = 'a76';
o.bmp.depv.vg.group = 1;

o.bmp.depv.vg(2).dq.dvlensec = .49;
o.bmp.depv.vg(2).vnm = 'bh';
o.bmp.depv.vg(2).group = 1;

o.bmp.mdl.mdlname = 'fnet_v';
o.bmp.mdl.lensec = 0;
o.bmp.mdl.epochnum = 1;

o.bmp.dvord = 4;
o.bmp(3).smlensec = {5,10};

for m = 1:numel(rgname) %create different copybin within o.roi for each rgname, to analyze them differently

    o.roi(m).rgname = rgname{m};

    % o.roi(m).nrm.post = {'z'};
    % o.roi(m).nrm.degdtr = 3;

    if strcmp(rgname{m}, 'eb')
        o.roi(m).roiname = 'eb';
        o.roi(m).dodraw = 1;
        o.roi(m).ma.numroi = 32;
        o.roi(m).ma.maskmake = 'nonzero';
        o.roi(m).ma.maskseg = 'torus';
        o.roi(m).ma.roirad = 1.5;
    elseif any(strcmp(rgname{m}, {'gal', 'gar'}))
        o.roi(m).roiname = {'dorsal', 'ventral'};
        o.roi(m).dodraw = 1;
    elseif any(strcmp(rgname{m}, 'no'))
        o.roi(m).roiname = {'left', 'right'};
        o.roi(m).dodraw = 1;
    end

end

o = ofill(o, mosfinal=do);


