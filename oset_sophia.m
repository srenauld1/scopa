function o = oset_sophia()

do = {'sld', 'dq', 'roi'}; %modules to run

o.dq.dvlensec = 0.4; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in vecdv) to be as short as possible, given sample rate and dvord
o.dq.dvord = 2; % order of polynomial used to fit local slope

o.roi.roiname = {'ves041'};
o.roi.nrm.nrmstr = {'dff008000'};

o = ofill(o, mosfinal=do); % mosfinal final ofill call to strip o to only 'mos' listed in input 'do'
