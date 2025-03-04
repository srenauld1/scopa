function daq = daqld(opt, pthstack, doplt, pth_daq, pth_daqrs, pth_ftvid, pth_ftvidrs)

%{
resample daq variables from daq sampling into imaging sampling (by volume and/or frame), also find each daq variable's derivative (for some, this is velocity)
uses imaging frameClock on DAQ to assign DAQ samples to frames (nearest neighbor interp to find each frame's centroid)
includes volume and frame flyback samples, then uses mod to convert to daqinds.slice
then, operates on daq variables according to coincident slice index, creating a different timeseries for each slice index
this occurs differently according to daq variable type
for 'normal' daq variables, averages daq variables during each frame,
for 'circular' daq variables, does the same but operates on x and y components 
for 'categorical' daq variables (integers treated categorically), finds same but uses nearest neighbor interp
only variables listed in daqvars will be processed; anything listed in daqvars but not found on daq is skipped
averaging by frame allows comparisons between imaging and behavior to have greater resolution in lag
volume and frame flyback samples are because:
   - we don't know the optimal lag
   - often, our imaging volume rate at least 2-4 times slower than stimulus
   and/or behavior rate, while imaging frame rate is at least 2-4 times
   faster, so correlation resolution can be improved, including comparing
   rois from different frames
this function downsamples daq variables to match imaging rate, rather than
upsampling imaging to match daq variables because:
    - downsampling behavior into imaging regularizes subsequent model fitting (and speeds computation)
    - imaging rates and indicators are already smoothing neural activity, and besides, the main optic flow detectors in the visual system have little power at 60 hz (behavior rate), 
this function can retain all available lag information by averaging during
each slice index (rather than just by volume index), or any requested
subset of slice indices, or can just resample during each volume index, or
can do both volume and slices; useinds controls the resampling indices
(useinds 'none' will just use matlab function 'resample' instead) 
resampling indices can contain flyback lines and/or frames, if requested with usefbl and usefbf
this function also differentiates all requested daq variables, using movingslope to reduce noise, if desired (increase slopelensec to reduce noise)
with movingslope there is no need for smoothing first, since slope window is built in
for circular variables, derivative operates on x and y components
for categorical variables, derivative is just diff over slopelen using conv
if frameClock is not on daq, uses matlab function 'resample' (again, with above adjustments for variable type)
default frameClock approach is much slower than using 'resample', but has a little less aliasing
useinds 'none' will use the resample approach, which takes seconds for
each useinds register (besides none) can take ~1-5 min, but is a one-time
computation, since output is saved and loaded on subsequent runs; so if you

notes on useinds: can be 'none', 'slice', 'vol', 'all', or numeric vector of slice indices, with optional 0 to mean volume indices; 
    'none' (resample using 'resample' function with padding to remove start/end filter transients), 
    'slice' (resample using all slice indices), 
    'vol' (resample using volume indices), 
    'all' (resample using all slice indices and volume indices), 
    numeric vector defines which slice indices (one indexed) to use with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); 
'none' is fastest but has a little more aliasing, which is probably rarely a problem; slice resampling is included especially for slow imaging rate, or large flyback; 
the more resampling registers are used, the slower this function on first run (output is saved/loaded for subsequent runs)
smoothing daq variables before differentiation should not be necessary because the resampling is downsampling by a large factor,
and tsdv allows variable slope window anyway (increase to reduce output noise), 
but if you still want to smooth, function tssm handles circular and normal variables separately (but will error for categorical)

%}

arguments
    opt = []
    pthstack = []
    doplt = []
    pth_daq = [] %can optionally pass path to original daq file (if you don't it will be derived from pthstack)
    pth_daqrs = [] %can optionally pass path to original daq file (if you don't it will be derived from pthstack)
    pth_ftvid = []%can optionally pass path to downsampled (in scopa/register.py) fictrac video (if you don't it will be derived from pthstack)
    pth_ftvidrs = []%can optionally pass save path for new temporally downsampled fictrac video (if you don't it will be derived from pthstack)
end

[opt, optid, pthstack, doplt] = fset('daq', opt, pthstack, doplt);

vtime = opt.vtime; %name of variable representing time in original daq file
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
balldia = opt.balldia; % mm, used to convert fictrac variables into mm
voltmin = opt.voltmin; % daq voltage min; need to find this in metadata
voltmax = opt.voltmax; % daq voltage max, need to find this in metadata
vrenm = opt.vrenm; %optional new names for each daq variable


idxreg = 'start';  %hard coding this because its effect on our 10khz daqs miniscule; idx can be 'start', 'end', 'center', denoting whether each daq sample represents the start, end, or center of the time bin (ie, start means first sample is t=0)


if ~isstring(vnormal)
    vnormal = string(vnormal); %could also convert to char here
end
if ~isstring(vcircular)
    vcircular = string(vcircular);%could also convert to char here
end
if ~isstring(vcategorical)
    vcategorical = string(vcategorical);%could also convert to char here
end


id = idmake(pthstack); %just in case id info gets used below

if isempty(pth_daqrs)
    pthpre = [id.pthstackdir id.recid '_' optid '_daq_'];
    pth_daqrs = [pthpre '.mat'];
end

md = mdsild(pthstack);
numslice_withflyback = md.numslice_withflyback;
numslice = md.numslice;
numvol = md.numvol;
sper = md.sper;



try

    if isfile(pth_daqrs)

        load(pth_daqrs, 'daq');

        if any(~isfield(daq, {'md', 'optid', 'recid', 'maketime_optfile_daq'}))
            error("daq struct must contain fields 'md', 'optid', 'recid', 'maketime_optfile_daq'; you may have loaded an old daq struct")
        end
        if ~isequal(daq.maketime_optfile_daq, glb('maketime_daq'))
            error("daq id is derived from an optid file different from original")
        end
        if ~isequal(daq.md, md) || ~isequal(daq.opt, opt) || ~isequal(daq.recid, recid)
            error("md, or opt, or recid in saved/loaded daq file does not match current/expected")
        end

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

        if isempty(pth_ftvid)
            pth_ftvid = [id.pthstackdir id.recid '_FTV_DS_.mat']; %downsampled ft video (downsampled in register.py)
        end
        if isempty(pth_ftvidrs)
            pth_ftvidrs = [id.pthstackdir id.recid '_FTV_DS_RS_.mat']; %downsampled ft video (downsampled in register.py)
        end

        daqvars.normal = vnormal;
        daqvars.circular = vcircular;
        daqvars.categorical = vcategorical;

        if round(slopelensec/sper)<slopeord+1
            error("slopelensec is too short given slopeord and sample rate, and will cause error in tsdv; you need to make slopelensec longer for this recording; the shortest possible value that will not cause error is (slopeord+1)*sper; for this recording that is: " + num2str( (slopeord+1)*sper))
        end

        %%%% LOAD DAQ DATA %%%%

        load(pth_daq, 'trialData', 'outputData')
        trialData = timetable2table(trialData);
        varnames = trialData.Properties.VariableNames;
        vtime = vtime(ismember(vtime, varnames));
        if isempty(vtime)
            error("none of your listed vtime are variables the raw daq; you need a time variable")
        end

        if exist('outputData', 'var') && outputData(2)==0 && outputData(end-1)==0 %output data is less accurate than frameClock, since volume (or frame?) seems to complete after outputData ends, but i think frameClock is missing any final flyback frames
            fprintf("cropping daq data because runbg is true" + newline)
            firstsamp = find(trialData.frameClock, 1, 'first');
            lastsamp = find(trialData.frameClock, 1, 'last');
            if strcmp(idxreg, 'start')
                starttime = trialData.(vtime)(firstsamp);
            elseif strcmp(idxreg, 'end')
                starttime = trialData.(vtime)(firstsamp-1);
            elseif strcmp(idxreg, 'center')
                starttime = (trialData.(vtime)(firstsamp) + trialData.(vtime)(firstsamp-1) ) / 2;
            end
            trialData = trialData(firstsamp:lastsamp, :);
        else
            starttime = trialData.(vtime)(1);
        end


        %%%% DEFINE INDICES FOR DOWNSAMPLING %%%%

        %%%%%%%%% extract slice and volume indices from scanimage clocks %%%%%%%%%


        if strcmp(useinds, 'none')
            daqinds.frame = []; %frame inds are not used outside function daqindsmake, although could be in the same way as slice or volume indices
            daqinds.slice = [];
            daqinds.vol = [];
            fprintf("user requested useinds 'none'; downsampling daq data with 'resample' function, rather than resampling with frame and/or volume indices" + newline)
        else
            if any(strcmp(varnames, 'frameClock')) %cannot run daqindsmake without frameClock
                daqinds = daqindsmake(trialData.frameClock, trialData.(vtime), usefbl, usefbf, numvol, numslice, numslice_withflyback, doplt, pthpre);
            else
                error("user requested a value for useinds that requires frameClock, but frameClock is not on daq; when frameClock is not on daq, useinds='none' is the only option")
            end
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

        daq = table();

        sliceinds_unique = unique(daqinds.slice(daqinds.slice~=0));
        num_unique_sliceinds = numel(sliceinds_unique);
        num_resamples = num_unique_sliceinds + include_volume_resample + include_volume_approx_resample; %resample for each slice remaining in sliceinds, and and another for volume (if it volinds remains)
        useinds_save = cell(num_resamples, 1);
        for si = 1:num_resamples

            newrow = table();

            if strcmp(useinds, 'none')
                rsinds = [];
                useinds_save{si} = {'none (volume approx)'};
            else
                if si<num_unique_sliceinds+1
                    rsinds_tmp = bin2ind(daqinds.slice==sliceinds_unique(si)); %each slice
                    useinds_save{si} = {['slice' num2str(sliceinds_unique(si))]};
                else
                    rsinds_tmp = daqinds.vol;
                    useinds_save{si} = {'volume'};
                end

                riu = unique(rsinds_tmp(rsinds_tmp~=0),'stable'); %index of each resampling register (frame or volume)
                rsinds = cell(numel(riu), 1);
                tic
                parfor k = 1:numel(riu)
                    rsinds{k} = find(rsinds_tmp==riu(k)); %do this once, before operating on variable, since this is the slow part; we use find because a boolean array holding all inds would be way too large, and this let's us find all inds once, and reuse them for all daq variables; if you only have one daq variable, this may be slightly inefficient, but with multiple daq variables this becomes much more efficient
                end
                toc

            end

            fn = fieldnames(daqvars);
            for fni = 1:numel(fn)
                vartype = fn{fni};
                for ii = 1:numel(daqvars.(vartype))
                    varname = daqvars.(vartype){ii};
                    if strcmp(varname, vtime)
                        trialData.(varname) = trialData.(varname)-starttime; %zero imaging starttime in case daq ran in the background
                    end
                    if ~strcmp(varnames, varname)
                        fprintf("warning, daq does not have variable named '" + varname + "', skipping it" + newline)
                    else


                        tmp = trialData.(varname);

                        if isduration(tmp)
                            tmp = seconds(tmp); %convert to seconds, whatever the units
                        end
                        if strcmp(vartype, 'circular')
                            tmp = tmp / (voltmax-voltmin)*2*pi - pi; %put in range -pi to pi, 0 V assigned to -pi
                        end
                        if isequal(vec(unique(tmp)), [0;1])
                            tmp = bin2ind(tmp);
                        end

                        tmp = tsrs(vartype, tmp, numvol, rsinds); %resample into imaging rate
                        tmpdv = tsdv(vartype, tmp, slopelensec, slopeord, sper); %find local slope (velocity for some vars)

                        if doplt
                            tsplt([], tmp, [], trialData.(varname), xseg=20, titlein=varname, pthgif=[pthpre varname '_.gif'])
                            tsplt([], tmpdv, [], trialData.(varname), xseg=20, titlein=varname, pthgif=[pthpre varname '_dv_.gif'])
                        end

                        if any(strcmp(daqvars.(vartype){ii}, tounwrap))
                            tmp = unwrap(tmp); %convert to mm (not for tmpdv)
                        end
                        if any(strcmp(daqvars.(vartype){ii}, tozero))
                            tmp = tmp - tmp(1); %convert to mm (not for tmpdv)
                        end
                        if any(strcmp(daqvars.(vartype){ii}, toballscale))
                            tmp = tmp*balldia/2; %convert to mm
                            tmpdv = tmpdv*balldia/2; %convert to mm
                        end
                        if ~strcmp(varname, vtime) %we don't care to create 'Time_dv'
                            tmpdv = tmpdv / sper; %convert to per second using mean sample period (could scale by each Time_dv, but this is more stable against dropped samples)
                        end
                        if strcmp(varname, vtime) && strcmp(idxreg, 'start') %if idxreg is 'start', make sure time starts at zero, for useinds 'none', it is artifactually slightly above zero
                            tmp(1) = 0;
                            tmpdv(1) = tmp(2) - tmp(1); %also update first diff, not that it matters
                        end
                        if isrow(tmp) %each daq var must be column; will be column for useinds 'none', will be row for useinds 'all' and 'vol'
                            tmp = tmp';
                        end
                        newrow.(varname) = {tmp}; %put in cell, then table, for variable sizes
                        newrow.([varname '_dv']) = {tmpdv}; %put in cell, then table, for variable sizes


                    end
                end
            end

            daq = [daq; newrow];

        end


        daq = table2struct(daq);

        %%%% RENAME %%%%

        daq = daqrename(daq, vrenm);


        for m = 1:numel(daq) %in case you used multiple registers with daqinds, daq struct will be nonscalar

            %%%% FLY PATH %%%%

            [daq(m).px, daq(m).py] = ficpath(daq(m).bfv, daq(m).bsv, daq(m).vy, daq(m).t, balldia);


            %%%% EPOCHS (ADJUST FROM DAQ, OR DERIVE FROM  %%%%

            if ~isempty(daq(m).epochts)
                [hc, hce, bin] = histcounts(daq(m).epochts);
                numepoch_alt = numel(unique(bin)); %will this always be the same as numel(pkx); if so this is a simpler way to do it?
                hc = [min(hc) hc min(hc)]; %hack to include the endpoints of histcounts as peaks
                [~, pkx] = findpeaks(hc);
                numepoch = numel(pkx);
                daq(m).epochts = discretize(daq(m).epochts, numepoch);
                if numel(unique(daq(m).epochts))~=numepoch
                    error("unique epochts must equal numepoch")
                end
            else %if you don't have epochs written to daq, load or derive them here (this is not recommended, better to write them to daq)
                [daq(m).vy, daq(m).vyv, daq(m).epochts] = epochld(id.recdatenum, daq(m).t, daq(m).vy, daq(m).vyv, md.sper);
            end



            %%%% RESAMPLE FICTRAC VIDEO %%%%


            try
                volrate = 1/sper;
                daq(m).ftv = ftvpr(daq(m).ftcam, pth_ftvid, pth_ftvidrs, ...
                    numvol, volrate, opt.ftv.numpkthr, ...
                    opt.ftv.smlenpx, opt.ftv.numpx, opt.ftv.smlensec);
            catch ME
                fprintf("could not resample fictrac video; this is the error: " + ME.message + newline)
                daq(m).ftv = [];
            end


            %%%% RECORD SOME METADATA %%%%

            daq(m).md = md; %save metadata to flag in case it changes
            daq(m).useinds = useinds_save{m};
            daq(m).optid = optid;
            daq(m).recid = id.recid;
            daq(m).maketime_optfile_daq = glb('maketime_daq');

        end

        %%%% SAVE %%%%

        % save(pth_daqrs, '-struct', 'daq', '-v7.3', '-mat');
        save(pth_daqrs, 'daq', '-v7.3', '-mat'); %cannot save as struct because it can be nonscalar

    end

catch ME

    daq = [];
    fprintf("tried loading/processing daq but it failed with this message: " + newline + ME.message + newline + "continuing without daq data" + newline)

end











