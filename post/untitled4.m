
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

XvoltsPerStep = (maxVal-minVal)./(xframes);
YvoltsPerStep = (maxVal-minVal)./(yframes);

% Set limits on voltage
rawPanelsData = [resample_with_padding(trialData.PanelsXDimTelegraph, fictrac_rate, NiDaq_rate); resample_with_padding(trialData.PanelsYDimTelegraph, fictrac_rate, NiDaq_rate)]';
rawPanelsData(rawPanelsData < minVal) = minVal;
rawPanelsData(rawPanelsData > maxVal) = maxVal;

% Calculate the frame number (round to nearest integer), & calculate the
% pixel angle of the bar given the frame number.

frX = round((rawPanelsData(:,1) - minVal)./XvoltsPerStep);
frY = round((rawPanelsData(:,2) - minVal)./YvoltsPerStep);
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




