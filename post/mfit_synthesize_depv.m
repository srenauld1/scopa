function [depv_syn, numsyndepv, ftsyn] = mfit_synthesize_depv(pthspre, supp, mdl, depv, indv, doplt, numsyndepv, optimp, plot_syn_against_single_depv, tinds)

%if plot_syn_against_single_depv==1 (default), arbitrarily plots synthetic depv against first roi of measured depv
%if plot_syn_against_single_depv==0, arbitrarily plots synthetic data against first numsyndepv rois of measured depv, if numsyndepv>num depv rois, the final depv roi is repeated 

if ~exist('plot_syn_against_single_depv', 'var') || isempty(plot_syn_against_single_depv)
    plot_syn_against_single_depv = 1;
end
if ~exist('tinds', 'var') || isempty(tinds)
    tinds = 1:floor(size(depv, 1)/8);
end


sprintf("creating " + num2str(numsyndepv) + " synthetic depv")

if doplt
    if plot_syn_against_single_depv
        depv = depv(:,1);
    else
        if numsyndepv>size(depv, 2) %this is just for plotting: if making more synthetic depv than there are real depv, repeat the final one for plotting against synthetic
            depv = cat(2, depv, repmat(depv(:,end), [1 numsyndepv-size(depv, 2)]));
        else %otherwise just take the first numsyndepv for plotting against syndepv
            depv = depv(:,1:numsyndepv);
        end
    end
end



if doplt

    sprintf("plotting default number of samples, synthetic vs measured")

    filename_save = [pthspre '_syntest_.gif'];
    nrows = 2; ncols = 1;
    [axx, axy, axw, axh] = arrange_subplots(nrows, ncols);
    hfg = figure; sgtitle(['synthetic vs measured depv; top: all samples; bottom: first ' num2str(numel(tinds)) ' samples'])
    for i = 1:numel(axx)
        hax{i} = axes('Parent', hfg, 'Position', [axx(i), axy(i), axw(i), axh(i)]); hp1{i} = plot(hax{i},1); hold(hax{i}, 'on'); hp2{i} = plot(hax{i},1);
    end


end

depv_syn = zeros(size(depv, 1), numsyndepv, 'single');
for i = 1:numsyndepv

    ftsyn(i,:) = synthesize_params_random(optimp.x0, optimp.lb, optimp.ub); %make synthetic model params, within bounds
    depv_syn(:,i) = mdl(ftsyn(i,:), indv, supp); %replace depv with synthetic depv
    if doplt
        if i==1
            hp1{1}.YData = depv(:,i); hp1{2}.YData = depv(tinds,i);
        end
        hp2{1}.YData = depv_syn(:,i); hp2{2}.YData = depv_syn(tinds,i);
        fig2gif(hfg, i, filename_save)
    end
end


end

function ftsyn = synthesize_params_random(x0, lb, ub)
dummybnd = 10;
ub(isinf(ub)&ub>0) = dummybnd; %replace inf with a (relatively) big number
ub(isinf(ub)&ub<0) = -dummybnd; %replace -inf with a (relatively) small number
lb(isinf(lb)&lb>0) = dummybnd; %replace inf with a (relatively) big number
lb(isinf(lb)&lb<0) = -dummybnd; %replace -inf with a (relatively) small number
ftsyn = lb + (ub-lb).*rand(size(x0)); %synthetic params (random, within bounds), to generate synthetic depv in case testing optimization code
end

