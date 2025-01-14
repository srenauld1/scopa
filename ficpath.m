function [posx, posy] = ficpath(vf, vs, yw, t, balld)

arguments
    vf %forward velocity (mm/s, ie scaled by ball diameter)
    vs %side velocity (mm/s, ie scaled by ball diameter)
    yw %heading (ie yaw)
    t %timestamps for each sample
    balld %ball diameter
end

if isempty(vf) || isempty(vs) || isempty(yw)
    posx = [];
    posy = [];
    fprintf("at least one of vf, vs, or yw, is empty, output will be empty" + newline)
else
    ballr = balld/2;
    vangf = vf / ballr; %vf was scaled by mmpd in daqld; revert for angular
    vangs = vs / ballr; %vs was scaled by mmpd in daqld; revert for angular
    ywz = yw - yw(1); %ywz means "yaw zeroed"
    per = [0 diff(t)]; % median(diff(t));
    dtx = (vangf .* per) .* sin(ywz) + (vangs .* per) .* sin(ywz + pi/2);
    posx = (cumsum(dtx) - dtx(1)) .* ballr;
    dty = (vangf .* per) .* cos(ywz) + (vangs .* per) .* cos(ywz + pi/2);
    posy = (cumsum(dty) - dty(1)) .* ballr;
end


