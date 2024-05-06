function daqdata = process_DAQ(pth_fldr, ids, rateim)



[expMetadata,trialMetadata, patternMetadata, fictracMetadata] = load_flyg_metadata(ids, pth_fldr);

%% Get variables

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

newRow = table({ids.datefly_hyphen}, ids.trialnum, 'VariableNames', {'expID', 'trialNum'});

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

[ intYaw, velYaw ] = process_fictrac_signal(trialData.ficTracYaw, patternMetadata.x_num, rateim, ratedaq, ratefictrac, maxvolt, maxFlyVelocity);
[ velSide , intSide ] = ficTracSignalDecoding( trialData.ficTracIntForward , ratedaq , ratefictrac/2,ratefictrac, maxFlyVelocity);
[ velForward , intForward ] = ficTracSignalDecoding( trialData.ficTracIntSide , ratedaq , ratefictrac/2, ratefictrac, maxFlyVelocity);

newRow.trialTime = {seconds(resample_with_padding(seconds(trialData.Time),ratefictrac,ratedaq))'};        % seconds
newRow.intFor = {(intForward * ball/2)'};      % mm
newRow.intSide = {(intSide * ball/2)'};        % mm
newRow.intHD = {(intYaw)'};                    % radians
newRow.velFor = {(velForward * ball/2)'};      % mm/sec
newRow.velSide = {(velSide * ball/2)'};        % mm/sec
newRow.velYaw = {(velYaw)'};                   % radians/sec

% Calculate visual cue position based on X & Y channel pos
if ismember('g4panels',trialData.Properties.VariableNames) && ismember('PanelsYDimTelegraph',trialData.Properties.VariableNames)

    xframes = patternMetadata.x_num;
    yframes = patternMetadata.y_num;
    pixelAngle = arenaExtent/xframes;

    % calculates width of most salient visual cue, ignores fainter
    % background patterns if present but currently requires main cue to be
    % an individual shape of uniform width & either the brightest or darkest component of the pattern

    pattern_2D = patternMetadata.Pats(:,:,1,1);

    if luminance == 0
        pattern_1D = pattern_2D(1,:) == min(pattern_2D(1,:));
    else
        pattern_1D = pattern_2D(1,:) == max(pattern_2D(1,:));
    end

    cueWidth = sum(pattern_1D);

    XvoltsPerStep = (maxvolt-minvolt)./(xframes);
    YvoltsPerStep = (maxvolt-minvolt)./(yframes);

    % Set limits on voltage
    rawPanelsData = [resample_with_padding(trialData.PanelsXDimTelegraph, ratefictrac, ratedaq); resample_with_padding(trialData.PanelsYDimTelegraph, ratefictrac, ratedaq)]';
    rawPanelsData(rawPanelsData < minvolt) = minvolt;
    rawPanelsData(rawPanelsData > maxvolt) = maxvolt;

    % Calculate the frame number (round to nearest integer), & calculate the
    % pixel angle of the bar given the frame number.

    frX = round((rawPanelsData(:,1) - minvolt)./XvoltsPerStep);
    frY = round((rawPanelsData(:,2) - minvolt)./YvoltsPerStep);
    yframeStep = xframes/yframes;

    % takes into account a change in cue pos due to a yframe
    % step
    % may need to change sign depending on the relationship b/w
    % your x & y frame pos values
    disp('Temporary message for Elena: if processing experiments acquired before 12/16/21 flip yframeStepsign to -');
    if yDimxDim == 0
        cuePos = mod(frX - yframeStep*(frY-1),xframes);
    else
        cuePos = mod(frX + yframeStep*(frY-1),xframes);
    end
    cuePos(cuePos==0) = xframes;

    % takes into account cue width & starting pos angle
    % relative to fly
    % may need to change sign depending on the relationship b/w
    % cus pos and and cue angle rel to the fly

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

    newRow.PanelsX = {frX};
    newRow.PanelsY = {frY};
    newRow.cuePos = {cuePos};
    newRow.cueAngle = {cueAngle};

elseif ismember('g4panels',trialData.Properties.VariableNames)

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

    newRow.PanelsX = frX;
    newRow.cuePos = cuePos;
    newRow.cueAngle = cueAngle;
end

% Append to main table
ftData = [ftData; newRow];

end