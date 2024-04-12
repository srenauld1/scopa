function fitmdl_plot_single_mdl(ri, mdl, supp, indv, depv, depvp, ft, ftsyn)

if exist('ftsyn', 'var')
    ftsyn = ftsyn(ri,:);
end


pthspre = supp.pthspre;
filename_save = [pthspre '_' num2str(ri) '_' datestr(now, 30) '_testpred.gif'];

tinds = 1:300;
hfg = figure;
subplot(2,1,1);
plot(depvp(tinds));
hold on;
plot(depv(tinds));
subplot(2,1,2);
plot(ft);
hold on;
plot(ftsyn);
mdl(ft, indv, supp, filename_save)
mdl(ftsyn, indv, supp, filename_save)
fig2gif(hfg, 1, filename_save)
