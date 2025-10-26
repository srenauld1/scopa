
function vecout = vecdv(vtype, vecin, opt)

%{

differentiate vector over sliding window using user-specified window length (seconds or samples) and polynomial model order
input vector can be circular (radians or degrees) or "categorical" or "normal" (see vtype notes below); 
vecin and vecout orientations are matched
todo: generalize for nd

%}


arguments
    vtype char {mustBeTextScalar, mustBeMember(vtype, {'n', 'r', 'd', 'c'})} % 'r' radians, 'd' degrees, 'c' categorical (not necessarily categorical, just means it uses nearest interp, so output contains only input values), 'n' everything else
    vecin {mustBeVector} %vector to be differentiated; if vtype is r or d, must be circular data in radians or degrees, respectively
    opt.lensamp double {mustBeScalarOrEmpty, mustBePositive} = [];  % window length in samples used to fit slope; make empty to have this derived automatically to be as short as possible, given sample rate and ord
    opt.lensec double {mustBeScalarOrEmpty, mustBePositive} = []; % window length in seconds used to fit slope; make empty to have this derived automatically to be as short as possible, given sample rate and ord
    opt.ord (1,1) double {mustBeMember(opt.ord,1:8)} = 2; % order of polynomial used to fit local slope
    opt.sper double {mustBeScalarOrEmpty, mustBePositive} = []; %sample period in seconds; required if lensec is nonempty
end
lensamp = opt.lensamp;
lensec = opt.lensec;
sper = opt.sper;
ord = opt.ord;

wasrow = 0;
if isrow(vecin)
    wasrow = 1;
    vecin = vecin';
end

if ~isempty(lensamp) && ~isempty(lensec)
    error("opt.lensamp or opt.lensec cannot both be nonempty")
end
if ~isempty(lensec) && isempty(sper)
    error("opt.sper must be nonempty if opt.lensec is nonempty")
end
if isempty(lensec) && isempty(lensamp) && ~isempty(sper)
    lensec = sper*ord+1;
end
if isempty(lensamp) && ~isempty(lensec)
    lensamp = round(lensec / sper);
end
if lensamp<ord+1
    error("movingslope will error because lensamp is less than ord+1; your value of lensec, given value of sper (sample period), gives lensamp less than ord+1; use a different lensamp and/or ord (likely just lensamp should be changed)")
end

if strcmp(vtype, 'r') || strcmp(vtype, 'd') % differentiate angular variable 

    if strcmp(vtype, 'd')
        vecin = deg2rad(vecin);
    end

    inpx = cos(vecin);
    inpy = sin(vecin);

    inpdx = movingslope(inpx, lensamp, ord, sper);
    inpdy = movingslope(inpy, lensamp, ord, sper);

    denom = inpx.^2 + inpy.^2;
    vecout = (-inpy ./ denom).*inpdx + (inpx ./ denom).*inpdy; %formula for derivative of atan2(y,x)

elseif strcmp(vtype, 'n') % differentiate non-angular variable 

    vecout = movingslope(vecin, lensamp, ord, sper);

elseif strcmp(vtype, 'c') %differentiate "categorical" variable 

    filt = [zeros(1,lensamp-1), 1, zeros(1,lensamp-1), -1];
    vecout = conv(vecin, filt, 'full');
    vecout = vecout((numel(filt) - 1)+1:end-(numel(filt) - (1 + (lensamp-1))));
    vecout = cat(1, zeros((lensamp-1)+1, 1), vecout);

end


if strcmp(vtype, 'd')
    vecout = rad2deg(vecout);
end

if wasrow
    vecout = vecout';
end
