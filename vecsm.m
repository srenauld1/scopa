function vecout = vecsm(vtype, vecin, opt)

%{

smooth vector (with matlab function smoothdata) using user-specified window length (seconds or samples) 
input vector can be angular (radians or degrees) or categorical or "normal"; 
vecin and vecout orientations are matched
todo: generalize for nd

%}

arguments
    vtype char {mustBeTextScalar, mustBeMember(vtype, {'n', 'r', 'd', 'c'})} % 'r' radians, 'd' degrees, 'c' categorical (not necessarily categorical, just means it uses nearest interp, so output uses only input values), 'n' everything else
    vecin {mustBeVector} %input variable to be differentiated; must be in radians if vtype is angular
    opt.lensamp double {mustBeScalarOrEmpty, mustBePositive} = [];  % window length in samples used to fit slope; make empty to have this derived automatically to be as short as possible, given sample rate and ord
    opt.lensec double {mustBeScalarOrEmpty, mustBePositive} = []; % window length in seconds used to fit slope; make empty to have this derived automatically to be as short as possible, given sample rate and ord
    opt.sper double {mustBeScalarOrEmpty, mustBePositive} = []; %sample period in seconds; required if lensec is nonempty
end
lensamp = opt.lensamp;
lensec = opt.lensec;
sper = opt.sper;

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

if isempty(lensamp) && ~isempty(lensec)
    lensamp = round(lensec / sper);
end


if strcmp(vtype, 'r') || strcmp(vtype, 'd') 

    if strcmp(vtype, 'd')
        vecin = deg2rad(vecin);
    end

    tmpx = cos(vecin);
    tmpy = sin(vecin);
    tmpx = smoothdata(tmpx, 'gaussian', lensamp, 'omitnan');
    tmpy = smoothdata(tmpy, 'gaussian', lensamp, 'omitnan');
    vecout = atan2(tmpy, tmpx);

    if strcmp(vtype, 'd')
        vecout = rad2deg(vecout);
    end

elseif strcmp(vtype, 'n')

    vecout = smoothdata(vecin, 'gaussian', lensamp, 'omitnan');

elseif strcmp(vtype, 'c')

    error("need to write categorical smooth (?)")

end

if wasrow
    vecout = vecout';
end