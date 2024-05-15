function plot_vonmises_polar(pars, tdat, fns, pcol, ttick, tticklab)

% plots von mises on polarplot, given parameters in argument 'pars'
% 'pars' is the only required input

%inputs
% pars (required): 4 element vector of von mises parameters [amplitude, concentration, location, baseline)
% tdat: vector of theta data in radians, or scalar for tdat uniform samples -pi to pi,
%       if tdat is not supplied as argument, tdat is 1000 uniform samples -pi to 2*pi-(2*pi/1000)
% fns: save path prefix (omit extension); if none supplied, saved in same directory as this function, with datetime suffix

% pcol: plot color; string or triplet; blue is default if none supplied
% ttick: theta ticks; [0 90 180 270] is default if none supplied
% tticklab: theta ticks labels; cell array of char elements; {'0', '', '180', '270'} is default if none supplied

% example: pars = [1 .5 0 0]; plot_vonmises_polar(pars)

%% check inputs

if ~exist('tdat', 'var') || isempty(tdat)
    nsamp = 1000;
    tdat = linspace(-pi, pi, nsamp);
    tdat = tdat(1:end-1);
end
if ~exist('fns', 'var') || isempty(fns)
    [pthenv, ~, ~] = fileparts(matlab.desktop.editor.getActiveFilename);
    fns = [pthenv filesep];
end
if ~exist('pcol', 'var') || isempty(pcol)
    pcol = [0 0 1];
end
if ~exist('ttick', 'var') || isempty(ttick)
    ttick = [0 90 180 270];
end
if ~exist('tticklab', 'var') || isempty(tticklab)
    tticklab = {'0', '', '180', '270'};
end


%% compute rho data

rdat = pars(1)*exp(pars(2)*cos(tdat-pars(3)))+pars(4); %von mises function

%% compute fwhm and amp

fwhm = 2 * abs( acos( 1/pars(2) * log( 1/2 *( exp(pars(2)) + exp(-pars(2)) ))));
amp = pars(1) * ( exp(pars(2)) - exp(-pars(2)) );

%% plot

hfg = figure;
ax = axes('Parent', hfg);
pax = polaraxes('Units', ax.Units, 'Position', ax.Position);


hpl = polarplot(pax, tdat, rdat); %plot


%adjust plot
pax.RLim = [min(rdat(:)) max(rdat(:))];
hpl.Color = pcol;
pax.ThetaTick = ttick;
pax.ThetaTickLabel = tticklab;
pax.ThetaZeroLocation = 'right';
pax.ThetaDir = 'counterclockwise';
ax.YAxis.Visible = 'off';
ax.XAxis.Visible = 'off';
ax.XAxis.Visible = 'off';
ax.Title.String = {['pars:  ' num2str(pars)]; ['FWHM (rad): ' num2str(fwhm) '   amp: ' num2str(amp) '   center (rad): ' num2str(pars(3)) '   baseline: ' num2str(pars(4))]};


%% save

date_insert = char(datetime('now','TimeZone','local','Format','yyMMddHHmmss')); %unique ID connecting param file to texture file and noise values file (if it exists)

fns = [fns(1:end-4) date_insert '_.fig'];

saveas( gcf, [fns '_.fig'])

