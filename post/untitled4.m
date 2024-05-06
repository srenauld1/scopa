xframes = patternMetadata.x_num;
pixelAngle = arenaExtent/xframes;

% calculates width of most salient visual cue, ignores fainter
% background patterns if present but currently requires main cue to be
% an individual shape of uniform width & brightest component of the pattern

pattern_2D = patternMetadata.Pats(:,:,1,1);
pattern_1D = pattern_2D(1,:) == max(pattern_2D(1,:));
cueWidth = sum(pattern_1D);
XvoltsPerStep = (maxVal-minVal)./(xframes);


% Set limits on voltage
rawPanelsData = [resample_with_padding(trialData.g4panels, fictrac_rate, NiDaq_rate)];
rawPanelsData(rawPanelsData < minVal) = minVal;
rawPanelsData(rawPanelsData > maxVal) = maxVal;

% Calculate the frame number (round to nearest integer), & calculate the
% pixel angle of the bar given the frame number.

frX = round((rawPanelsData - minVal)./XvoltsPerStep);
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
