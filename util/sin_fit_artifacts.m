
%%

clear all
close all
clc

load(['~/indv.mat'], 'indv') %
load(['~/depv_z.mat'], 'depv'); depvz = depv;
load(['~/depv_f.mat'], 'depv'); depvf = depv;
keepinds = ~isnan(indv);
indv = indv(keepinds);
depvz = depvz(:,keepinds);
depvf = depvf(:,keepinds);
numtinds = 100;
tinds = round(linspace(1, size(depvz, 2), numtinds));
tinds = 1:100;
tinds = 1 : 20 : size(depvz, 2);
midx = median([1:size(depvz, 1)]);
midx2 = midx+1;
allz = max(depvz);
allf = mean(depvf);
% allz = max(depvz);
[~, tinds] = sort(allz);
figure; plot(allz(tinds)); yyaxis right; plot(allf(tinds));
tinds_tinds = 1 : 50 : numel(tinds);
tinds = tinds(tinds_tinds);

filename_save = '~/tessscale_contiguous.gif';
hfg = figure; hax = axes('Parent', hfg);
yyaxis left;
hpl1 = plot(hax, 1:size(depvz, 1), depvz(:,tinds(1)));
yyaxis right;
hpl2 = plot(hax, 1:size(depvz, 1), depvf(:,tinds(1)));
hold(hax, 'on')
yyaxis left;
hpl3 = scatter(hax, midx, allz(1), 50, 'b', 'filled');
yyaxis right;
hpl4 = scatter(hax, midx2, allf(1), 50, 'r', 'filled');
hax.YAxis(1).Limits = [min(depvz(:)) max(depvz(:))];
hax.YAxis(2).Limits = [min(depvf(:)) max(depvf(:))];

for i = 1:numel(tinds)
    hpl1.XData = 1:size(depvz, 1);
    hpl1.YData = depvz(:,tinds(i));
    hpl2.XData = 1:size(depvf, 1);
    hpl2.YData = depvf(:,tinds(i));
    hpl3.XData = midx;
    hpl3.YData = allz(tinds(i));
    hpl4.XData = midx2;
    hpl4.YData = allf(tinds(i));

    fig2gif(hfg, i, filename_save)
end

%%

[indvsort, sortinds] = sort(indv);

numtest = 4;
partest = linspace(1, 16, numtest);

partest2 = linspace(0, 2*pi, numtest);


partest = [partest; partest2];
partest = partest(:,1:end-1);

% phaseshift = phaseshift([1 3 5 6]);
for i = 1:size(partest, 2)
    [bls(:,i), predvonsort(:,i), predsinsort(:,i)] = testthat(indv, indvsort, sortinds, partest(:,i));
end

figure;
subplot(2,1,1)
plot(indvsort, predvonsort);
subplot(2,1,2)
plot(indvsort, predsinsort);
% plot(indvsort, predsinsort);



function [bls, predvonsort, predsinsort] = testthat(indv, indvsort, sortinds, par)



% ftvon = [1 par(1) 0 0]; %width
ftvon = [1 par(1) par(2) 0]; %phase
mdlvon = @(pars,in) pars(1)*exp(pars(2)*cos(in-pars(3)))+pars(4);
predvon = mdlvon(ftvon, indv);
predvon = zscore(predvon);


yu = max(predvon);
yl = min(predvon);
yr = (yu-yl);                               % Range of ‘y’
yz = predvon-yu+(yr/2);
zx = indv(yz .* circshift(yz,[0 1]) <= 0);     % Find zero-crossings
per = pi;%;2*mean(diff(zx));                     % Estimate period
ym = mean(predvon);

mdlsin = @(b,indv)  b(1).*(sin(2*pi*indv./b(2) + 2*pi/b(3))) + b(4);    % Function to fit
losssin = @(b) sum((mdlsin(b,indv) - predvon).^2);
x0 = [yr;  per;  -1;  ym];
lbnd = [-inf,2*pi,-inf,-inf];
ubnd = [inf,2*pi,inf,inf];% Least-Squares cost function
ftsin = fmincon(losssin, x0, [], [], [], [], lbnd, ubnd, [], []); %example single run of local solver
% ftsin2 = fminsearch(losssin, x0);                       % Minimise Least-Squares
predsin = mdlsin(ftsin, indv);
predvonsort = predvon(sortinds);
predsinsort = predsin(sortinds);
% figure; hold on;
% plot(indvsort, predvon(sortinds));
% plot(indvsort, predsin(sortinds));

bls = [ftvon(4); ftsin(1); ftsin(4)];

end

