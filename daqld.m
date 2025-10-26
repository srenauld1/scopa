function dq = daqld(pthdaq, opt, opt2)

%{

resample daq variables from daq sampling into imaging sampling (by desired resampled variable length, or by imaging volume and/or frame indices), 
also differentiate each daq variable (ie compute velocities)

daq variable type 
    resampling (and derivative/velocity computation) occurs differently according to daq variable type (type listed in opt2.vpp, see below)
        'normal' daq variables, averages daq variables during each frame,
        'radians' daq variables, does the same but operates on x and y components 
        'categorical' daq variables (integers treated categorically), finds same but uses nearest neighbor interp

resampling to match imaging rate
    this function downsamples daq variables to match imaging rate, rather than upsampling imaging to match daq variables because:
        - downsampling behavior into imaging regularizes subsequent model fitting (and speeds computation)
        - imaging rates and indicators are already smoothing neural activity, and besides, the main optic flow detectors in the visual system have little power at 60 hz (behavior rate), 

differentiating to compute velocity
    this function also differentiates all requested daq variables, using movingslope to reduce noise, if desired (increase dvlensec to reduce noise)
        for circular variables, derivative operates on x and y components
        for categorical variables, derivative is just diff over slopelen using conv

smoothing
    this function does not smooth (directly) 
    smoothing daq variables before differentiation should not be necessary because the resampling is a downsampling by a large factor,
    and vecdv allows the user to set the differentiation window (increase dvlenserc to reduce noise in derivative/velocity), 
    but if you still want to smooth, function vecsm handles angular and non-angular variables separately (but will error for categorical)

rsidx:
    determines how to resample
    empty or numeric vector
        if empty [] 
            uses matlab function 'resample' to match desired number output samples (imaging numvol, by default, and/or if rsidx is negative, at the resampling rate given by -1*rsidx)
        if numeric vector
            numbers denote which slice or volume indices to use for resampling (with 0 denoting volume indices, rather than slice);
            variables are resampled according to coincident slice or volume index (depending on rsidx), creating a different timeseries for each rsidx
            resampling indices can contain flyback lines and/or frames, if requested with usefbl and usefbf
            for example:
                rsidx=[0 4] will resample with volume indices, and slice 4 indices
            averaging by slice allows comparisons between imaging and behavior to have greater resolution in lag
            volume and frame flyback samples are resampling options because:
               - we don't know the optimal lag
               - often, our imaging volume rate at least 2-4 times slower than stimulus and/or behavior rate, while imaging frame rate is at least 2-4 times faster, so correlation resolution can be improved, including comparing rois from different frames
            if rsdx is nonempty numeric vector, each rsidx element (resampling register) can take ~1-5 min, but is a one-time computation, since output is saved and loaded on subsequent runs;
            if frameClock is not on daq, rsidx must be empty (nonempty rsidx will error)
            volume and frame indices are computed in daqidxmake
                daqidxmake uses imaging frameClock on daq to assign daq samples to frames (nearest neighbor interp to find each frame's centroid)
                daqidxmake optionally includes volume and frame flyback samples, then uses mod to convert to daqidx.slice and daqidx.vol (as a resampling options, depending on rsidx)

    [] is fastest by far, but has a little more aliasing, which is probably almost never a problem; 
    slice resampling can be useful for slow imaging rate, or large flyback; 
    the greater numel(rsidx), the slower this function on first run (output is saved/loaded for subsequent runs)

opt2.vpp
    string column vector, each element is format "newname = oldnames = type = dodv"
        newname (before first equals sign) is one name, newname will be fieldname within new/saved/output struct 'dq';
        oldnames (after first equals sign) is comma separated list of names, all possible variable names written to raw daq file that are to be renamed newname;
            for each newname, any of the oldnames that exist are processed and written to fieldname newname in output struct 'dq'
            if none of the oldnames exist, newname is assigned empty value [] in struct 'dq';
            if you are running a2p, do not change any newname;
            if struct has newname already, nothing changes; newname=newname will retain name; recommend including newname in oldname in case they are already in use (as in default opt2.vpp below)
        type (after second equals sign) is single char denoting variable type
            'r' means 'radians'; 'r' is processed as angular data with units radians
            'm' means millimeters; 'm' is processed the same as 'r', but with the additional final steps of unwrapping, zeroing, and rescaling, to convert from radians to mm
            'c' means 'categorical'; 'c' is processed as a categorical variable (eg frame number is resampled with nearest interp, rather than any averaging, to retain original values in resampled output); these variables do not have to be strictly categorical
            'b' means 'binary'; processed same as 'c', except converted from binary to count before processing
            'n' means normal, and is for everything else (ie not angular, not categorical)
            't' means time; 't' is processed the same as 'n', but is flagged as the time vector; one and only one 't' variable must exist in the raw daq file, otherwise error
        dodv (after third equals sign) denotes whether the variable should be differentiated (ie to derive velocity); 1 for yes, 0 for no
    for example,
        string element "vh = g4panels, g4yaw, g4hd = r = 1" means any variable in struct 'trialData' (from original daq file) named 'g4panels', 'g4yaw', or 'g4hd' is processed as a angular variable in radians and given written/saved to output struct 'dq' as fieldname 'vh'
        string element "vh = g4panels, g4yaw, g4hd = r = 0" means any variable in struct 'trialData' (from original daq file) named 'g4panels', 'g4yaw', or 'g4hd' is not processed, and 'vh' appears in output struct 'dq' with empty value []
    opt2.vpp is in opt2 (rather than opt) because it likely to remain unchanged
            

%}


arguments

    pthdaq char {mustBeTextScalar} = '' %path to original daq file; if empty, user prompted to select file

    opt.rsidx {mustBeNumeric, mustBeVectorOrEmpty, mustBeAllNonnegIntOrNegScalarOrEmpty, mustBeUnique} = []; % resampling indices; empty or nonempty numeric vector of slice indices, with optional 0 denoting volume indices; empty [] means resample using 'resample' function with padding to avoid start/end transients); numeric vector defines which slice indices (one-indexed) to use, with 0 denoting volume index resampling (eg [0 4] will resample with volume and slice 4); empty [] is fastest by far (on first run, since subsequent runs just load results) but has a little more aliasing, which is probably rarely a problem;
    opt.dvlensec double {mustBeScalarOrEmpty, mustBePositive} = []; % window length in seconds used to fit slope to each daq variable (to compute their derivatives, ie velocities); make empty to have this derived automatically (in vecdv) to be as short as possible, given sample rate and dvord
    opt.dvord (1,1) double {mustBeMember(opt.dvord,1:8)} = 2; % order of polynomial used to fit local slope
    opt.usefbl (1,1) {mustBeMember(opt.usefbl,[0,1])} = 1; % whether to include flyback lines when resampling with frame indices (if rsidx is not empty)
    opt.usefbf (1,1) {mustBeMember(opt.usefbf,[0,1])} = 1; % whether to include flyback frames when resampling with volume indices (if rsidx is not empty)
    opt.balldia (1,1) double = 9; % mm, used to convert fictrac variables into mm
    opt.voltlim (1,2) double = [0,10]; % daq voltage [min,max]; need to get this from metadata, rather than setting it here
    opt.voltminhd (1,1) double = 1/12 * 2*pi; %heading angle (radians) assigned to voltmin and voltmax (on bergI, it is fly's 1 o'clock, and target range is -pi to pi, hence 1/12 * 2*pi)
    opt.optid {mustBeTextScalar} = ''; %automatically generated id for each unique input opt set; if your input opt is not generated by oset, leave optid empty

    opt2.vpp (:,1) string = [  %string column vector; vpp means variable processing pattern each element is "newname = oldnames = type = dodv", where newname is one name, oldnames is comma separated list of names, type is single char, and dodv is 0 or 1; see docs above for more detail; don't change newnames shown here if running a2p
        "t = t, Time, time, T = t = 0";
        "bf = bf, ficTracIntForward = m = 1";
        "bs = bs, ficTracIntSide = m = 1";
        "bh = bh, ficTracYaw, ficTracHeading, ficTracHd = r = 1";
        "vh = vh, g4panels, g4yaw, g4hd = r = 1";
        "vvynom = vvynom, g4vel, g4velnom = c = 0";
        "epochts = epochts, epoch = c = 0";
        "ftcam = ftcam, ftcam = b = 0"
        "heat = heat = c = 0"
        "iter = iter, virmenIteration = c = 0"
        ];
    opt2.nmvel (:,1) string = [ %name of derivative = name of differentiated variable; only variables listed have their derivatives written to output struct 'dq'
        "bvf = bf"; %ball forward becomes ball velocity forward
        "bvs = bs"; %ball side becomes ball velocity side
        "bvy = bh"; %ball heading becomes ball velocity yaw
        "vvy = vh"; %vis heading becomes vis velocity yaw
        ]
    opt2.pthftv char {mustBeTextScalar} = '' %can optionally pass in path to downsampled fictrac video (optionally downsampled in scopa/register.py); if empty, pthftv it will be derived from pthdaq in ftvalign
    opt2.doplt (1,1) {mustBeMember(opt2.doplt,[0,1]), mustBeNonempty} = 0
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
voltminhd = opt.voltminhd;%
optid = opt.optid;

vpp = opt2.vpp;
nmvel = opt2.nmvel;
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

    load(pthdaqrs, 'dq');

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
    vrenm = strings(size(spl,1),1);
    for k = 1:size(spl,1)
        vrenm(k,:) = string(strjoin([spl(k,1), spl(k,2)], '='));
    end
    vppnew = spl(:,1);
    vppold = spl(:,2);
    vpptypes = spl(:,3);
    vppdv = str2double(spl(:,4));
    if any(~ismember(vppdv, [0,1]))
        error("for each element of string opt2.vpp, dodv (here, vppdv) must be '0' or '1'")
    end
    vpptime = split(spl(strcmp(vpptypes, 't'),2), ',');
    if ~isvector(vpptime)
        error("there must be one and only one element with dodv=1 and type='t' in string array 'vpp'")
    end


    %%%% PARSE nmvel %%%%

    nmvel = convertStringsToChars(erase(nmvel, " "));
    spl = split(nmvel, '=');
    nmvelnew = spl(:,1);
    nmvelold = spl(:,2);


    %%%% LOAD DAQ DATA %%%%

    load(pthdaq, 'trialData', 'outputData')
    trialData = timetable2table(trialData);
    tdvnames = trialData.Properties.VariableNames;
    vtime = string(vpptime(ismember(vpptime, tdvnames)));
    if isempty(vtime)
        error("in vpp, none of the oldnames with type='t' are fields in trialData in the original daqData file; you need a time variable")
    end

    if isduration(trialData.(vtime))
        trialData.(vtime) = seconds(trialData.(vtime));
    end

    if exist('outputData', 'var') && outputData(2)==0 && outputData(end-1)==0 %output data is less accurate than frameClock, since volume (or frame?) seems to complete after outputData ends, but i think frameClock is missing final flyback frames (if they exist)
        fprintf("cropping daq data because runbg is true" + newline)
        firstsamp = find(trialData.frameClock, 1, 'first');
        lastsamp = find(trialData.frameClock, 1, 'last');
        starttime = trialData.(vtime)(firstsamp); %we do this bc sample represents the start of the time bin (not end or center); do this if end: trialData.(vtime)(firstsamp-1); do this if center: (trialData.(vtime)(firstsamp) + trialData.(vtime)(firstsamp-1) ) / 2; but effect on our 10khz daq is negligible, we do 'start' to make t=0
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
            sper_tmp = 1/-rsidx{m};
        else
            sper_tmp = sper;
            if isempty(rsidx{m})
                rskey = numvol;
            else
                if rsidx{m} == 0
                    rsinds_tmp = daqidx.vol;
                else
                    rsinds_tmp = binary2count(daqidx.slice==rsidx{m}); %each slice
                end
                riu = unique(rsinds_tmp(rsinds_tmp~=0), 'stable'); %index of each resampling register (frame or volume)
                rskey = cell(numel(riu), 1);
                parfor k = 1:numel(riu)
                    rskey{k} = find(rsinds_tmp==riu(k)); %do this once, before operating on variable, since this is the slow part; we use find because a boolean array holding all inds would be way too large, and this let's us find all inds once, and reuse them for all daq variables;
                end
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
                if strcmp(vpptypes{k}, 'r')
                    tmp = wrapToPi(tmp/(voltlim(2)-voltlim(1))*2*pi+voltminhd); %put in range -pi to pi, with 0 in front of fly
                end
                if strcmp(vpptypes{k}, 'b')
                    if all(tmp == 0 | tmp == 1, 'all')
                        tmp = binary2count(tmp);
                    else
                        error("variable " + tdvname + " was assigned vpptype 'b', but it is not binary")
                    end
                end

                vtype = regexprep2(vpptypes{k}, {'t', 'm', 'b'}, {'n', 'r', 'c'}, whole=1); %rename some vpptypes to obtain vtype; vtype is input for functions vecrs and vecdv; in these functions, t needs to get the same treatment as n, m the same as r, and b the same as c (t, m, and b aren't valid vtypes in vecrs and vecdv)

                tmp_o = tmp; %set aside before resampling, in case plotting below

                tmp = vecrs(vtype, tmp, rskey); %resample into imaging rate
                tmpdv = vecdv(vtype, tmp, lensec=dvlensec, ord=dvord, sper=sper_tmp); %find local slope (velocity for some vars)

                if doplt
                    tsplt([], tmp, [], tmp_o, xseg=20, titlein=tdvname, pthgif=[pthauto() tdvname '_.gif'])
                    tsplt([], tmpdv, [], tmp_o, xseg=20, titlein=tdvname, pthgif=[pthauto() tdvname '_dv_.gif'])
                end

                if strcmp(vpptypes{k}, 'm')
                    tmp = unwrap(tmp);  %unwrap circular
                    tmp = tmp - tmp(1); %zero
                    tmp = tmp*balldia/2; %convert from radians to mm
                    tmpdv = tmpdv*balldia/2; %convert to mm
                end

                if strcmp(vpptypes{k}, 't') %we do this because we consider each sample to represent start of time bin (not end or center), make sure time starts at zero, for rsidx=[], it is artifactually slightly above zero
                    tmp(1) = 0;
                end

                nm = regexprep2(tdvname, strsplit(vppold{k}, ','), vppnew{k}, whole=1);

                if m>1 && ~isequal(numel(tmp), size(dq.(nm)(m,:), 2))
                    error("resampled vector length does not match previous; this should only happen if rsidx has multiple nonnegative values; one of the values you chose for rsidx might correspond to a slice that appears in fewer volumes than a previous value for rsidx; you cannot use this current problematic value")
                end
                
                dq.(nm)(m,:) = tmp; %make it row vector to place time last (a2p convention)

                if ismember(nm, nmvelold)
                    nmveltmp = regexprep2(nm, nmvelold, nmvelnew, whole=1); %derive fieldname of derivative/velocity from opt2.nmvel
                    dq.(nmveltmp)(m,:) = tmpdv; %make it row vector to place time last (a2p convention)
                end

            elseif isempty(tdvname)
                fprintf("warning, trialData field '" + vppold{k} + "' is not listed in vpp oldnames, so it will not be processed and will not appear in output struct 'dq'" + newline)
            else
                error("in oldnames listed in vpp, there are multiple matches to trialData field " + vppold{k})
            end

        end

    end


    %%%% FLY PATH %%%%

    bvfang = dq.bvf/(balldia/2); %above these were scaled to mm, so revert
    bvsang = dq.bvs/(balldia/2); %above these were scaled to mm, so revert
    [dq.px, dq.py] = ficpath(bvfang, 'r/s', bvsang, 'r/s', dq.vh, 'r', dq.t, 's', balldia, 'mm'); %flat path according to visual stim heading
    [dq.pxb, dq.pyb] = ficpath(bvfang, 'r/s', bvsang, 'r/s', dq.bh, 'r', dq.t, 's', balldia, 'mm'); %flat path according to ball heading


    %%%% EPOCHS  %%%%

    try
        [hc, hce, bin] = histcounts(dq.epochts);
        hc = [min(hc) hc min(hc)]; %hack to include the endpoints of histcounts as peaks
        [~, pkx] = findpeaks(hc);
        numepoch = numel(pkx); % numepoch_alt = numel(unique(bin)), will this always be the same as numel(pkx); if so this is a simpler way to do it?
        dq.epochts = discretize(dq.epochts, numepoch);
        if numel(unique(dq.epochts))~=numepoch
            error("unique epochts must equal numepoch")
        end
    catch ME
        fprintf("setting dq.epochts to empty because of this error: " + ME.message + newline)
        dq.ftv = [];
    end


    %%%% RESAMPLE FICTRAC VIDEO %%%%

    try
        volrate = 1/sper_tmp;
        numpkthr = 10; %in laser oscillation timeseries, number of contiguous peaks with periodic distance to be considered the start of the imaging trial, and also the end when applied in the reverse direction; this could just be same as numvol, but in case there are missing peaks, making this number smaller . . . max would be  round(numvol*0.8)
        topkp = [];   % keep empty to draw where laser is brightest; fraction of vertical top of fictrac video frames to consider when finding brightest numpx pixels (pedestal at bottom can sometimes be brightest part of image, so this can exclude that); if empty, user prompted to draw roi
        smlenpx = []; %window length for gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
        numpx = [];  %keep empty is topkp is empty, since roi you draw will determine numpx; after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpx' pixels in the mean frame of fictrac video
        smlensec = 1;
        doplt_ftvalign = 1; %show the plots in ftvalign
        ftrate = []; %fictrac rate, hz, only set this to nonempty (eg, ftrate=60) if you don't have pth_dat to derive more precise estimate
        dq.ftv = ftvalign(rskey=dq.ftcam, pthdaq=pthdaq, numvol=numvol, imrate=volrate, ...
            numpkthr=numpkthr, topkp=topkp, smlenpx=smlenpx, numpx=numpx, smlensec=smlensec, ftrate=ftrate, ...
            pth_vid=pthftv, doplt=doplt_ftvalign);
    catch ME
        fprintf("setting dq.ftv to empty because of this error: " + ME.message + newline)
        dq.ftv = [];
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







