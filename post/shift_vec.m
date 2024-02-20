
clear all
% close all
clc

shift = 2.1;
numsamp = 15;
time = 0:numsamp-1;
y = linear_filter_1d(0.5, 0.51, 1, 1, 0, numsamp, 0);
% y = sin(linspace(0,2*pi, numsamp));
 
% fd = 0.9;
% len = 128;
% [filt,i0,bw] = designFracDelayFIR(fd,len);
% % filt = filt / norm(vec(filt(:)),1);
% fdf = dsp.FIRFilter(filt);
% 
% 
% new = filter(filt,1,y); online example says to use following, but stackexchange says use left bc thats a bug  new = fdf(y)

new = fraccircshift(y,shift);

figure
% new = interp1(time+shift, y, time);
% new = interp1(time+shift,new,[0,1],'linear','extrap');
plot(time, y); hold on; plot(time, new)


figure; 

