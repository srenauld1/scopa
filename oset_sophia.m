function o = oset_sophia()

do = {'s', 'dq', 'roi'}; %modules to run

o.dq.dvlensec = 2; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in vecdv) to be as short as possible, given sample rate and dvord
o.dq.dvord = 2; % order of polynomial used to fit local slope
o.dq.voltminhd = glbfile('voltminhd_flyclock_berg2')/12 * 2*pi; %glbfile('voltminhd_flyclock_berg2') is 6 (o clock), so voltminhd is -pi; voltminhd is heading angle (radians) assigned to voltmin and voltmax
o.dq.rskey = {0, -60};

o.roi.dodraw = 1;
o.roi.roiname = 'ves041';
o.roi.nrm.nrmstr = 'dff005000';

o = ofill(o, mosfinal=do); % mosfinal final ofill call to strip o to only 'mos' listed in input 'do'
