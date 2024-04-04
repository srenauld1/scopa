function [depv, numsyndepv, ftsyn] = synthesize_depv(fitin, depv_orig, indvauge, doplots, numsyndepv, tinds)

%just outputs the last ftsyn, that's fine

sprintf("creating " + num2str(numsyndepv) + " synthetic depv")

if ~exist('numsyndepv', 'var') || isempty(numsyndepv)
    numsyndepv = 20;
end

if ~exist('tinds', 'var') || isempty(tinds)
    tinds = 1:floor(size(depv_orig, 1)/8);
end

depv_orig = depv_orig(:,1); %arbitrarily plot synthetic data against one roi of measured data 

if doplots
    filename_save = [fitin.supp.pthspre '_syntest_.gif'];
    [axx, axy, axw, axh] = arrange_subplots(2, 1, 0.05, 0.05);
    hfg = figure;
    for i = 1:numel(axx)
        hax{i} = axes('Parent', hfg, 'Position', [axx(i), axy(i), axw(i), axh(i)]); hp1{i} = plot(hax{i},1); hold(hax{i}, 'on'); hp2{i} = plot(hax{i},1);
    end


end

for i = 1:numsyndepv
    ftsyn(i,:) = fitin.supp.synpars(); %make synthetic model params, within bounds
    depv(:,i) = fitin.objfcn(ftsyn(i,:), indvauge, fitin.supp); %replace depv with synthetic depv
    if doplots
        if i==1
            hp1{1}.YData = depv_orig; hp1{2}.YData = depv_orig(tinds);
        end
        hp2{1}.YData = depv(tinds,i); hp2{2}.YData = depv(tinds);
        fig2gif(hfg, i, filename_save)
    end
end
