function [posx, posy] = ficpath(vf, vfu, vs, vsu, hd, hdu, t, tu, ballr, ballru, doplt)

%{

compute fictive path (x and y position)
input units designated after each input 
currently only one option for each unit, to help prevent unit mistakes, and also allow unit flexibility in future

%}

arguments
    vf % angular forward velocity, units vfu
    vfu %vf units 
    vs % angular side velocity, , units vsu
    vsu %vs units
    hd % heading, units hdu
    hdu %hd units
    t % timestamp for each sample, units tu
    tu %t units 
    ballr % ball radius, units ballru
    ballru %ballr units
    doplt = 0
end

%%%% make sure units are correct (see allowed units below) %%%% 

unitcheck(vfu, 'radians/second')
unitcheck(vsu, 'radians/second')
unitcheck(hdu, 'radians')
unitcheck(tu, 'seconds')
unitcheck(ballru, 'millimeters')

%%%% row vectors to put time in 2nd dim %%%% 

vf = vf(:)';
vs = vs(:)';
hd = hd(:)';
t = t(:)';

%%%% compute path %%%% 

if isempty(vf) || isempty(vs) || isempty(hd)
    posx = [];
    posy = [];
    fprintf("at least one of vf, vs, or hd, is empty, output will be empty" + newline)
else
    ballr = ballr/2;
    hdz = hd - hd(1); % heading zeroed 
    per = [0 diff(t)]; 
    dtx = (vf .* per) .* sin(hdz) + (vs .* per) .* sin(hdz + pi/2);
    posx = (cumsum(dtx) - dtx(1)) .* ballr;
    dty = (vf .* per) .* cos(hdz) + (vs .* per) .* cos(hdz + pi/2);
    posy = (cumsum(dty) - dty(1)) .* ballr;
end

%%%% plot %%%% 

if doplt
    pthfig = pathauto(suffix='.gif');
    h = figure; 
    subplot(311); plot(t, vf); title('forward velocity')
    subplot(312); plot(t, vs); title('side velocity')
    subplot(313); plot(t, hd); title('heading')
    fig2gif(h,1,pthfig); close(h)

    pthfig = pathauto(suffix='.gif');
    h = figure;
    plot(posx, posy); title('path')
    fig2gif(h,1,pthfig); close(h)
end

end

function unitcheck(nm, unit)

if ~strcmpi(strtrim(nm), strtrim(unit))
    error(nm + " must be " + unit)
end

end