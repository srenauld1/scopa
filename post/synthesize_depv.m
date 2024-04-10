function [depv, numsyndepv, ftsyn] = synthesize_depv(fitin, depv_orig_subset, indv, doplots, numsyndepv, tinds, x0, ub, lb)

%just outputs
%arbitrarily plots synthetic data against first numsyndepv rois of measured data the last ftsyn, that's fine

sprintf("creating " + num2str(numsyndepv) + " synthetic depv")

if ~exist('tinds', 'var') || isempty(tinds)
    tinds = 1:floor(size(depv_orig_subset, 1)/8);
end


if doplots
    filename_save = [fitin.supp.pthspre '_syntest_.gif'];
    [axx, axy, axw, axh] = arrange_subplots(2, 1, 0.05, 0.05);
    hfg = figure;
    for i = 1:numel(axx)
        hax{i} = axes('Parent', hfg, 'Position', [axx(i), axy(i), axw(i), axh(i)]); hp1{i} = plot(hax{i},1); hold(hax{i}, 'on'); hp2{i} = plot(hax{i},1);
    end


end

depv = zeros(numsyndepv, 'single');
depv = zeros(size(depv_orig_subset, 1), numsyndepv, 'single');
for i = 1:numsyndepv

    ftsyn(i,:) = synthesize_params_random(x0, ub, lb); %make synthetic model params, within bounds
    depv(:,i) = fitin.modfun(ftsyn(i,:), indv, fitin.supp); %replace depv with synthetic depv
    if doplots
        if i==1
            hp1{1}.YData = depv_orig_subset(:,i); hp1{2}.YData = depv_orig_subset(tinds,i);
        end
        hp2{1}.YData = depv(tinds,i); hp2{2}.YData = depv(tinds);
        fig2gif(hfg, i, filename_save)
    end
end


end

function ftsyn = synthesize_params_random(x0, ub, lb)
dummybnd = 10;
ub(isinf(ub)&ub>0) = dummybnd; %replace inf with a (relatively) big number
ub(isinf(ub)&ub<0) = -dummybnd; %replace -inf with a (relatively) small number
lb(isinf(lb)&lb>0) = dummybnd; %replace inf with a (relatively) big number
lb(isinf(lb)&lb<0) = -dummybnd; %replace -inf with a (relatively) small number
ftsyn = lb + (ub-lb).*rand(size(x0)); %synthetic params (random, within bounds), to generate synthetic depv in case testing optimization code
end

