function [posx, posy] = ficpath(vf, vs, yw, t, balld)

vangf = vf / (balld/2);
vangs = vs / (balld/2);
mmpd = balld * pi / 360; 
ywz = yw - yw(1);
rt = median(diff(t));
dtx = (vangf ./ rt) .* sin(ywz) + (vangs ./ rt) .* sin(ywz + pi/2);
posx = (cumsum(dtx) - dtx(1)) .* mmpd;
dty = (vangf ./ rt) .* cos(ywz) + (vangs ./ rt) .* cos(ywz + pi/2);
posy = (cumsum(dty) - dty(1)) .* mmpd;

end


