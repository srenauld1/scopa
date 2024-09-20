function fitmdl_plot_single_mdl(ri, mdl, supp, depv, depvp, ft, indv, ftsyn, normalize_depv, tinds)

if exist('ftsyn', 'var') && ~isempty(ftsyn)
    ftsyn = ftsyn(ri,:);
else
    ftsyn = [];
end
if ~exist('tinds', 'var') || isempty(tinds)
    tinds = 1:floor(size(depv, 1)/4);
end
% if ~strcmp(normalize_depv, 'none')
%     indv = rescale(indv, -1, 1);
% end

pthspre = supp.pthspre;


filename_save = [pthspre '_' num2str(ri) '_' datestr(now, 30) '_testpred.gif'];
nrows = supp.num_total_model_functions + 3; 
ncols = 1;
margins_subplot = 0.05;
margins_fig = 0.05;
ax = arrange_subplots([nrows, ncols], margins_subplot, margins_fig);

widfac = 1;
htfac = 1;
hfg = figure; sgtitle({'1st fig: predicted (red) and measured (black) and ind var (blue if shown), all samples'; ['2nd fig: same, but first ' num2str(numel(tinds)) ' samples']; '3rd fig: model params'; 'below 3rd fig: model comps'})
for k = 1:numel(ax.rowmajor.xp)
    if k==1 || k==4
        dummyvec = nan(numel(depv),1);
    elseif k==2
        dummyvec = nan(numel(tinds),1);
    elseif k==3
        dummyvec = nan(numel(ft),1);
    end
    hax{k} = axes('Parent', hfg, 'Position', [ax.rowmajor.xp(k), ax.rowmajor.yp(k), ax.xe(widfac), ax.ye(htfac)]); 
    yyaxis left; 
    hp1{k} = plot(hax{k},dummyvec, 'k-'); hold(hax{k}, 'on'); hp2{k} = plot(hax{k},dummyvec, 'r-'); 
    hax{k}.YAxis(1).Color = [0 0 0];
    yyaxis right; 
    hp3{k} = plot(hax{k},dummyvec, 'b-'); hold(hax{k}, 'on'); hp4{k} = plot(hax{k},dummyvec, 'c-');
    hax{k}.YAxis(2).Color = [0 0 0];
end


hp1{1}.XData = 1:numel(depv);
hp1{1}.YData = depv;
hp2{1}.XData = 1:numel(depv);
hp2{1}.YData = depvp;

% if exist('indv', 'var') && ~isempty(indv)
%     if size(indv, 2)>3
%         disp("plotting no more than 2 indv dims")
%     end
%     for ii = 1:size(indv, 2)
%         if ii==1
%             hp3{1}.XData = 1:numel(indv(:,ii));
%             hp3{1}.YData = indv(:,ii);
%         elseif ii==2
%             hp4{1}.XData = 1:numel(indv(:,ii));
%             hp4{1}.YData = indv(:,ii);
%         end
%     end
% end

hp1{2}.XData = 1:numel(tinds);
hp1{2}.YData = depv(tinds);
hp2{2}.XData = 1:numel(tinds);
hp2{2}.YData = depvp(tinds);

if exist('indv', 'var') && ~isempty(indv)
    if size(indv, 2)>3
        disp("plotting no more than 2 indv dims")
    end
    for ii = 1:size(indv, 2)
        if ii==1
            hp3{2}.XData = 1:numel(indv(tinds,ii));
            hp3{2}.YData = indv(tinds,ii);
        elseif ii==2
            hp4{2}.XData = 1:numel(indv(tinds,ii));
            hp4{2}.YData = indv(tinds,ii);
        end
    end
end


hp1{3}.XData = 1:numel(ft);
hp1{3}.YData = ft;
hp2{3}.XData = 1:numel(ftsyn);
hp2{3}.YData = ftsyn;

supp.starting_hax = 3;
supp.framecount = 1;
if strcmp(supp.mdlclass, 'svd')

else
    [~, hax, ~] = mdl(ft, indv, supp, hax); %update existing axes with plots of model components
end
if ~isempty(ftsyn)
    [~, hax, ~] = mdl(ftsyn, indv, supp, hax);
end

fig2gif(hfg, 1, filename_save)
