function daq = daqld(pthstack, opt, doplt, pth_daq, pth_daqrs)


% uses imaging frameClock on DAQ to assign DAQ samples to frames (nearest neighbor interp to find each frame's centroid)
% includes volume and frame flyback samples (reason below)
% then uses mod to convert to daqinds.slice
% then, operates on daq variables according to coincident slice index, creating a different timeseries for each slice index
% this occurs differently according to daq variable type (see default 'daqvars' struct below)
% for 'normal' daq variables, averages daq variables during each frame,
% for 'circular' daq variables, does the same but operates on x and y components
% for 'categorical' daq variables, finds same but mode instead of mean
% only variables listed in daqvars will be processed, anything listed in daqvars but not found on daq is skipped
% averaging by frame allows comparisons between imaging and behavior to have greater resolution in lag
% volume and frame flyback samples are included for two reasons:
%    1 - we don't know the optimal lag,
%    2 - our imaging rates and indicators are pretty slow
% this function downsamples daq variables to match imaging, rather than upsampling imaging to match daq variables
% imaging rates and indicators are already smoothing neural activity, and visual system at least has very little power at 60 hz anyway (although not sure about other input modalities to our neurons)
% downsampling behavior regularizes subsequent model fitting (and also speeds computation)
% but this function does retain all available lag information by averaging during each slice index
% also creates a timeseries for the entire volume too, as the final entry of the resampled matrix, for each daqvariable, (this volume timeseries includes all flyback samples too)
% this function also differentiates all requested daq variables, using movingslope to reduce noise (increase slopelensec to reduce noise)
% with movingslope there is no need for smoothing first, since slope window is built in
% for circular variables, derivative operates on x and y components
% for categorical variables, derivative is skipped
% if frameClock is not on daq, uses matlab function 'resample' (again, with adjustments for circular variables)
% default frameClock approach is much slower than using 'resample', so there are checkpoints where variables are saved and loaded on subsequent runs,
% but this appears to be a little more accurate, and handles sharp transitions well
% useinds 'none' will use the resample approach (which takles 5-10 seconds),
% the slow version will take about 10 minutes the first time you run it (but subsequent runs on the same daqdata will just take seconds)


arguments
    pthstack = []
    opt = []
    doplt = []
    pth_daq = [] %can optionally pass path to original daq file (if you don't it will be derived from pthstack)
    pth_daqrs = [] %can optionally pass path to original daq file (if you don't it will be derived from pthstack)
end

if isempty(pthstack)
    pthstack = glb('pthstack');
    if isempty(pthstack)
        error("you must either pass argument pthstack or set glb('pthstack')")
    end
end
if isempty(opt)
    fprintf("user did not pass options as argument, using all defaults")
    opt = odf('daq', fill=1, unpack=1);
end

balldia = opt.balldia; % mm, used to convert fictrac variables into mm
voltmin = opt.voltmin; % daq voltage min; need to find this in metadata
voltmax = opt.voltmax; % daq voltage max, need to find this in metadata
vnormal = opt.vnormal; %list normal (not circular, not categorical) daq variables you want to process; virmenIteration is averaged by imaging frame, output is converted to frame number in the usual way
vcircular = opt.vcircular; %list circular daq variables you want to process
vcategorical = opt.vcategorical; %list categorical daq variables you want to process
toballscale = opt.toballscale; %define which vars to rescale from radians to mm
tounwrap = opt.tounwrap;  %define which vars to unwrap
tozero = opt.tozero; %%define which vars to zero (force to start at 0)
slopelensec = opt.slopelensec; %slope length (seconds) for computing derivative of each daq variable
slopeord = opt.slopeord; %slope order for computing derivative of each daq variable (should just stay 2)
useinds = opt.useinds; %'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 'none' (resample using 'resample' function with padding to avoid start/end transients), 'slice' (resample using all slice indices), 'vol' (resample using volume indices), 'all' (resample using all slice indices and volume indices), numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
usefbl = opt.usefbl; %use flyback lines when defining resampling inds if useinds is not none; flyback lines are probably always too fast to ever make this parameter matter
usefbf = opt.usefbf; %use flyback frames when defining resampling inds if useinds is not none; this param could be relevant for slow volume rates, or flyback that is slow, relative to non-flyback
renm = opt.renm; %optional new names for each daq variable
idxreg = opt.idxreg;  %work-in-progress, currently has no effect; 'start', 'end', 'center'; index represents the start, end, center of bin

id = idmake(pthstack); %just in case id info gets used below

if isempty(pth_daqrs)
    pth_daqrs = [id.pthstackdir id.recid '_daqrs_.mat'];
end

md = mdsild(pthstack);
numslice_withflyback = md.numslice_withflyback;
numslice = md.numslice;
numvol = md.numvol;
volrate = md.volrate;
sampper = 1/volrate;

if isempty(doplt)
    doplt = any(strcmp('daq', glb('plt')));
end

if ~isstring(vnormal)
    vnormal = string(vnormal); %could also convert to char here
end
if ~isstring(vcircular)
    vcircular = string(vcircular);%could also convert to char here
end
if ~isstring(vcategorical)
    vcategorical = string(vcategorical);%could also convert to char here
end

if round(slopelensec/sampper)<slopeord+1
    slopelensec_new = (slopeord+1)*sampper;
    error("WARNING, IN daqld, slopelensec is too short given slopeord and sample rate, and will cause error in tsdv; you need to make slopelensec longer for this recording; the shortest possible value that will not cause error (and without changing slopeord) is: " + num2str(slopelensec_new))
end


daq = table();

try

    if isfile(pth_daqrs)

        load(pth_daqrs, 'daq')

    else

        fprintf("processed/resampled daq file '" + pth_daqrs + "' does not exist; making it now" + newline)

        if isempty(pth_daq)
            pth_daq_pat = [id.pthstackdir id.recdate '-' id.fly '_daqData_*_trial_' sprintf( '%03d', id.trialnum ) '.mat'];
            pth_daq = rdir(pth_daq_pat);
            if isempty(pth_daq)
                error("no daq file matching this pattern: " + pth_daq_pat)
            end
            pth_daq = pth_daq.name;
        end

        pthfigpre = pth_daqrs(1:end-4);

        daqvars_bytype.normal = vnormal;
        daqvars_bytype.circular = vcircular;
        daqvars_bytype.categorical = vcategorical;

        %%%% LOAD DAQ DATA %%%%

        load(pth_daq, 'trialData', 'outputData')
        trialData = timetable2table(trialData);

        if exist('outputData', 'var') && outputData(2)==0 && outputData(end-1)==0 %output data is less accurate than frameClock, since volume (or frame?) seems to complete after outputData ends, but i think frameClock is missing any final flyback frames
            fprintf("cropping daq data because runbg is true" + newline)
            firstsamp = find(trialData.frameClock, 1, 'first');
            lastsamp = find(trialData.frameClock, 1, 'last');
            if strcmp(idxreg, 'start')
                starttime = trialData.Time(firstsamp);
            elseif strcmp(idxreg, 'end')
                starttime = trialData.Time(firstsamp-1);
            elseif strcmp(idxreg, 'center')
                starttime = (trialData.Time(firstsamp) - trialData.Time(firstsamp-1) ) / 2;
            end
            trialData = trialData(firstsamp:lastsamp, :);
        else
            starttime = trialData.Time(1);
        end

        %%%% DEFINE INDICES FOR DOWNSAMPLING %%%%

        %%%%%%%%% extract slice and volume indices from scanimage clocks %%%%%%%%%

        daqinds.frame = []; %frame inds are not used outside function daqindsmake, although could be in the same way as slice or volume indices
        daqinds.slice = [];
        daqinds.vol = [];
        if ~strcmp(useinds, 'none') && any(strcmp(trialData.Properties.VariableNames, 'frameClock')) %cannot run daqindsmake without frameClock
            maxtplot = 2; %first maxtplot seconds to plot daqinds in daqindsmake
            daqinds = daqindsmake(trialData.frameClock, trialData.Time, usefbl, usefbf, numvol, numslice, numslice_withflyback, doplt, maxtplot, pthfigpre);
        else
            fprintf("frame clock not on daq, or user requested useinds 'none'; downsampling daq data with 'resample' function, rather than resampling with frame and/or volume indices" + newline)
        end

        %%%%%%%%% filter slice inds and volume inds according to useinds %%%%%%%%%

        if strcmp(useinds, 'slice') || strcmp(useinds, 'none')
            daqinds.vol = [];
        end
        if strcmp(useinds, 'vol') || strcmp(useinds, 'none')
            daqinds.slice = [];
        end
        if isnumeric(useinds)
            if any(~ismember(useinds(useinds~=0), daqinds.slice))
                error("you requested a useinds that does not exist in sliceinds; it may exceed numslice_withflyback, or it may have been eliminated from sliceinds given your setting for usefbf")
            end
            if all(useinds==0) %useinds=0 is same as useinds='vol'
                daqinds.slice = [];
            else
                daqinds.slice(~ismember(daqinds.slice, useinds)) = 0;
            end
            if ~ismember(0, useinds)
                daqinds.vol = [];
            end
        end
        if isempty(daqinds.vol)
            include_volume_resample = 0;
        else
            include_volume_resample = 1;
        end
        if strcmp(useinds, 'none')
            include_volume_approx_resample = 1;
        else
            include_volume_approx_resample = 0;
        end



        %%%% MAKE/SAVE RESAMPLED DAQ DATA %%%%

        sliceinds_unique = unique(daqinds.slice(daqinds.slice~=0));
        num_unique_sliceinds = numel(sliceinds_unique);
        num_resamples = num_unique_sliceinds + include_volume_resample + include_volume_approx_resample; %resample for each slice remaining in sliceinds, and and another for volume (if it volinds remains)
        for si = 1:num_resamples

            newrow = table();
            newrow.recdatenum = {id.recdatenum};
            newrow.flynum = {id.flynum};
            newrow.trialnum = {id.trialnum};
            if strcmp(useinds, 'none')
                resample_inds = [];
                newrow.methodrs = {'volume_approx'};
            else
                if si<num_unique_sliceinds+1
                    resample_inds = bin2ind(daqinds.slice==sliceinds_unique(si)); %each slice
                    newrow.methodrs = {['slice' num2str(sliceinds_unique(si))]};
                else
                    resample_inds = daqinds.vol;
                    newrow.methodrs = {'volume'};
                end
            end

            fn = fieldnames(daqvars_bytype);
            for fni = 1:numel(fn)
                daqvartype = fn{fni};
                for ii = 1:numel(daqvars_bytype.(daqvartype))
                    daqvarname = daqvars_bytype.(daqvartype){ii};
                    if strcmp(daqvarname, 'Time')
                        trialData.(daqvarname) = trialData.(daqvarname)-starttime; %zero imaging starttime in case daq ran in the background
                    end
                    if ~strcmp(trialData.Properties.VariableNames, daqvarname)
                        fprintf("warning, daq does not have variable named '" + daqvarname + "', skipping it" + newline)
                    else

                        [ tmp, tmp_dv ] = daqpr(daqvartype, daqvarname, trialData.(daqvarname), numvol, resample_inds, sampper, voltmin, voltmax, slopelensec, slopeord, pthfigpre, doplt);

                        if any(strcmp(daqvars_bytype.(daqvartype){ii}, tounwrap))
                            tmp = unwrap(tmp); %convert to mm (not for tmp_dv)
                        end
                        if any(strcmp(daqvars_bytype.(daqvartype){ii}, tozero))
                            tmp = tmp - tmp(1); %convert to mm (not for tmp_dv)
                        end
                        if any(strcmp(daqvars_bytype.(daqvartype){ii}, toballscale))
                            tmp = tmp*balldia/2; %convert to mm
                            tmp_dv = tmp_dv*balldia/2; %convert to mm
                        end
                        if ~strcmp(daqvarname, 'Time') %we don't care to create 'Time_dv'
                            tmp_dv = tmp_dv / sampper; %convert to per second using mean sample period (could scale by each Time_dv, but this is more stable against dropped samples)
                        end
                        if strcmp(daqvarname, 'Time') && strcmp(idxreg, 'start') %if idxreg is 'start', make sure time starts at zero, for useinds 'none', it is artifactually slightly above zero
                            tmp(1) = 0;
                            tmp_dv(1) = tmp(2) - tmp(1); %also update first diff, not that it matters
                        end
                        if isrow(tmp) %each daq var must be column; will be column for useinds 'none', will be row for useinds 'all' and 'vol'
                            tmp = tmp';
                        end
                        newrow.(daqvarname) = {tmp}; %put in cell, then table, for variable sizes
                        newrow.([daqvarname '_dv']) = {tmp_dv}; %put in cell, then table, for variable sizes
                    end
                end
            end
            daq = [daq; newrow];
        end

        save(pth_daqrs, 'daq', '-v7.3', '-mat');

    end

catch ME

    fprintf("tried loading/processing daq but it failed with this message: " + newline + ME.message + newline + "continuing without daq data" + newline)

end


%%%% RENAME, IF YOU WANT %%%%

daq = daqrename(daq, renm);


[daq.px, daq.py] = ficpath(daq.bfv, daq.bsv, daq.vy, daq.t, balldia);


%%%% DERIVE EPOCHS, IF THEY'RE NOT ON DAQ %%%%

if ~isfield(daq, 'epochts')
    [daq.vy, daq.vyv, daq.epochts] = epochld(id.recdatenum, daq.t, daq.vy, daq.vyv, md.sampper);
end


%%%% RESAMPLE FICTRAC VIDEO %%%%

% if isfield(daq, 'ftcam')
%     ftcaminds = daq.ftcam;
% else
%     ftcaminds = [];
% end
% ftvdsrs = ftvpr(ftcaminds, pth.ftvid, pth.ftvidrs, md.numvol, md.volrate, o.ftv.numpkthr, ...
%     o.ftv.smlenpx, o.ftv.numpx, .o.ftv.smlensec, pth.ftdat, pth.ftvidlog, pth.ftlog);







