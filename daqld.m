function dq = daqld(pthdaq, opt, opt2)

%{

SUBROUTINES
    (1) resample daq variables to align with imaging, or resample into arbitrary rate; functions 'vecrs' and 'resample'
    (2) differentiate some daq variables (to compute velocities); functions 'vecdv' and 'movingslope'
    (3) compute fly fictive path; function 'ficpath'
    (4) resample and crop fictrac video to align with imaging (optional); function 'ftvalign'

NAME-VALUE ARGUMENT 'rsidx'
    determines how to resample
        if nonnegative
            must be integer (does not have to be matlab class int), can be nonscalar
            requires daq record of imaging-frame-on and imaging-frame-off samples (eg 'frameClock'), which are used to determine when each slice and each volume are being acquired  
                function 'daqidxmake' computes volume and slice indices (and frame indices, which are unused, directly)
                    'daqidxmake' uses 'frameClock' on daq to assign daq samples to frames (nearest neighbor interpolation to find each frame's centroid), then uses mod to convert to slice and volume indices
                    'daqidxmake' optionally includes volume and frame flyback samples, if name-value arguments 'usefbl' and 'usefbf' equal 1, respectively
            each nonnegative rsidx element denotes which slice and/or volume index to use for resampling, where 0 denotes volume indices, and 1+ denotes slice indices
            daq variables are resampled according to coincident slice and/or volume index, creating a different timeseries for each nonnegative rsidx element (each "resampling register")
            example: rsidx = [0,4] will create two "resampling registers", one with volume indices and one with slice 4 indices; dq fields will have size (2,v), where v is number imaging volumes
            daqld allows multiple resampling registers for the following reasons:
               - we don't know the "true lag" between imaging and daq variables
               - often, our imaging volume rate is at least 2-4 times slower than stimulus and/or behavior rate, while imaging frame rate is at least 2-4 times faster, so multiple resampling registers can improve the resolution of temporal correlations between imaging and daq variables
                    - this is particularly useful when comparing rois from different slices of a stack acquired at low volume rate, or when volume flyback time is slow
            daqld allows multiple resampling registers to be saved to the same output struct 'dq' (rather than requiring rsidx always be scalar) to facilitate comparisons among resampling registers; 
                however, empty or negative rsidx must be run separately from nonnegative rsidx because they can output different resampled variable length (certainly this is true for negative rsidx, but often is also true for rsidx=[] because of resample imprecision, although typically empty and nonnegative rsidx match in resampled output length)  
            warning: all nonnegative rsidx should resample into the same length (matching number of imaging volumes, or frames if non-volumetric, which are also called "volumes" in scopa metadata anyway), 
                however, sometimes the resampled length can be slightly shorter than expected; 
                this can happen if the daq onset is delayed, relative to imaging (if runbg is false, see runbg section above); 
                it can also happen if you use a "resampling register" representing one of the last slices in the stack, as these can be missing in the final volume)
            vpp is in opt (rather than opt2) because it is id-controlled (see function 'oid'), ie 'rsidx' is a "functional" option (affects output data in nontrivial/non-cosmetic ways)
        if empty [] 
            uses matlab function 'resample' to match imaging number of volumes (or frames, if not volumetric)
            only requires daq record of number of imaging volumes (or from scanimage metadata), and imaging start time
            warning: resampling with 'resample' (rsidx=[] or negative scalar), has a little more aliasing than resampling with slice and/or volume indices (nonnegative rsidx), but the differences in spectra are typically very small; 
        if negative
            must be scalar
            the negative of the negative rsidx represents the desired arbitrary resampling rate 
            with negative rsidx, daqld operates exactly the same as empty rsidx, but resamples into a different rate, so output length in time will not match number imaging volumes, unless rsidx is exactly imaging volume rate (times -1)
            this can be useful if you want daq variables resampled into behavior rate (often 60 hz, so for this, rsidx = -60)
            warning: resampling with 'resample' (rsidx=[] or negative scalar), has a little more aliasing than resampling with slice and/or volume indices (nonnegative rsidx), but the differences in spectra are typically very small; 

NAME-VALUE ARGUMENT 'vpp'
    controls which daq variables are resampled, how they are processed before/during/after resampling, and fieldnames they are given in output struct 'dq' 
    'vpp' must be a string column vector
    each element is format "newname = oldnames = type = dvname"
        newname is one name assigned to fieldname in output struct 'dq';
            if you are running a2p, do not change any newname (default newnames are used downstream)
        oldnames is comma separated list of unique names, all possible variable names in original daq file to be given newname in output struct 'dq';
            for each newname, any of the oldnames in original daq file are processed (will error if multiple oldname matches are found)
            if none of the oldnames exist, newname is assigned empty value [] in struct 'dq';
            by default, if newname is already in original daq file, its name will not change (each newname gets added to correponding oldnames automatically in daqld) 
        type is single char denoting variable type (determines how variables are processed)
            'r' means 'radians'; 'r' is processed as angular data with units radians (there is no option for unit degrees, so be sure angular data is in radians)
            'm' means millimeters; 'm' is processed the same as 'r', but with the additional final steps of unwrapping, zeroing, and rescaling, to convert from radians to mm
            'c' means 'categorical'; 'c' does not literally have to be categorical; it just means it is processed to retain original values in resampled output; specifically, 'c' is resampled using nearest-neighbor interpolation, rather than any averaging; for example, a variable like imagingFrameIndex might get type 'c', so output is integer-valued 
            'b' means 'binary'; processed same as 'c', except converted from binary to count before processing (using function 'binary2count')
            'n' means normal, and is for everything else
            't' means time; 't' is processed the same as 'n', but is flagged as the time vector for special treatment; one and only one 't' variable must exist in the original daq file (error otherwise)
            more info on type
                resampling occurs differently for each daq variable type
                    'n' and 't' daq variables: averaged during each resampling time bin
                    'r' and 'm' daq variables: atan2(sin(x)/sin(x)) is averaged during each resampling time bin, where x is daq variable
                    'c' and 'b' daq variables: nearest-neighbor interpolation used to find value nearest centroid of each resampling time bin ('c' are not literally categorical variables, but output values contain only input values, for example, some integer daq variables that need to remain integers after resampling)
                differentiation also occurs differently for each of these types (analogous to the resampling differences above) 
                    'n' and 't' daq variables: differentiated normally
                    'r' and 'm' daq variables: derivative operates on x and y components
                    'c' and 'b' daq variables: derivative is just diff over slopelen using conv
        dvname 
            dvname is the name of the differentiated variable (ie velocity) 
            if there is no dvname (if vpp row ends with 3rd equals sign), that variable's derivative is not written to output struct 
     'vpp' is in opt2 (rather than opt) because it is not id-controlled (see function 'oid'), ie 'vpp' is not a "functional" option (does not affect output data, except in ways that should not ever change, specifically variable 'type')
      example:
            opt2.vpp = [ 
                        "vh = vh, g4panels, g4yaw, g4hd = r = vvy";
                        "ftcam = ftcam = b"
                            ];
            1st element (1st row) means any variable in struct 'trialData' (from original daq file) named 'g4panels', 'g4yaw', or 'g4hd' is processed as an 'r' variable (angular, in radians) and saved to fieldname 'vh' in output struct 'dq'; the derivative is also saved to fieldname 'vvy' in output struct 'dq' 
            2nd element (2nd row) means any variable in struct 'trialData' (from original daq file) named 'ftcam' is processed as a 'b' (binary) variable (converted to count, then treated by vecrs and vecdv as type 'c') and saved to fieldname 'ftcam' in output struct 'dq'; the derivative is not saved to output struct 'dq'
        
RESAMPLING TO MATCH IMAGING RATE
    daqld is specialized to downsample daq variables into imaging rate, rather than upsampling imaging data to match daq sampling
        - downsampling behavior into imaging regularizes subsequent model fitting (and speeds computation)
        - imaging rates and indicators are already smoothing neural activity, and the main optic flow detectors in the visual system have little power at 60 Hz behavior rate, 

DIFFERENTIATION
    daqld differentiates some daq variables to compute their velocities
    differentiation occurs in function 'movingslope' (called from function 'vecdv') to allow flexible noise reduction; 
    to reduce noise, increase name-value argument 'dvlensec'; 
    name-value argument 'dvord' should probably remain 2 or 3

SMOOTHING
    this function does not smooth any variables (not directly, at least) 
    smoothing daq variables before differentiation should not be necessary because the resampling is a downsampling by a large factor, and because the user can set the differentiation window length (dvlensec), 
    but if you still want to smooth, function 'vecsm' handles angular and non-angular variables separately, just like 'vecrs' and 'vecdv' (note vecsm does not have an option for 'c' variables)

RUNBG (START TIMES FOR DAQ, IMAGING, BEHAVIOR, ETC.)
    if daq starts before all other processes start, and ends after all other processes end, daqld crops daq data so everything is aligned in time; 
    in carl's branch of flyg this occurs when variable 'runbg' equals 1
    if this is not the case, daq variables are assumed to be aligned in time with imaging, but this may not be the case (there can be a variable lag in start time between them)

FICTRAC VIDEO RESAMPLING
    since the fictrac video is ideally resampled using frame-on samples written to the daq, daqld includes an optional resampling of the fictrac video (function 'ftvalign')  
    if video frame-on times were not written to daq, ftvalign attempts a hack alignment that is not very robust yet; for this reason, ftvalign is in a try statement, and if it fails, field ftv=[] in output struct 'dq'

TIME DIMENSION
    like all a2p variables that do not have two channels, resampled variables all have last dimension time (which is 2nd dimension in all cases except 'ftv', the fictrac video, which is yxt)


%}


arguments

    pthdaq char {mustBeTextScalar} = '' %path to original daq file; if empty, user prompted to select file interactively

    opt.rsidx {mustBeNumeric, mustBeVectorOrEmpty, mustBeAllNonnegIntOrNegScalarOrEmpty, mustBeUnique} = [0]; % empty or nonempty numeric vector denoting resampling method; empty [] means resample using matlab 'resample' function into imaging number volumes, with padding to avoid start/end transients; negative scalar means resample using matlab 'resample' function into rate rsidx*-1 (eg rsidx=-60 resamples into 60 hz); nonnegative integer (in which case, can be nonscalar) defines which slice indices (one-indexed) to use for resampling (interp over requested time bins, method depends on vtype, see docs above), with 0 denoting resampling by volume index rather than slice index (eg [0 4] will resample with volume indices and slice 4 indices); nonegative integer rsidx is recommended over empty rsidx, because there is a little less aliasing and it is faster 
    opt.dvlensec double {mustBeScalarOrEmpty, mustBePositive} = []; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in vecdv) to be as short as possible, given sample rate and dvord
    opt.dvord (1,1) double {mustBeMember(opt.dvord,1:8)} = 2; % order of polynomial used to fit local slope
    opt.usefbl (1,1) {mustBeMember(opt.usefbl,[0,1])} = 1; % whether to include flyback lines when resampling with frame indices (if rsidx is not empty)
    opt.usefbf (1,1) {mustBeMember(opt.usefbf,[0,1])} = 1; % whether to include flyback frames when resampling with volume indices (if rsidx is not empty)
    opt.balldia (1,1) double = 9; % mm, used to convert fictrac variables into mm
    opt.voltlim (1,2) double = [0,10]; % daq voltage [min,max]; need to get this from metadata, rather than setting it here
    opt.voltminhd (1,1) double = 1/12 * 2*pi; %heading angle (radians) assigned to voltmin and voltmax (on bergI, it is fly's 1 o'clock, and target range is -pi to pi, hence 1/12 * 2*pi)
    opt.optid {mustBeTextScalar} = ''; %automatically generated id for each unique input opt set; if your input opt is not generated by oset, leave optid empty

    opt2.vpp (:,1) string = [  %string column vector; vpp means variable processing pattern each element is "newname = oldnames = type", where newname is one name, oldnames is comma separated list of names, type is scalar char; see docs above for more detail; don't change newnames shown here if running a2p
        "t = Time, time, T = t = ";
        "bf = ficTracIntForward = m = bvf";
        "bs = ficTracIntSide = m = bvs";
        "bh = ficTracYaw, ficTracHeading, ficTracHd = r = bvy";
        "vh = g4panels, g4yaw, g4hd = r = vvy";
        "vvynom = g4vel, g4velnom = c = ";
        "epochts = epoch = c = ";
        "ftcam = ftcam = b = "
        "heat = heat = c = "
        "iter = virmenIteration = c = "
        ];

    opt2.pthftv char {mustBeTextScalar} = '' %can optionally pass in path to downsampled fictrac video (optionally downsampled in scopa/register.py); if empty, pthftv it will be derived from pthdaq in ftvalign
    opt2.doplt (1,1) {mustBeMember(opt2.doplt,[0,1]), mustBeNonempty} = 0 % 1 to make plots 
    opt2.och (1,1) {mustBeMember(opt2.och,[0,1]), mustBeNonempty} = 0 %och means "options check"; 1 to exit function and return nothing but arguments block struct opt (not opt2 or any other name-value arguments struct); 0 to skip och (run function normally), which is default

end
    
if opt2.och
    if isfield(opt, 'optid')
        opt = rmfield(opt, 'optid');
    end
    dq = opt;
    return
end

opt = optidcheck('dq', opt); %make sure optid matches input, if nonempty (if empty, assign it default value)

rsidx = opt.rsidx;
dvlensec = opt.dvlensec;
dvord = opt.dvord;
usefbl = opt.usefbl;
usefbf = opt.usefbf;
balldia = opt.balldia;
voltlim = opt.voltlim;
voltminhd = opt.voltminhd;
optid = opt.optid;

vpp = opt2.vpp;
pthftv = opt2.pthftv;
doplt = opt2.doplt;


if isempty(pthdaq)
    try
        loc = userdatfile('pthpar');
    catch
        loc = pthscopaget();
    end
    [fn, loc] = uigetfile([loc '*.mat'], 'choose daq file to load');
    if isequal(fn, 0)
        error("you cancelled stack file selection; you must pass in argument pthdaq, or select stack file")
    end
    if isempty(regexp(fn, '^\d{8}-\d+_daqData_\d{6}_trial_\d{3}.mat', 'once'))
        error("file you chose does not match expected daq file pattern")
    end
    pthdaq = fullfile(loc, fn);
end

id = idmake(pthdaq); %make id again here just for id.pthrec to derive mdsi file
pthmd = [id.pthrec '_mdsi_.txt'];
if isfile(pthmd)
    md = mdsild(pthmd); %mdsild can run just with recid input, but if mdsild file does not exist, will error here
else
    error("mdsi_.txt file does not exist, so either put it in filesystem, or create it by running stackld on the raw stack, or by running registration on the raw stack")
end

numslice_withflyback = md.numslice_withflyback;
numslice = md.numslice;
numvol = md.numvol;
sper = md.sper;

pthdaqrs = [id.pthrec '_' optid '_dq_.mat'];

try

    dq = load(pthdaqrs);

    if any(~isfield(dq, {'md', 'optid', 'recid', 'maketime_optfile_daq'}))
        error("struct 'dq' must contain fields 'md', 'optid', 'recid', 'maketime_optfile_daq'; you may have loaded an old struct 'dq'")
    end
    if ~isequal(dq.maketime_optfile_daq, glb('maketime_daq'))
        error("daq id is derived from an optid file different from original")
    end
    if ~isequal(dq.md, md) || ~isequal(dq.recid, id.recid)
        error("md or recid in saved/loaded dq file does not match current/expected")
    end
    if ~isfield(dq, 'opt') %doing this check separately from above because added opt to saved variables later than others
        dq.opt = opt;
        save(pthdaqrs, '-struct', 'dq', '-v7.3', '-mat');
    else
        if ~isequal(dq.opt, opt)
            error("opt saved/loaded from dq file does not match input opt")
        end
    end


catch ME


    fprintf("tried loading daqrs file but it failed with this message: " + newline + ME.message + newline + "trying to process daq data now" + newline)


    %%%% PARSE VPP %%%%

    vpp = convertStringsToChars(erase(vpp, " "));
    spl = split(vpp, '=');
    vppnew = spl(:,1);
    vppold = spl(:,2);
    vpptypes = spl(:,3);
    vppvel = spl(:,4);
    vpptime = split(spl(strcmp(vpptypes, 't'),2), ',');
    if ~isvector(vpptime)
        error("there must be one and only one element with dodv=1 and type='t' in string array 'vpp'")
    end
    if any(cellfun(@isempty, [vppnew; vppold]))
        error("none of the newnames or oldnames in vpp can be empty")
    end
    vppold_flat = {};
    for k = 1:numel(vppold)
        vppold_flat = cat(2, vppold_flat, strsplit(vppold{k}, ','));
    end
    if ~isequal(numel(unique(vppold_flat)), numel(vppold_flat))
        error("there cannot be any repeat oldnames (within or across rows) in name-value argument vpp")
    end
    vppold = strcat(vppnew, ',', vppold); %add vppnew to vppold, in case newname already is in use 


    %%%% LOAD DAQ DATA %%%%

    load(pthdaq, 'trialData', 'outputData')
    trialData = timetable2table(trialData);
    tdvnames = trialData.Properties.VariableNames;
    vtime = string(vpptime(ismember(vpptime, tdvnames)));
    if isempty(vtime)
        error("in vpp, none of the oldnames with type='t' are fields in 'trialData' (ie in the original daq file); you must have one time variable")
    end

    if isduration(trialData.(vtime))
        trialData.(vtime) = seconds(trialData.(vtime));
    end

    if exist('outputData', 'var') && outputData(2)==0 && outputData(end-1)==0 %output data is less accurate than frameClock, since volume (or frame?) seems to complete after outputData ends, but i think frameClock is missing final flyback frames (if they exist)
        fprintf("cropping daq data in time because daq started/stopped before/after everything else" + newline)
        firstsamp = find(trialData.frameClock, 1, 'first');
        lastsamp = find(trialData.frameClock, 1, 'last');
        starttime = trialData.(vtime)(firstsamp); % here, we decide that each sample represents the start of its time bin (not the end or center); do this if we decide end: trialData.(vtime)(firstsamp-1); do this if we decide center: (trialData.(vtime)(firstsamp) + trialData.(vtime)(firstsamp-1) ) / 2; however, changing start/end/center has negligible effect on our 10khz daq data; when we decide 'start', t(1)=0, which is nice
        trialData = trialData(firstsamp:lastsamp, :);
    else
        starttime = trialData.(vtime)(1);
    end

    daqrate = 1/median(diff(trialData.(vtime)));
    if daqrate<1/sper*2.5
        error("daq sampling rate is too slow for resampling into imaging rate")
    end


    %%%%%%%%% DEFINE INDICES FOR DOWNSAMPLING: EXTRACT SLICE AND VOLUME INDICES FROM SCANIMAGE CLOCKS %%%%%%%%%

    if any(rsidx>=0)
        if any(strcmp(tdvnames, 'frameClock')) %cannot run daqidxmake without frameClock
            daqidx = daqidxmake(trialData.frameClock, trialData.(vtime), numvol, numslice, numslice_withflyback, usefbl=usefbl, usefbf=usefbf, doplt=doplt);
        else
            error("user requested a value for rsidx that requires frameClock, but frameClock is not on daq; when frameClock is not on daq, rsidx=[] is the only option")
        end
        if any(~ismember(rsidx(rsidx~=0), daqidx.slice))
            error("you requested a rsidx that does not exist in sliceinds; it may exceed numslice_withflyback, or it may have been eliminated from sliceinds given your setting for usefbf")
        end
    end


    %%%% MAKE/SAVE RESAMPLED daq DATA %%%%

    for k = 1:numel(vppnew)
        dq.(vppnew{k}) = []; %create empty output struct 'dq' (in case some variables aren't found)
    end

    if isempty(rsidx)
        rsidx = {[]};
    else
        rsidx = num2cell(rsidx);
    end

    for m = 1:numel(rsidx)

        if rsidx{m}<0
            rskey = round( numvol * sper * -rsidx{m} );
            newlen = rskey;
            sper_tmp = 1/-rsidx{m};
        else
            sper_tmp = sper;
            if isempty(rsidx{m})
                rskey = numvol;
                newlen = rskey;
            else
                if rsidx{m} == 0
                    rskey = daqidx.vol;
                else
                    rskey = binary2count(daqidx.slice==rsidx{m}); % slice resampling
                end
                newlen = numel(unique(rskey(rskey~=0), 'stable'));  %index of each resampling register (frame or volume)
            end
        end

        for k = 1:numel(vppnew)

            tdvname = tdvnames(~cellfun(@isempty, regexp(vppold{k}, strcat('^(.+,)*', tdvnames, '(,.+)*$'), 'forcecelloutput')));

            if isscalar(tdvname)

                tdvname = cell2mat(tdvname);

                tmp = trialData.(tdvname);

                if isduration(tmp) %not all durations are the "time" variable
                    tmp = seconds(tmp); %convert to seconds, whatever the units
                end
                if strcmp(tdvname, vtime)
                    tmp = tmp-starttime; %zero imaging starttime in case daq ran in the background
                end
                if any(strcmp(vpptypes{k}, {'r', 'm'}))
                    tmp = wrapToPi(tmp/(voltlim(2)-voltlim(1))*2*pi+voltminhd); %put in range -pi to pi, with 0 in front of fly
                end
                if strcmp(vpptypes{k}, 'b')
                    tmp = binary2count(tmp);
                end

                vtype = regexprep2(vpptypes{k}, {'t', 'm', 'b'}, {'n', 'r', 'c'}, whole=1); %rename some vpptypes to obtain vtype; vtype is input for functions vecrs and vecdv; in these functions, t needs to get the same treatment as n, m the same as r, and b the same as c (t, m, and b aren't valid vtypes in vecrs and vecdv)

                tmp_o = tmp; %set aside before resampling, in case plotting below

                tmp = vecrs(vtype, tmp, rskey); %resample
                tmpdv = vecdv(vtype, tmp, lensec=dvlensec, ord=dvord, sper=sper_tmp); %find "sliding derivative" / "moving slope" (ie velocity, for some vars)

                if doplt
                    tsplt([], tmp, [], tmp_o, xseg=20, titlein=tdvname, pthgif=[pthauto() tdvname '_.gif'])
                    tsplt([], tmpdv, [], tmp_o, xseg=20, titlein=tdvname, pthgif=[pthauto() tdvname '_dv_.gif'])
                end

                if strcmp(vpptypes{k}, 'm')
                    tmp = unwrap(tmp);  %unwrap angular
                    tmp = tmp - tmp(1); %zero
                    tmp = tmp*balldia/2; %convert from radians to mm
                    tmpdv = tmpdv*balldia/2; %convert to mm
                end

                if strcmp(vpptypes{k}, 't')
                    tmp(1) = 0; %we do this because we consider each sample to represent start of time bin (not end or center), make sure time starts at zero, for rsidx=[], it is artifactually slightly above zero
                end

                nm = regexprep2(tdvname, strsplit(vppold{k}, ','), vppnew{k}, whole=1); %rename matched oldname with newname using scopa function regexprep2

                if m>1 && ~isequal(newlen, numel(tmp), size(dq.(nm)(m-1,:), 2))
                    error("resampled variable length does not match length of a previous 'resampling register'; this should only happen if rsidx has multiple nonnegative values; one of the values you chose for rsidx might correspond to a slice that appears in fewer volumes than a previous value for rsidx; you cannot use this current problematic value")
                end

                dq.(nm)(m,:) = tmp; 

                if ~isempty(vppvel{k}) %only save differentiated variable if it has an entry after 3rd equals sign in name-value argument 'vpp'
                    dq.(vppvel{k})(m,:) = tmpdv; 
                end

            elseif isempty(tdvname)
                fprintf("warning, 'trialData' (in original daq file) contains a variable named '" + vppold{k} + "' that is not listed as an oldname in name-value argument 'vpp', so it will not be processed and will not appear in output struct 'dq'" + newline)
            else
                error("'trialData' (in original daq file) contains a variable named " + vppold{k} + " that matches multiple oldnames in element " + num2str(k) + " of name-value argument 'vpp'")
            end

        end

        %%%% FLY PATH %%%%

        bvfang = dq.bvf(m,:)/(balldia/2); %above these were scaled to mm, so revert
        bvsang = dq.bvs(m,:)/(balldia/2); %above these were scaled to mm, so revert
        [dq.px(m,:), dq.py(m,:)] = ficpath(bvfang, 'r/s', bvsang, 'r/s', dq.vh(m,:), 'r', dq.t(m,:), 's', balldia, 'mm'); %flat path according to visual stim heading
        [dq.pxb(m,:), dq.pyb(m,:)] = ficpath(bvfang, 'r/s', bvsang, 'r/s', dq.bh(m,:), 'r', dq.t(m,:), 's', balldia, 'mm'); %flat path according to ball heading


        %%%% EPOCHS  %%%%

        try
            [hc, hce, bin] = histcounts(dq.epochts(m,:));
            hc = [min(hc) hc min(hc)]; %hack to include the endpoints of histcounts as peaks
            [~, pkx] = findpeaks(hc);
            numepoch = numel(pkx); % numepoch_alt = numel(unique(bin)), will this always be the same as numel(pkx); if so this is a simpler way to do it?
            dq.epochts(m,:) = discretize(dq.epochts(m,:), numepoch);
            if numel(unique(dq.epochts(m,:)))~=numepoch
                error("unique epochts must equal numepoch")
            end
        catch ME
            fprintf("setting dq.epochts to nan because of this error: " + ME.message + newline)
            dq.epochts(m,:) = nan(1,newlen);
        end


        %%%% RESAMPLE FICTRAC VIDEO %%%%

        ftvaligned = 0;
        if ~ftvaligned && ( isempty(rsidx{m}) || rsidx{m}>=0 ) %switch ftvalign off if it succeeded once; we resample only using one register because we don't want a bunch of fictrac videos (too big); also rsidx it must not be negative (ie video must be aligned with imaging, not some arbitrary resample rate, since we don't know when it begins relative to imaging, resampling the whole video into some arbitrary rate is pointless)
            try
                dq.ftv = ftvalign(rsidx=dq.ftcam(m,:), pthdaq=pthdaq, numvol=numvol, imrate=1/sper, ...
                    numpkthr=10, topkp=0.5, smlenpx=2, numpx=10, smlensec=1, ftrate=[], ...
                    pth_vid=pthftv, doplt=1);
                ftvaligned = 1;
            catch ME
                fprintf("setting dq.ftv to empty because of this error: " + ME.message + newline)
            end
        end
        if ~ftvaligned
            dq.ftv = [];
        end

    end


    %%%% RECORD SOME METADATA %%%%

    dq.md = md; %save metadata in case it changes
    dq.rsidx = rsidx;
    dq.opt = opt;
    dq.optid = optid;
    dq.recid = id.recid;
    dq.maketime_optfile_daq = glb('maketime_daq');


    %%%% SAVE %%%%

    save(pthdaqrs, '-struct', 'dq', '-v7.3', '-mat');

end


end



function mustBeAllNonnegIntOrNegScalarOrEmpty(x)

if ~isempty(x)
    if any(x<0)
        if ~isscalar(x)
            error("must be scalar, if negative")
        end
    else
        if any(mod(x,1)~=0)
            error("all elements must be integer, if nonnegative")
        end
    end
end

if any(~isreal(x))
    error("all elements must be real")
end
if any(~isfinite(x))
    error("all elements must be finite")
end

end







