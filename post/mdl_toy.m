close all

numpvarbin = 20;
numwtbin = 1;

randinds1 = randperm(numel(ft));
randinds2 = randperm(numel(ft));

tinds = 1:300;
filename_save = '~/stacks/20230627-2_D05_syt7f_018_syt7f/hot_syn_test_.gif';

pvar_syn_all = linspace(0.5, 1, numpvarbin);
wt_all = linspace(0, 0.7, numwtbin);
[pp,qq] = meshgrid(pvar_syn_all, wt_all);
tmp = [pp(:) qq(:)];

numrows = 4;
numcolumns = 1;
margins_fig = 0.05;
margins_subfig = 0.05;
[axx, axy, axw, axh] = arrange_subplots(numrows,numcolumns,margins_fig,margins_subfig);
ylm = [min(depv(:)) max(depv(:))];
ylm = [min(depv(:))-range(ylm)*0.1 max(depv(:))+range(ylm)*0.1 ];
hfg = figure;
for si = 1:numrows
    hax{si} = axes('Parent', hfg, 'Position', [axx(si), axy(si), axw(si), axh(si)]); hold(hax{si}, 'on'); hp1{si} = plot(hax{si},1,'k'); hp2{si} = plot(hax{si},1,'r'); hp3{si} = plot(hax{si},1,'b'); %hax{si}.YLim = ylm;
end

for ii = 1:size(tmp, 1)

    pvar_syn = tmp(ii,1);
    wt_syn = tmp(ii,2);

    gtr_syn_1 = ft(randinds1);
    gtr_syn_2 = ft(randinds2);
    depv_syn_1 = indv*gtr_syn_1; %synthetic response
    depv_syn_2 = indv*gtr_syn_2; %synthetic response
    % gtr_syn = wt_syn*gtr_syn_1 + (1-wt_syn)*gtr_syn_2; %ground truth model is weighted sum of two
    depv_syn = wt_syn*depv_syn_1 + (1-wt_syn)*depv_syn_2; %ground truth model is weighted sum of two

    ft_syn = mdlfcn( indv, depv_syn, pvar_syn); %fit synthetic response
    ft_syn2 = transpose(depv_syn'*indv / size(depv_syn, 1)); %alternate objective function (average correlation)
    depvp_syn = indv*ft_syn; %synthetic response model prediction
    depvp_syn2 = indv*ft_syn2; %synthetic response model prediction
    gof1 = mse(gtr_syn_1, ft_syn);
    gof2 = mse(gtr_syn_1, ft_syn2);
    gof3 = mse(depv_syn, depvp_syn);
    gof4 = mse(depv_syn, depvp_syn2);

    si = 1; hp1{si}.YData = depv_syn; hp2{si}.YData = depvp_syn; hp3{si}.YData = depvp_syn2; hax{si}.Title.String = {['pvar: ' num2str(pvar_syn) ', wt: ' num2str(wt_syn)]; ['gof1: ' num2str(gof1) ', gof2: ' num2str(gof2) ', gof3: ' num2str(gof3) ', gof4: ' num2str(gof4)]; "synthesized resp vs fit resp, all samples"};
    si = 2; hp1{si}.YData = depv_syn(tinds); hp2{si}.YData = depvp_syn(tinds); hp3{si}.YData = depvp_syn2(tinds); hax{si}.Title.String = "synthesized resp vs fit resp, subset of samples";
    si = 3; hp1{si}.YData = gtr_syn_1; hp2{si}.YData = ft_syn; hp3{si}.YData = ft_syn2; hax{si}.Title.String = "ground truth vs fits";
    si = 4; hp1{si}.YData = []; hp2{si}.YData = gtr_syn_1; hp3{si}.YData = gtr_syn_2; hax{si}.Title.String = "ground truth model and contaminating model";

    fig2gif(hfg, ii, filename_save)

end

[~,worst_pars] = sort(abs(gtr_syn_1-ft_syn), 'descend');
zerovar_indv = find(sum(indv)==0);
badcomp = [zerovar_indv' worst_pars(1:length(zerovar_indv))];