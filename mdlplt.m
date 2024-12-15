function mdlplt(mdl, supp, depv, pred, ft, indv, normalize_depv, tinds)

if ~exist('tinds', 'var') || isempty(tinds)
    tinds = 1:floor(size(depv, 1)/4);
    if numel(tinds)>700
        tinds = tinds(1:700);
    end
end
% if ~strcmp(normalize_depv, 'none')
%     indv = rescale(indv, -1, 1);
% end

[indvsort, sortinds] = sort(indv);


dttm = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
pthgif = [supp.pthspre '_' dttm '_testpred.gif'];
nrows = supp.num_total_model_functions + 3;
ncols = 1;
layout = [nrows, ncols];
marginax = 0.05;
marginfg = 0.05;
ax = axarr(layout, marginax=marginax, marginfg=marginfg);

widfac = 1;
htfac = 1;
hfg = figure;
sgtitle({'1: measured (black), predicted (red), ind. var. (blue if shown), all samples'; ['2: same, but first ' num2str(numel(tinds)) ' samples']; '3: model params'; '4+: model comps'})
for k = 1:numel(ax.x)
    if k==1 || k==4
        dummyvec = nan(size(depv,1),1);
    elseif k==2
        dummyvec = nan(numel(tinds),1);
    elseif k==3
        dummyvec = nan(size(ft,2),1);
    end
    hax{k} = axes('Parent', hfg, 'Position', [ax.x(k), ax.y(k), ax.w(widfac), ax.h(htfac)]);

    if k~=4
        yyaxis left;
    end
    hp1{k} = plot(hax{k},dummyvec, 'k-'); hold(hax{k}, 'on');
    hp2{k} = plot(hax{k},dummyvec, 'r-');
    hax{k}.YAxis(1).Color = [0 0 0];

    if k~=4
        yyaxis right;
        hp3{k} = plot(hax{k},dummyvec, 'b-'); hold(hax{k}, 'on');
        hp4{k} = plot(hax{k},dummyvec, 'c-');
        hax{k}.YAxis(2).Color = [0 0 0];
    end
end


for ri = 1:size(depv,2)

    hp1{1}.XData = 1:size(depv,1);
    hp1{1}.YData = depv(:,ri);
    hp2{1}.XData = 1:size(depv,1);
    hp2{1}.YData = pred(:,ri);

    % commenting out indv because it's too busy for ther first plot
    % if exist('indv', 'var') && ~isempty(indv)
    %     if size(indv, 2)>3
    %         disp("plotting no more than 2 indv dims")
    %     end
    %     for ii = 1:size(indv, 2)
    %         if ii==1
    %             hp3{1}.XData = 1:numel(indv(tinds,ii));
    %             hp3{1}.YData = indv(tinds,ii);
    %         elseif ii==2
    %             hp4{1}.XData = 1:numel(indv(tinds,ii));
    %             hp4{1}.YData = indv(tinds,ii);
    %         end
    %     end
    % end


    hp1{2}.XData = 1:numel(tinds);
    hp1{2}.YData = depv(tinds,ri);
    hp2{2}.XData = 1:numel(tinds);
    hp2{2}.YData = pred(tinds,ri);

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


    hp1{3}.XData = 1:numel(ft(ri,:));
    hp1{3}.YData = ft(ri,:);


    hp1{4}.XData = indvsort;
    hp1{4}.YData = depv(sortinds,ri);
    hp2{4}.XData = indvsort;
    predtmp = mdl(ft(ri,:), indv, supp);
    hp2{4}.YData = predtmp(sortinds);

    % supp.starting_hax = 3;
    % supp.framecount = ri;

    % no reason to use this right now if all we need here is the prediction
    % if strcmp(supp.mdlclass, 'svd')
    %
    % else
    %     [predtmp, hax, ~] = mdl(ft(ri,:), indv, supp, hax); %update existing axes with plots of model components
    % end
    % if ~isempty(ftsyn)
    %     [predtmp, hax, ~] = mdl(ftsyn(ri,:), indv, supp, hax);
    % end

    fig2gif(hfg, ri, pthgif)

end
