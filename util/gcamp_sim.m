
%% set up some basics

close all
clear all
clc


allplots = 1;

T = 0.001; % time step in ms
Fs = 1/ T; % sample rate, 1 kHz

%% define the GCaMP6F filter based on measurements from Schnell et al. 2014 PNAS

xdata = [0 : T : 0.2];

%A = [1 0 0.4 1 0 0.05 0]; % tau_on is 50 ms, tau_off is 490 ms

a1_1 = 1; % "amplitude"
t1_1 = 0; % when x = t, y = a1 + b
tau1_1 = 0.01; % "time constant" - when x increases by tau1, y decreases by factor a1 * e
b_1 = 0; % as x --> inf, y --> b

a1_2 = 1; % "amplitude"
t1_2 = 0; % when x = t, y = a1 + b
tau1_2 = .07; % "time constant" - when x increases by tau1, y decreases by factor a1 * e
b_2 = 0; % as x --> inf, y --> b

cnst = 0;

%ydata = Exponential2_1D( A , xdata );

y_1 = a1_1 * exp(-1 / tau1_1 * (xdata - t1_1)) + b_1;
y_2 = a1_2 * exp(-1 / tau1_2 * (xdata - t1_2)) + b_2;


ydata = y_1 - y_2 + cnst;

ydata = ydata / sum( ydata );
nSamples = numel( xdata );

if allplots
    figure; plot(xdata, ydata);
end

xdatashort = linspace(xdata(1), xdata(end), 30);
ydatashort = interp1(xdata, ydata, xdatashort);
figure; 
plot(ydatashort);


%% compute the transfer function

Ydata = fft( ydata );

Ayy = 2 * abs(Ydata) / nSamples;
freq = [0 : floor( numel( xdata ) / 2 )] * Fs / numel( xdata );

if allplots
    figure;
    
    plot( freq, Ayy(1 : size(freq, 2) ) );
    xlim([0 20]);
    
    xlabel( 'frequency (Hz)' );
    ylabel ( 'power' );
end

%% flip the impulse response function to make a filter

filter = ydata;

%% convolve the filter with some synthetic responses

% freqi = 1;
% input = [zeros( size( xdata ) ) 0.5 * sin( 2 * pi * freqi * xdata ) + 0.25 zeros( size( xdata ) )];
% input = sinSFi(1./[.1 0.02],15003,'period',5);
load('~/samptestdat.mat', 'B');
B = tsrs(B(1:1000), 20000);
% input(input<0) = 0;
if allplots
    figure; plot(B)
end
%% 

Ad1 = conv( B, filter );
Ad1 = downsample(Ad1, 20);

Alim = numel(B) .* [.2 .4]; %[2.2e5 2.6e5] in B . . . restrict x axis to small region (which includes abrupt transition)

hfg = figure;
ax1 = axes(hfg);
plot(ax1,1:numel(B),B,'-k')
ax1.XColor = 'k';
ax1.YColor = 'k';
ax1.XLim = Alim;
ax1.Box = 'off';

ax2 = axes(hfg);
plot(ax2,1:numel(Ad1),Ad1,'-r')
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax2.XColor = 'r';
ax2.YColor = 'r';
ax2.Box = 'off';
ax2.XLim = Alim / (numel(B) / numel(Ad1));
ax2.YLim = ax1.YLim;
%% 

N = numel(B)
X = fftshift(fft(Ad1));
%%Frequency specifications:

%%Plot the spectrum:
figure;
plot(abs(X)/N);
xlabel('Frequency (in hertz)');
title('Magnitude Response');

%% 


filter = ones(200,1);
filter(1:10) = 1;


output = conv( input, filter );
timePoints = [1 : numel( output )] * T;

figure;
hold on;
plot( timePoints(1 : numel(input)), input, 'r' );
plot( timePoints, output, 'b' );

xlim([0 15])
% ylim([-0.5 0.5])