function daqdata = process_DAQ(pth_fldr, ids, rateim, numsamp_im, smoothwindow_sec, slopelen, slopeorder)



[expMetadata,trialMetadata, patternMetadata, fictracMetadata] = load_flyg_metadata(ids, pth_fldr);

%% Get variables %

maxvolt = 10; %need to find this in metadata
minvolt = 0; %need to find this in metadata

if ~trialMetadata.usingPanels
    error("no panels info")
end

if isfield(patternMetadata,'arenaExtent')
    arenaExtent = patternMetadata.arenaExtent;
else
    arenaExtent = 360;
    warning('experiment.arenaExtent missing in experiment CSV, using arenaExtent: 360 degrees')
end

if isfield(patternMetadata,'initialAngle')
    initialAngle = patternMetadata.initialAngle;
else
    initialAngle = -9.375;
    warning('experiment.initialAngle missing in experiment CSV, using initialAngle: 90 degrees')
end

if isfield(patternMetadata,'ball')
    ball = patternMetadata.ball;
else
    ball = 9;
    warning('fictrac.ball.diameter missing in experiment CSV, using ball diameter: 9 mm')
end

if isfield(patternMetadata,'patternLuminance')
    luminance = patternMetadata.patternLuminance;
else
    luminance = 1;
    warning('experiment.patternLuminance missing in experiment CSV, using G3 pattern luminance: 1')
end

if isfield(patternMetadata,'yDimxDimRelationship')
    yDimxDim = patternMetadata.yDimxDimRelationship;
else
    yDimxDim = 1;
    warning('experiment.yDimxDimRelationship missing in experiment CSV, using G3 yDimxDimRelationship: 1')
end

if isfield(patternMetadata,'cuePosAngleRelationship')
    cuePosAngleRel = patternMetadata.cuePosAngleRelationship;
else
    cuePosAngleRel = 1;
    warning('experiment.cuePosAngleRel missing in experiment CSV, using G3 cuePosAngleRel: 1')
end


%%


fndaq = dir(fullfile(pth_fldr,['*',ids.datefly_hyphen,'_daqData_*_trial_'  sprintf( '%03d', ids.trialnum ) '.mat']));

load(fullfile(pth_fldr,fndaq.name),'trialData')

daqdata = table({ids.datefly_hyphen}, ids.trialnum, 'VariableNames', {'expID', 'trialNum'});

ratefictrac = fictracMetadata.fictracRate;
try
    ratedaq = trialMetadata.daqSampRate;
catch
    ratedaq = expMetadata.daqSampRate;
end

maxFlyVelocity = 20; %radians/sec

% Copy important variables, converting units as needed
trialData = timetable2table(trialData);

%% Elena: all Berg4 trials prior to 05/25/22 have the channels for IntSide & IntFor switched

smoothwindow_i = smoothwindow_sec*rateim;

if any(strcmp(trialData.Properties.VariableNames, 'VolumeClock'))
    method_resample = 'timestamps';
    inds = trialData.VolumeClock;
else
    method_resample = 'resample';
    inds = [];
end
iscircular = 1;
[ intYaw, velYaw ] = process_fictrac_signal(trialData.ficTracYaw, method_resample, iscircular, numsamp_im, inds, rateim, ratedaq, ratefictrac, maxvolt, smoothwindow_i, slopelen, slopeorder, maxFlyVelocity);
[ intSide, velSide ] = process_fictrac_signal(trialData.ficTracIntForward, method_resample, iscircular, numsamp_im, inds, rateim, ratedaq, ratefictrac, maxvolt, smoothwindow_i, slopelen, slopeorder, maxFlyVelocity);
[ intForward, velForward ] = process_fictrac_signal(trialData.ficTracIntSide, method_resample, iscircular, numsamp_im, inds, rateim, ratedaq, ratefictrac, maxvolt, smoothwindow_i, slopelen, slopeorder, maxFlyVelocity);


daqdata.trialTime = {seconds(resample_with_padding(seconds(trialData.Time),ratefictrac,ratedaq))'};        % seconds
daqdata.intFor = {(intForward * ball/2)'};      % mm
daqdata.intSide = {(intSide * ball/2)'};        % mm
daqdata.intHD = {(intYaw)'};                    % radians
daqdata.velFor = {(velForward * ball/2)'};      % mm/sec
daqdata.velSide = {(velSide * ball/2)'};        % mm/sec
daqdata.velYaw = {(velYaw)'};                   % radians/sec

if ismember('g4panels',trialData.Properties.VariableNames)% Calculate visual cue position based on X channel pos

    xframes = patternMetadata.x_num;
    pixelAngle = arenaExtent/xframes;

    % calculates width of most salient visual cue, ignores fainter
    % background patterns if present but currently requires main cue to be
    % an individual shape of uniform width & brightest component of the pattern

    pattern_2D = patternMetadata.Pats(:,:,1,1);
    pattern_1D = pattern_2D(1,:) == max(pattern_2D(1,:));
    cueWidth = sum(pattern_1D);
    XvoltsPerStep = (maxvolt-minvolt)./(xframes);


    % Set limits on voltage
    rawPanelsData = [resample_with_padding(trialData.g4panels, ratefictrac, ratedaq)];
    rawPanelsData(rawPanelsData < minvolt) = minvolt;
    rawPanelsData(rawPanelsData > maxvolt) = maxvolt;

    % Calculate the frame number (round to nearest integer), & calculate the
    % pixel angle of the bar given the frame number.

    frX = round((rawPanelsData - minvolt)./XvoltsPerStep);
    cuePos = frX;

    % takes into account cue width & starting pos angle
    % relative to fly

    if cuePosAngleRel == 0
        cueAngle = (initialAngle - ((cuePos - 2) + cueWidth/2).*pixelAngle);
    else
        cueAngle = (initialAngle + ((cuePos - 2) + cueWidth/2).*pixelAngle);
    end

    cueAngle = wrapTo180(cueAngle);

    % clean up/filter (artifacts often present at 180 to -180 transitions)

    cueAngle = smoothdata(cueAngle,'movmedian',5); % can play around with this step
    cueAngle(cueAngle > 180) = 180;
    cueAngle(cueAngle < -180) = -180;

    % debug plot
    % figure();plot(cueAngle)

    % Berg4 default: cue pos counterclockwise to the fly = - angles
    %                cue pos clockwise to the fly = + angles
    % may vary by arena depending on how it/fictrac was setup
    % IMPORTANT: check your arena's coordinate frame

    daqdata.PanelsX = frX;
    daqdata.cuePos = cuePos;
    daqdata.cueAngle = cueAngle;
end


end