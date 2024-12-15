
function plot_coh_freq(wcoh,wcs,FourierFactor,sigmaT,freq,t,nov,mc,normfreqflag)

figure; 

if normfreqflag
    frequnitstrs = wavelet.internal.wgetfrequnitstrs;
    ylbl = frequnitstrs{1};
    coifactorfreq = 1;
    
elseif ~normfreqflag
    [freq,eng_exp,uf] = engunits(freq,'unicode');
    coifactorfreq = eng_exp;
    ylbl = wavelet.internal.wgetfreqlbl([uf 'Hz']);
    
end
if normfreqflag
    ut = 'Samples';
    dt = 1;
    coifactortime = 1;
else
    [t,eng_exp,ut] = engunits(t,'unicode','time');
    coifactortime = eng_exp;
    dt = mean(diff(t));
end

N = size(wcoh,2);

% We have to recompute the cone of influence for whatever scaling
% is done in time and frequency by engunits
% dt = dt*coifactortime;

FourierFactor = FourierFactor/coifactorfreq;
sigmaT = sigmaT*coifactortime;
coiScalar = FourierFactor/sigmaT;
samples = createCoiIndices(N);
coi = coiScalar*dt*samples;
invcoi = 1./coi;

maxFreq = cast(max(freq),'like',invcoi);
minFreq = cast(min(freq),'like',invcoi);

invcoi = min(invcoi,maxFreq,'includenan');

Yticks = 2.^(round(log2(minFreq)):round(log2(maxFreq)));

AX = newplot;
setappdata(AX,'evstruct',[]);

f = ancestor(AX,'figure');
cla(AX,'reset');
imagesc(t,log2(freq),wcoh);

AX.CLim = [0 1];
AX.YLim = log2([minFreq, maxFreq]);
AX.YTick = log2(Yticks);
AX.YDir = 'normal';
set(AX,'YLim',log2([minFreq, maxFreq]), ...
    'layer','top', ...
    'YTick',log2(Yticks(:)), ...
    'YTickLabel',num2str(sprintf('%g\n',Yticks)), ...
    'layer','top');
ylabel(ylbl)
xlbl = [getString(message('Wavelet:getfrequnitstrs:Time')) ' (' ut ')'];
xlabel(xlbl);
title(getString(message('Wavelet:wcoherence:CoherenceTitle')));
hold(AX,'on');
hcol = colorbar;
hcol.Label.String = 'Magnitude-Squared Coherence';
plot(AX,t,log2(invcoi),'w--','linewidth',2);
theta = angle(wcs);
theta(wcoh< mc)= NaN;
if all(isnan(theta))
    return;
end

% Create mesh grid for phase plot
tspace = ceil(size(theta,2)/40);
pspace = round(2^log2(size(theta,1)/nov/2));
tax = t(1:tspace:size(theta,2));
pax = freq(1:pspace:size(theta,1));
plotPhaseVectors(AX,theta,tax,pax,tspace,pspace);
hzoom = zoom(f);
cbzoom = @(~,evd)zoomArrows(evd,theta,tax,pax,tspace,pspace);
cbfig = @(hobject,evd)ResizeFig(hobject,evd,theta,tax,pax,tspace,pspace);
evstruct.sclistener = event.listener(f,'SizeChanged',cbfig);
evstruct.ylimlistener = event.proplistener(AX,AX.findprop('YLim'),...
    'PostSet',cbfig);
evstruct.xlimlistener = event.proplistener(AX,AX.findprop('XLim'),...
    'PostSet',cbfig);
setappdata(AX,'evstruct',evstruct);
set(hzoom,'ActionPostCallback',cbzoom);
% Set NexPlot to replace
f.NextPlot = 'replace';
end
%--------------------------------------------------------------------------

function plotPhaseVectors(axhandle,theta,tax,pax,tspace,pspace)
if ~isempty(findobj(axhandle,'type','patch'))
    delete(findobj(axhandle, 'type', 'patch'));
end

[tgrid,pgrid]=meshgrid(tax,log2(pax));
theta = theta(1:pspace:size(theta,1),1:tspace:size(theta,2));

idx = find(~any(isnan([tgrid(:) pgrid(:) theta(:)]),2));

tgrid = tgrid(idx);
pgrid = pgrid(idx);
theta = theta(idx);

% Determine extent of phase arrows in plot
[dx,dy] = determinearrowextent(axhandle);
%

% Create the arrow patch object for plotting the phase
arrowpatch = [-1 0 0 1 0 0 -1; 0.1 0.1 0.5 0 -0.5 -0.1 -0.1]';

for ii=numel(tgrid):-1:1
    % Multiply each arrow by the rotation matrix for the given theta
    rotarrow = arrowpatch*[cos(theta(ii)) sin(theta(ii));...
        -sin(theta(ii)) cos(theta(ii))];
    patch(tgrid(ii)+rotarrow(:,1)*dx,pgrid(ii)+rotarrow(:,2)*dy,[0 0 0],...
        'edgecolor','none' ,'Parent',axhandle);
end
end
%--------------------------------------------------------------------------

function [dx,dy] = determinearrowextent(axhandle)
% Get the data aspect ratio of the y and x axis
dataaspectratio = get(axhandle,'DataAspectRatio');
axesposition = get(axhandle,'position');
widthheight = axesposition(3:4);
ar = widthheight./dataaspectratio(1:2);

ar(2)=ar(1)/ar(2);
ar(1)=1;

xlim = axhandle.XLim;
dxlim = xlim(2)-xlim(1);

dx=ar(1).*0.02*dxlim;
dy=ar(2).*0.02*dxlim;
end

function ResizeFig(source,evd,theta,tax,pax,tspace,pspace)
if strcmpi(class(evd),'event.PropertyEvent')
    AX = evd.AffectedObject;
elseif strcmpi(class(source),'matlab.ui.Figure')
    AX = gca;
end

plotPhaseVectors(AX,theta,tax,pax,tspace,pspace);
end

function zoomArrows(evd,theta,tax,pax,tspace,pspace)
% resizes arrows in event of zoom

AX = evd.Axes;
plotPhaseVectors(AX,theta,tax,pax,tspace,pspace);
end
%--------------------------------------------------------------------------

function indices = createCoiIndices(N)
if isodd(N)  % is odd
    indices = 1:ceil(N/2);
    indices = [indices, fliplr(indices(1:end-1))];
else % is even
    indices = 1:N/2;
    indices = [indices, fliplr(indices)];
end
end
