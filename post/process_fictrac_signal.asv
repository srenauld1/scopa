function [posint_out, vel] = process_fictrac_signal(method_downsample, iscircular, posint_in, rateim, ratedaq, ratefictrac, maxvolt, smoothwindow, slopelen, slopeorder, maxFlyVelocity)

posint_out = posint_in/maxvolt*2*pi - pi; %put in range -pi to pi, G4 frame 0 assigned to -pi


%% 


q = 1000;
p = 1;

limx1 = [1.2e5 2.3e5];
y1 = posint_out(1:12600000);
x1 = 1:numel(y1);
y2 = resample(y1, p, q);
% y2 = resample(y2, p, q);
% y2 = resample(y2, p, q);

% obsv = [1:12600000]';
% % y2 = resample(y1,obsv,.001, 2, 3);
% % y2 = resample(y1,obsv,.001, 2, 3, 'spline');
% n = 10*q+1;
% cutoffRatio = .85;% use .25 of Nyquist range of desired sample rate
% lpFilt = p * fir1(n, cutoffRatio * 1/q);% construct lowpass filter 
% y2 = resample(y1, obsv, 1/q, p, q, lpFilt);

x2 = 1:numel(y2);

hfg = figure;
ax1 = axes(hfg);
plot(ax1,x1,y1,'-k')
ax1.XColor = 'k';
ax1.YColor = 'k';
ax1.XLim = limx1;
ax1.Box = 'off';

ax2 = axes(hfg);
plot(ax2,x2,y2,'-r')
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax2.XColor = 'r';
ax2.YColor = 'r';
ax2.Box = 'off';
ax2.XLim = ax1.XLim / (numel(y1) / numel(y2));
ax2.YLim = ax1.YLim;

%% 

if strcmp(method_downsample, 'timestamps')

elseif strcmp(method_downsample, 'resample')
    if iscircular
        posint_out = smooth_circular_variable(posint_out, smoothwindow);
        vel = differentiate_circular_variable(posint_out, md.dtmnb, slopelen, slopeorder);
    else
        posint_out = smoothdata(posint_out, 'gaussian', smoothwindow, 'omitnan');
        vel = movingslope(posint_out, slopelen, slopeorder, dt);
    end
    posint_out = downsample_variable(md, posint_out, iscircular); %downsample into imaging rate
    vel = downsample_variable(md, vel, iscircular); %downsample into imaging rate
end
