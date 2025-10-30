function [posx, posy] = ficpath(vf, vfu, vs, vsu, hd, hdu, t, tu, ballr, ballru, doplt)

%{

use fictrac data to compute fictive "flat path" (xy position)
input units required after each input (to help user prevent unit mistakes) 
currently only one option for each unit, but in future, units will be flexible

%}

arguments
    vf (1,:) double {mustBeVector} % angular forward velocity, units vfu
    vfu string {mustBeTextScalar, mustBeMember(vfu,"r/s")} %vf units
    vs (1,:) double {mustBeVector} % angular side velocity, units vsu
    vsu string {mustBeTextScalar, mustBeMember(vsu,"r/s")} %vs units
    hd (1,:) double {mustBeVector} % heading, units hdu
    hdu string {mustBeTextScalar, mustBeMember(hdu,"r")} %hd units
    t (1,:) double {mustBeVector} % timestamp for each sample, units tu
    tu string {mustBeTextScalar, mustBeMember(tu,"s")} %t units
    ballr (1,1) double % ball radius, units ballru
    ballru string {mustBeTextScalar, mustBeMember(ballru,"mm")} %ballr units
    doplt (1,1) {mustBeBinary} = 0
end


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


if doplt
    pthfig = pthauto(suffix='.gif');
    h = figure; 
    subplot(311); plot(t, vf); title('forward velocity')
    subplot(312); plot(t, vs); title('side velocity')
    subplot(313); plot(t, hd); title('heading')
    fig2gif(h,1,pthfig); close(h)

    pthfig = pthauto(suffix='.gif');
    h = figure;
    plot(posx, posy); title('path')
    fig2gif(h,1,pthfig); close(h)
end


end
