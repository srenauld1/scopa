function [dq, s] = dqmake_olheat(s, opt)

%{

dqmake_olheat: build a resampled 'dq' struct for the NEW ("olheat") data-collection
format, analogous to what dqmake does for the old format, but adapted to the fact
that fictrac/behavior/heat variables now live in a separate heat_log CSV (sampled at
fictrac rate, ~50 Hz) rather than on the daq at 10 kHz.

THE PROBLEM THIS SOLVES
    old format: trialData (in the daqData .mat) contained the behavior variables
        (ficTracIntForward, ficTracYaw, g4panels, epoch, ...) sampled on the daq at
        10 kHz, so dqmake could resample them straight onto imaging rate using frameClock.
    new format: the daq only records the imaging clocks (frameClock, lineClock), the two
        sync lines (sync1, sync2), and a few analog outputs (heat_laser, LED_heading,
        g4panelsAO). The actual behavior + heat variables are in a heat_log_*.csv:
            heading_rad, intx_rad, inty_rad, panel_heading, heat_active, heat_voltage_V,
            plus its own sync1, sync2, ft_iteration, time_elapsed_s.
    the heat_log runs on its own clock (it starts before imaging and ends after), so its
    rows must first be aligned onto the daq/imaging timeline before they can be resampled.

ALIGNMENT (how heat_log rows are matched to the daq)
    sync1 is a square wave that toggles once per fictrac iteration and is recorded in BOTH
        files, so each sync1 transition on the daq corresponds to exactly one heat_log row.
    sync2 is an analog "fingerprint" (0-1, slowly varying, ~100 distinct values) recorded
        in both files. Sampling daq sync2 at each sync1 edge gives a per-iteration sequence
        that is matched against the heat_log sync2 column by sliding the (shorter) daq
        sequence over the (longer) heat_log sequence and minimizing SSE. This locks in a
        single sharp offset (verified corr ~1.0), telling us which heat_log row is imaging
        start. sync2 is used (not just a sync2 on/off marker) because sync2 does not gate
        the imaging window.

RESAMPLING
    once each heat_log row has a daq time (= time of its matched sync1 edge), each behavior
    variable is interpolated onto the full daq sample grid and then downsampled to imaging
    volume rate using the frameClock-derived volume index (same machinery dqmake uses:
    vecrs for resampling, vecdv for derivatives). Angular variables are interpolated via
    sin/cos to avoid wrap artifacts; cumulative position (intx/inty) is scaled to mm by the
    ball radius; heat command variables are held (nearest/step).

VARIABLE MAPPING (heat_log -> dq, matching a2p conventions)
    heading_rad   -> bh   (ball heading, radians)          + bvy (yaw velocity)
    intx_rad      -> bf   (forward, mm)                     + bvf (forward velocity, mm/s)
    inty_rad      -> bs   (side, mm)                        + bvs (side velocity, mm/s)
    panel_heading -> vh   (visual/panel heading, radians)   + vvy (visual yaw velocity)
    heat_active   -> heat_active   (0/1, categorical)
    heat_voltage_V-> heat_voltage  (commanded heat voltage, categorical)
    heat_laser (daq analog) -> heatlaser (resampled daq command, for reference)
    px,py   fictive path from forward/side velocity + visual heading
    pxb,pyb fictive path from forward/side velocity + ball heading

SCOPE
    this is the "just alignment + dq" stage. It returns dq (and, if s is a struct, sets
    s.dq and s.t and optionally saves). The remaining a2p stages (roi/bump/model/plots)
    are not run here and can be layered on later, exactly as a2p calls dqmakew then the
    other *makew functions.

%}


arguments

    s = '' % smake stack struct, OR char path to: the recording folder, the daqData .mat, or the stack .mat; if empty, user is prompted to pick the daq file

    opt.rskey (1,1) double {mustBeInteger, mustBeNonnegative} = 0 % 0 = resample to imaging VOLUME rate (only mode supported in this first version); slice-index resampling can be added later like dqmake
    opt.dvlensec (1,1) double {mustBePositive} = 0.5 % window length (s) for the sliding-slope derivative (velocity); larger = smoother
    opt.dvord (1,1) double {mustBeMember(opt.dvord,1:5)} = 2 % polynomial order for the sliding-slope derivative
    opt.usefbl (1,1) {mustBeMember(opt.usefbl,[0 1])} = 1 % include flyback lines when computing slice indices
    opt.usefbf (1,1) {mustBeMember(opt.usefbf,[0 1])} = 1 % include flyback frames when computing volume indices
    opt.balldia (1,1) double {mustBePositive} = 9 % ball diameter (mm) for this rig (bergII: 9 mm per experiment config); used to convert integrated ball rotation to mm
    opt.corrmin (1,1) double {mustBeInRange(opt.corrmin,0,1)} = 0.9 % minimum sync2 correlation at the best offset required to trust the alignment
    opt.doplt (1,1) {mustBeMember(opt.doplt,[0 1])} = 0 % 1 to plot the sync alignment and a few resampled variables
    opt.dosave (1,1) {mustBeMember(opt.dosave,[0 1])} = 0 % 1 to save dq (and t) into the stack .mat, if s is a struct (like dqmakew)

end

if opt.rskey ~= 0
    error("this first version of dqmake_olheat only supports rskey=0 (imaging volume-rate resampling)")
end


%%%% RESOLVE INPUT PATHS (daq .mat, heat_log .csv) AND METADATA %%%%

[pthdaq, pthheatlog, recfld] = olheat_locate(s);
fprintf("dqmake_olheat operating on:" + newline + "  daq:      " + pthdaq + newline + "  heat_log: " + pthheatlog + newline)

md = mdsild(pthdaq); % scanimage metadata (numvol, numslice, numslice_withflyback, sper); mdsild finds/creates the *_mdsi_.txt from the raw stack
numvol               = md.numvol;
numslice             = md.numslice;
numslice_withflyback = md.numslice_withflyback;
sper                 = md.sper; % seconds per volume


%%%% LOAD DAQ, CROP TO IMAGING WINDOW %%%%

S = load(pthdaq, 'trialData');
if ~isfield(S, 'trialData')
    error("daq file does not contain variable 'trialData'")
end
trialData = S.trialData;
if istimetable(trialData)
    trialData = timetable2table(trialData);
end
vnms = trialData.Properties.VariableNames;
for req = ["Time" "frameClock" "sync1" "sync2"]
    if ~ismember(req, vnms)
        error("daq trialData is missing required variable '" + req + "'")
    end
end

% crop to the frameClock-active window so daq time is zeroed at imaging start
fc_raw = double(trialData.frameClock) > 0.5;
firstsamp = find(fc_raw, 1, 'first');
lastsamp  = find(fc_raw, 1, 'last');
if isempty(firstsamp)
    error("frameClock never goes high on the daq; cannot locate the imaging window")
end
trialData = trialData(firstsamp:lastsamp, :);

% daq time vector (seconds, zeroed)
dt = trialData.Time;
if isduration(dt)
    dt = seconds(dt);
end
dt = dt - dt(1);
dt = dt(:);
daqrate = 1/median(diff(dt));
if daqrate < 1/sper*2.5
    error("daq sampling rate (" + daqrate + " Hz) is too slow to resample into imaging rate")
end

frameClock = double(trialData.frameClock) > 0.5;
sync1      = double(trialData.sync1);
sync2      = double(trialData.sync2);


%%%% FRAME/SLICE/VOLUME INDICES FROM frameClock (per daq sample) %%%%

idx = olheat_daqidx(frameClock, dt, numvol, numslice, numslice_withflyback, opt.usefbl, opt.usefbf);
idxvol = idx.vol; % single, per daq sample; with usefbf=1 there are no zeros, so every volume bin is filled
newlen = numel(unique(idxvol(idxvol~=0)));


%%%% LOAD heat_log CSV %%%%

hl = readtable(pthheatlog);
hlcols = hl.Properties.VariableNames;
for req = ["sync1" "sync2" "heading_rad" "intx_rad" "inty_rad" "panel_heading" "heat_active" "heat_voltage_V"]
    if ~ismember(req, hlcols)
        error("heat_log is missing required column '" + req + "'")
    end
end
log_s2 = hl.sync2(:);


%%%% ALIGN heat_log ROWS TO daq VIA sync1 EDGES + sync2 FINGERPRINT %%%%

b1  = sync1 > 0.5;         % threshold sync1 to binary (accounting for error in the voltage signal
edg = find(diff(b1) ~= 0) + 1;                    % daq sample index of each sync1 transition (= one heat_log row each)
if numel(edg) < 10
    error("found too few sync1 edges on the daq (" + numel(edg) + "); cannot align")
end
daq_s2 = sync2(edg);                              % daq sync2 fingerprint sampled at each sync1 edge
daq_te = dt(edg);                                 % daq time of each edge

a = daq_s2(:);  b = log_s2(:);
n = numel(a);   m = numel(b);
if n > m
    error("more daq sync1 edges (" + n + ") than heat_log rows (" + m + "); unexpected, cannot align")
end
% slide the (shorter) daq fingerprint over the (longer) heat_log fingerprint, minimize SSE of z-scored signals
az = (a - mean(a)) / std(a);
sse = inf(m - n + 1, 1);
for off = 0:(m - n)
    seg = b(off + (1:n));
    bz = (seg - mean(seg)) / std(seg);
    d = az - bz;
    sse(off + 1) = d.' * d;
end
[bestsse, bi] = min(sse);
offset = bi - 1;                                  % 0-based: heat_log row (offset+1) is the first daq sync1 edge (imaging start)
ssesort = sort(sse);
secondsse = ssesort(min(2, numel(ssesort)));
% correlation at the best offset, as an alignment-quality check
segbest = b(offset + (1:n));
alcorr = corr_local(a, segbest);
fprintf("sync alignment: heat_log row %d = imaging start; corr=%.4f; best SSE=%.3g (next best %.3g)\n", offset+1, alcorr, bestsse, secondsse);
if alcorr < opt.corrmin
    error("sync alignment correlation (%.4f) is below corrmin (%.2f); alignment is not trustworthy", alcorr, opt.corrmin);
end

% matched heat_log rows (1-based), one per daq sync1 edge
mrows = offset + (1:n).';


%%%% PLACE heat_log VARIABLES ON THE daq SAMPLE GRID %%%%

% angular variables (radians, wrapped): interpolate via sin/cos to avoid wrap artifacts
bh_daq = interp_ang(daq_te, hl.heading_rad(mrows),   dt);
vh_daq = interp_ang(daq_te, hl.panel_heading(mrows), dt);

% cumulative ball rotation (radians, already unwrapped): interpolate linearly, scale to mm by ball radius
ballr = opt.balldia/2;
bf_daq = interp1(daq_te, hl.intx_rad(mrows), dt, 'linear', 'extrap') * ballr;
bs_daq = interp1(daq_te, hl.inty_rad(mrows), dt, 'linear', 'extrap') * ballr;

% heat command variables (heat_active 0/1, heat_voltage_V 0/2) are step signals where 0 is a
% valid state, so they are NOT put on the daq grid / resampled with vecrs 'c' (which treats 0 as
% missing). They are sampled (held) directly at each volume centroid time further below.

% daq-native analog heat_laser command (already at daq rate), for reference
if ismember("heat_laser", string(trialData.Properties.VariableNames))
    heatlaser_daq = double(trialData.heat_laser);
else
    heatlaser_daq = [];
end


%%%% RESAMPLE TO IMAGING VOLUME RATE (vecrs) + DERIVATIVES (vecdv) %%%%

rk = single(idxvol(:));

dq = [];
tvol  = vecrs('n', dt(:), rk);                                 % absolute volume centroid times (daq reference)
dq.t  = zerofirst(tvol);                                       % time (s), zeroed
dq.bh = vecrs('r', bh_daq(:), rk);
dq.bf = vecrs('n', bf_daq(:), rk);
dq.bs = vecrs('n', bs_daq(:), rk);
dq.vh = vecrs('r', vh_daq(:), rk);
if ~isempty(heatlaser_daq)
    dq.heatlaser = vecrs('n', heatlaser_daq(:), rk);
end

% heat command variables: hold (step) at each volume centroid; 0 is a valid state, so sample
% directly (not via vecrs 'c'). fillmissing guards the first/last centroid if just outside the
% sync-edge time range.
dq.heat_active  = fillmissing(interp1(daq_te, hl.heat_active(mrows),    tvol, 'previous', 'extrap'), 'nearest');
dq.heat_voltage = fillmissing(interp1(daq_te, hl.heat_voltage_V(mrows), tvol, 'previous', 'extrap'), 'nearest');

dq.bvy = vecdv('r', dq.bh, lensec=opt.dvlensec, ord=opt.dvord, sper=sper); % yaw velocity (rad/s)
dq.bvf = vecdv('n', dq.bf, lensec=opt.dvlensec, ord=opt.dvord, sper=sper); % forward velocity (mm/s)
dq.bvs = vecdv('n', dq.bs, lensec=opt.dvlensec, ord=opt.dvord, sper=sper); % side velocity (mm/s)
dq.vvy = vecdv('r', dq.vh, lensec=opt.dvlensec, ord=opt.dvord, sper=sper); % visual yaw velocity (rad/s)


%%%% PUT TIME IN LAST (2nd) DIMENSION, a2p CONVENTION (row vectors) %%%%

fn = fieldnames(dq);
for k = 1:numel(fn)
    v = dq.(fn{k});
    if isnumeric(v) && isvector(v) && ~isempty(v)
        if size(v, ndims(v)) ~= newlen
            v = v.';
        end
        if size(v, ndims(v)) ~= newlen
            error("dq." + fn{k} + " has length " + numel(v) + " but expected " + newlen);
        end
        dq.(fn{k}) = v;
    end
end


%%%% FICTIVE PATH %%%%

bvfang = dq.bvf/ballr; % mm/s -> rad/s (ficpath wants angular velocity)
bvsang = dq.bvs/ballr;
[dq.px,  dq.py ] = ficpath(bvfang, 'r/s', bvsang, 'r/s', dq.vh, 'r', dq.t, 's', opt.balldia, 'mm'); % path under visual heading
[dq.pxb, dq.pyb] = ficpath(bvfang, 'r/s', bvsang, 'r/s', dq.bh, 'r', dq.t, 's', opt.balldia, 'mm'); % path under ball heading


%%%% RECORD METADATA IN dq %%%%

dq.rskey       = opt.rskey;
dq.pthdaq      = pthdaq;
dq.pthheatlog  = pthheatlog;
dq.recfld      = recfld;
dq.syncoffset  = offset;      % 0-based heat_log row of imaging start
dq.synccorr    = alcorr;      % sync2 correlation at the chosen offset
dq.balldia     = opt.balldia;
dq.opt         = opt;


%%%% PLOTS (optional) %%%%

if opt.doplt
    figure('Name', 'dqmake_olheat: sync alignment');
    subplot(211);
    plot(1:n, (a-mean(a))/std(a), 'k'); hold on;
    plot(1:n, (segbest-mean(segbest))/std(segbest), 'r--');
    legend('daq sync2 @ edges', 'heat\_log sync2 @ offset'); title(sprintf('sync2 alignment (corr=%.4f, offset row=%d)', alcorr, offset+1));
    xlabel('iteration'); ylabel('z-scored sync2');
    subplot(212);
    plot(dq.t, dq.bh, 'b'); hold on; plot(dq.t, dq.vh, 'r');
    legend('bh (ball heading)', 'vh (visual heading)'); xlabel('time (s)'); ylabel('rad'); title('resampled headings');
end


%%%% OPTIONALLY WRITE INTO s AND SAVE %%%%

if isstruct(s)
    s.dq = dq;
    s.t  = dq.t;
    if opt.dosave
        if isfield(s, 'pth') && ~isempty(s.pth)
            matsv(s.pth, 'dq', 't', s = s);
            fprintf("saved dq and t into " + s.pth + newline);
        else
            fprintf("dosave requested but s has no .pth; skipping save" + newline);
        end
    end
end

end



%==================================================================================================
function [pthdaq, pthheatlog, recfld] = olheat_locate(s)
% resolve the daq .mat, heat_log .csv, and recording folder from s (struct or path)

if isstruct(s)
    if isfield(s, 'pth') && ~isempty(s.pth)
        recfld = fileparts(s.pth);
    elseif isfield(s, 'pthstack') && ~isempty(s.pthstack)
        recfld = fileparts(s.pthstack);
    elseif isfield(s, 'pthdaq') && ~isempty(s.pthdaq)
        recfld = fileparts(s.pthdaq);
    else
        error("input struct s has no .pth, .pthstack, or .pthdaq to locate the recording folder");
    end
elseif ischar(s) || isstring(s)
    s = char(s);
    if isempty(s)
        [fn, loc] = uigetfile('*daqData*trial*.mat', 'choose the daqData .mat file');
        if isequal(fn, 0)
            error("you cancelled file selection; pass in a stack struct or a path");
        end
        recfld = loc;
    elseif isfolder(s)
        recfld = s;
    elseif isfile(s)
        recfld = fileparts(s);
    else
        error("input path does not exist: " + string(s));
    end
else
    error("s must be a struct or a char/string path");
end

d = dir(fullfile(recfld, '*daqData*trial*.mat'));
if isempty(d)
    error("no *daqData*trial*.mat file found in " + string(recfld));
end
pthdaq = fullfile(d(1).folder, d(1).name);

h = dir(fullfile(recfld, 'heat_*.csv'));
if isempty(h)
    error("no heat_log_*.csv file found in " + string(recfld));
end
pthheatlog = fullfile(h(1).folder, h(1).name);

end



%==================================================================================================
function idx = olheat_daqidx(frameon, t, numvol, numslice, numslice_withflyback, usefbl, usefbf)
% compute per-daq-sample frame/slice/volume indices from the frameClock.
% adapted from the local daqidxmake function inside dqmake.m; hard errors softened to
% warnings so a slightly-incomplete final volume does not block the whole pipeline.

frameon = logical(frameon(:));
t = t(:);

% frame indices
idxframe = binary2count(frameon);
numvol_daq = max(idxframe)/numslice_withflyback;
if numvol_daq ~= numvol
    daq_underflow = numvol - numvol_daq;
    if daq_underflow > 0
        fprintf("warning: volumes computed from daq frames (%.3f) < scanimage numvol (%d) by %.3f\n", numvol_daq, numvol, daq_underflow);
    else
        fprintf("warning: volumes computed from daq frames (%.3f) > scanimage numvol (%d); overflow\n", numvol_daq, numvol);
    end
end

% flyback LINES: samples with idxframe==0 fall between frames (frameClock low). If usefbl,
% assign each the nearest frame index so it is included; otherwise leave them as 0 (excluded).
if usefbl
    kp = idxframe == 0;
    if any(kp)
        idxframe(kp) = interp1(t(~kp), idxframe(~kp), t(kp), 'nearest', 'extrap');
    end
end
nz = idxframe > 0; % samples assigned to a real imaging frame

% slice and volume indices by direct integer division of the frame index. This works for any
% flyback count, including flyback==0 (unlike dqmake's daqidxmake, which delimits volumes by
% flyback-frame gaps and so collapses to a single volume when there are no flyback frames).
idxslice = zeros(size(idxframe));
idxvol   = zeros(size(idxframe));
idxslice(nz) = mod(idxframe(nz) - 1, numslice_withflyback) + 1;          % 1..numslice_withflyback
idxvol(nz)   = floor((idxframe(nz) - 1) / numslice_withflyback) + 1;     % 1..numvol

% flyback FRAMES: slices beyond numslice are discard/flyback frames. If usefbf, keep them
% assigned to their volume (they already are); otherwise zero them out (exclude).
if ~usefbf
    isfb = idxslice > numslice;
    idxframe(isfb) = 0;
    idxslice(isfb) = 0;
    idxvol(isfb)   = 0;
end

if any(isnan([idxframe; idxslice; idxvol]))
    error("there should be no nans in any daq index");
end

idx.frame = single(idxframe);
idx.slice = single(idxslice);
idx.vol   = single(idxvol);

end



%==================================================================================================
function vq = interp_ang(tq_known, vq_known, tq)
% interpolate wrapped angular data (radians) onto tq by interpolating sin and cos, avoiding
% wrap discontinuities; output is wrapped to (-pi, pi]
s = interp1(tq_known, sin(vq_known), tq, 'linear', 'extrap');
c = interp1(tq_known, cos(vq_known), tq, 'linear', 'extrap');
vq = atan2(s, c);
end



%==================================================================================================
function v = zerofirst(v)
% shift a vector so its first element is 0 (used for the resampled time vector)
if ~isempty(v)
    v = v - v(1);
end
end



%==================================================================================================
function c = corr_local(x, y)
% pearson correlation without the Statistics Toolbox
x = x(:); y = y(:);
x = x - mean(x); y = y - mean(y);
denom = sqrt(sum(x.^2) * sum(y.^2));
if denom == 0
    c = 0;
else
    c = sum(x .* y) / denom;
end
end
