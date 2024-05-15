

clear all 
close all
clc

load('~/samptestdat.mat', 'B');

Ad1 = downsample(B, 10);

Alim = numel(B) ./ [80  20]; %[2.2e5 2.6e5] in B . . . restrict x axis to small region (which includes abrupt transition)

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

N = numel(B)
X = fftshift(fft(Ad1));
%%Frequency specifications:

%%Plot the spectrum:
figure;
plot(abs(X)/N);
xlabel('Frequency (in hertz)');
title('Magnitude Response');