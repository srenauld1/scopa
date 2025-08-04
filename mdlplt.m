function mdlplt(mdl, supp, depv, pred, ft, indv, nrmd, mse_train, tinds, indvdims)

arguments
    mdl
    supp
    depv
    pred
    ft
    indv
    nrmd = []
    mse_train = []
    tinds = []
    indvdims = [1 2]
end

fontsize = 10;
zerolim = 1;

if isempty(tinds)
    tinds = 1:floor(size(depv, 1)/4);
    if numel(tinds)>1000
        tinds = tinds(1:1000);
    end
    tinds = 1000:2000;
    tinds = 1:size(depv, 1);
end

if size(indv, 2)==1
    indvdims = indvdims(1);
end

if ~isempty(mse_train) && isscalar(mse_train)
    msestr = ['mse: ' num2str(mse_train)];
else
    msestr = '';
end

% if ~strcmp(nrmd, 'none')
%     indv = rescale(indv, -1, 1);
% end

[indvsort, sortinds] = sort(indv(:,indvdims(1)));


dttm = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
pthgif = [supp.pthspre '_' dttm '_testpred.gif'];
pthgif = pathauto(suffix='.gif', usetime=1);

nrows = supp.num_total_model_functions + 3;
ncols = 1;
layout = [nrows, ncols];
marginax = 0.05;
marginfg = 0.05;
ax = axarr(layout, marginax=marginax, marginfg=marginfg);

widfac = 1;
htfac = 1;
h = initfig(szf=2);
hfg = h.hfg;

sgtitle({ ...
    '1: measured (black), predicted (red), independent variable(s) (blue & green), train set'; ...
    '2: same, but validation set; 3: model coefficients; 4: model components'; ...
    msestr ...
    }, fontsize=fontsize)

for k = 1:numel(ax.x)
    if k==1 || k==4
        dummyvec = nan(size(depv,1),1);
    elseif k==2
        dummyvec = nan(numel(tinds),1);
    elseif k==3
        dummyvec = nan(supp.num_samp_mdl,1);
    end
    hax{k} = axes('Parent', hfg, 'Position', [ax.x(k), ax.y(k), ax.w(widfac), ax.h(htfac)]);

    if k~=4
        yyaxis left;
    end
    hp1{k} = plot(hax{k},dummyvec, 'k-'); hold(hax{k}, 'on');
    if k==3
        hp2{k} = plot(hax{k},dummyvec, 'k--');
    else
        hp2{k} = plot(hax{k},dummyvec, 'r-');
    end
    hax{k}.YAxis(1).Color = [0 0 0];

    if k~=4
        yyaxis right;
        hp3{k} = plot(hax{k},dummyvec, 'b-'); hold(hax{k}, 'on');
        hp4{k} = plot(hax{k},dummyvec, 'g-');
        hax{k}.YAxis(2).Color = [0 0 0];
    end
end


for ir = 1:size(depv,2)

    hp1{1}.XData = 1:size(depv,1);
    hp1{1}.YData = depv(:,ir);
    hp2{1}.XData = 1:size(depv,1);
    hp2{1}.YData = pred(:,ir);

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
    hp1{2}.YData = depv(tinds,ir);
    hp2{2}.XData = 1:numel(tinds);
    hp2{2}.YData = pred(tinds,ir);

    if exist('indv', 'var') && ~isempty(indv)
        if size(indv, 2)>3
            disp("plotting no more than 2 indv dims")
        end
        for ii = 1:size(indv, 2)
            if ii==indvdims(1)
                hp3{2}.XData = 1:numel(indv(tinds,ii));
                hp3{2}.YData = indv(tinds,ii);
            elseif ii==indvdims(2)
                hp4{2}.XData = 1:numel(indv(tinds,ii));
                hp4{2}.YData = indv(tinds,ii);
            end
        end
    end


    ft2 = reshape(ft(ir,:), [], supp.num_samp_mdl);
    hp1{3}.XData = 1:size(ft2,2);

    for kk = 1:size(ft2,1)
        if kk==1
            hp1{3}.YData = ft2(kk,:);
        elseif kk==2
            hp2{3}.YData = ft2(kk,:);
        end
    end
    xline(0)


    hp1{4}.XData = indvsort;
    hp1{4}.YData = depv(sortinds,ir);
    hp2{4}.XData = indvsort;
    if startsWith(supp.mdlname, 'svd')
        predtmp = indv*ft';
    else
        predtmp = mdl(ft(ir,:), indv, supp);
    end
    hp2{4}.YData = predtmp(sortinds);

    % supp.starting_hax = 3;
    % supp.framecount = ir;

    % no reason to use this right now if all we need here is the prediction
    % if strcmp(supp.mdlclass, 'svd')
    %
    % else
    %     [predtmp, hax, ~] = mdl(ft(ir,:), indv, supp, hax); %update existing axes with plots of model components
    % end
    % if ~isempty(ftsyn)
    %     [predtmp, hax, ~] = mdl(ftsyn(ir,:), indv, supp, hax);
    % end




    if zerolim
        for k = 1:numel(ax.x)
            if k~=3
                for m = 1:numel(hax{k}.YAxis)
                    limabs = max(abs(hax{k}.YAxis(m).Limits));
                    hax{k}.YAxis(m).Limits = [-limabs limabs];
                end
            end
        end
    end


    fig2gif(hfg, ir, pthgif)

    pthsv = strrep(pthgif, '.gif', '.fig');
    saveas(gcf, pthsv)


end
