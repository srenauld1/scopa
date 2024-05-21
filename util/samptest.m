

clear all 
close all
clc

load('~/samptestdat.mat', 'A', 'B', 'C', 'inds', 'Ad1', 'Ad2', 'Ad3', 'Ad4');

%% volts to circle 

% maxvolt=10;
% A = A/maxvolt*2*pi - pi; %put in range -pi to pi, G4 frame 0 assigned to -pi

%% pretend we have native fictrac sampling

% A = resample(A, 1, 167);

%% create artificial frame inds for A 

daqrate = 10000;
% daqrate = 60;
imrate = 9.3076; %9.3076
inds = zeros(size(A));
spacing = 2*daqrate/imrate; 
errfrac = 0.002;
errframe = spacing*errfrac; 
nn = floor(numel(inds)/spacing); 
errframelow = -errframe;
errframehi = errframe;
errframerand = (errframehi-errframelow).*rand(1,nn) + errframelow;
indies = round(spacing*[1:nn] + errframerand);
indies = [indies];
inds(indies) = 1;
for i = 1:numel(indies)
    inds(indies(i):round(indies(i)+spacing/2)) = 1;
end
% inds = cumsum(inds);
% max(inds)
figure; plot(inds(end-round(numel(inds)/1000):end))


%% create artificial frame inds for B 

daqrate = 10000;
% daqrate = 60;
brate = 60; %9.3076
inds = zeros(size(A));
spacing = 2*daqrate/brate; 
errfrac = 0.002;
offset = 30; 
errframe = spacing*errfrac; 
nn = floor(numel(inds)/spacing); 
errframelow = -errframe;
errframehi = errframe;
errframerand = (errframehi-errframelow).*rand(1,nn) + errframelow;
indies = round(spacing*[1:nn] + errframerand);
indies = [indies] + offset;
inds(indies) = 1;
for i = 1:numel(indies)
    inds(indies(i):round(indies(i)+spacing/2)) = 1;
end
% inds = cumsum(inds);
% max(inds)
figure; plot(inds(end-round(numel(inds)/1000):end))

%% downsample with frame average
% 
% Au = unique(inds,'stable'); %index of each frame 
% Ad1 = arrayfun(@(i)mean(A(inds==Au(i))),1:numel(Au)); %average of A for each sample of B 
% 
% %% downsample with circular frame average
% 
% Acos = cos(A);
% Asin = sin(A);
% Au = unique(inds,'stable'); %index of each frame 
% Adx = arrayfun(@(i)mean(Acos(inds==Au(i))),1:numel(Au)); %average of A for each frame of B 
% Ady = arrayfun(@(i)mean(Asin(inds==Au(i))),1:numel(Au)); %average of A for each frame of B 
% Ad2 = atan2(Ady, Adx);

%% downsample with resample

dsfac = numel(Ad1) / numel(A);
[p, q] = rat(dsfac); %p=16, q=17191
Ad3 = resample(A, p, q);

%% 

Ad4 = resample_timeseries(A, numel(Ad1));

%% plot frame average


Alim = numel(A) ./ [57.277272727272724  48.465384615384615]; %[2.2e5 2.6e5] in A . . . restrict x axis to small region (which includes abrupt transition)
Alim = numel(A) ./ [57.277272727272724  39.465384615384615]; %[2.2e5 2.6e5] in A . . . restrict x axis to small region (which includes abrupt transition)
hfg = figure;
ax1 = axes(hfg);
plot(ax1,1:numel(A),A,'-k')
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
ax2.XLim = Alim / (numel(A) / numel(Ad1));
ax2.YLim = ax1.YLim;


%%plot resample


hfg = figure;
ax1 = axes(hfg);
plot(ax1,1:numel(A),A,'-k')
ax1.XColor = 'k';
ax1.YColor = 'k';
ax1.XLim = Alim;
ax1.Box = 'off';

ax2 = axes(hfg);
plot(ax2,1:numel(Ad2),Ad2,'-r')
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax2.XColor = 'r';
ax2.YColor = 'r';
ax2.Box = 'off';
ax2.XLim = Alim / (numel(A) / numel(Ad2));
ax2.YLim = ax1.YLim;


%%plot circular resample


hfg = figure;
ax1 = axes(hfg);
plot(ax1,1:numel(A),A,'-k')
ax1.XColor = 'k';
ax1.YColor = 'k';
ax1.XLim = Alim;
ax1.Box = 'off';

ax2 = axes(hfg);
plot(ax2,1:numel(Ad3),Ad3,'-r')
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax2.XColor = 'r';
ax2.YColor = 'r';
ax2.Box = 'off';
ax2.XLim = Alim / (numel(A) / numel(Ad3));
ax2.YLim = ax1.YLim;


%%plot circular frame av


hfg = figure;
ax1 = axes(hfg);
plot(ax1,1:numel(A),A,'-k')
ax1.XColor = 'k';
ax1.YColor = 'k';
ax1.XLim = Alim;
ax1.Box = 'off';

ax2 = axes(hfg);
plot(ax2,1:numel(Ad4),Ad4,'-r')
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax2.XColor = 'r';
ax2.YColor = 'r';
ax2.Box = 'off';
ax2.XLim = Alim / (numel(A) / numel(Ad4));
ax2.YLim = ax1.YLim;


%% frequency plots too, need to clean up the resample part (delete it basically since it's already done above)


        % testing resample in assemble_DAQ.m in flyg

        % numt = 2000;
        % dsfac = 4;
        % m0 = idpoly(1,[ ],[1 1 1 1]);
        % e = idinput(numt,'rgs');
        % sim_opt = simOptions('AddNoise',true,'NoiseData',e);
        % y1 = sim(m0,zeros(numt,0),sim_opt);

        dsfac = 10000;
        y1 = trialData.g4panels(1:12600000);
        numt = numel(y1);

        y1 = iddata(y1,[],1);
        y2 = y1;
        y3 = y1;
        y4 = y1;

        g1 = spa(y1);

        y2.y = y2.y(1:dsfac:end);
        y2.SamplingInstants = linspace(1, y1.SamplingInstants(end), numel(y2.y));
        g2 = spa(y2);

        y3.y = mean(reshape(y3.y, dsfac, []))';
        % y3.y = mean(y3.y([1:dsfac:numt ] + [0:dsfac-1]'));
        y3.SamplingInstants = linspace(1, y1.SamplingInstants(end), numel(y3.y));
        g3 = spa(y3);

        % y4.y = resample(y4.y, 1, dsfac);
        y4.y = resample_with_padding(y4.y, 1, dsfac)';
        y4.y(y4.y < minVal) = minVal;
        y4.y(y4.y > maxVal) = maxVal;
        y4.SamplingInstants = linspace(1, y1.SamplingInstants(end), numel(y4.y));
        g4 = spa(y4);


        freqs = linspace(0, g1.Frequency(end)/dsfac, 129);
        freqs = freqs(2:end);
        % 
        % freqs = linspace(0, g1.Frequency(end), 129);
        % freqs = freqs(2:end);

        figure; 
        % h = spectrumplot(g1,g2,g3,g4,g1.Frequency);
        % h = spectrumplot(g1,g2,freqs);
        h = spectrumplot(g1,g2,g3,g4,freqs);
        opt = getoptions(h);
        opt.FreqScale = 'linear';
        opt.FreqUnits = 'Hz';
        setoptions(h,opt);
        % subplot(1,3,2)
        % spectrumplot(g1,g3,g1.Frequency,opt)
        % subplot(1,3,3)
        % spectrumplot(g1,g4,g1.Frequency,opt)
        % 
        % y1.y = y1.y(1:numel(y4.y));
        % y1.SamplingInstants = 1:numel(y4.y);
        % g1p = spa(y1);
        % figure; 
        % h = spectrumplot(g1p,g2,g3,g4,g2.Frequency,opt);
        % opt = getoptions(h);
        % opt.FreqScale = 'linear';
        % opt.FreqUnits = 'Hz';
        % setoptions(h,opt);
