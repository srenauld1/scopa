function [posx, posy] = ficpath(vf, vs, yw, t, balld)

mmpd = balld/2; 
vangf = vf / mmpd; %vf was scaled by mmpd in daqld; revert for angular 
vangs = vs / mmpd; %vs was scaled by mmpd in daqld; revert for angular 
ywz = yw - yw(1);
per = [0 diff(t)]; % median(diff(t));
dtx = (vangf .* per) .* sin(ywz) + (vangs .* per) .* sin(ywz + pi/2);
posx = (cumsum(dtx) - dtx(1)) .* mmpd;
dty = (vangf .* per) .* cos(ywz) + (vangs .* per) .* cos(ywz + pi/2);
posy = (cumsum(dty) - dty(1)) .* mmpd;

end


