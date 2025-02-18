function [pred_syn, numsyndepv, ftsyn] = mdl_synthesize_depv(pthspre, supp, mdl, depv, indv, doplt, numsyndepv, opp, plot_syn_against_single_depv, nrmd, tinds)


%if plot_syn_against_single_depv==1 (default), arbitrarily plots synthetic depv against first roi of measured depv
%if plot_syn_against_single_depv==0, arbitrarily plots synthetic data against first numsyndepv rois of measured depv, if numsyndepv>num depv rois, the final depv roi is repeated

if ~exist('plot_syn_against_single_depv', 'var') || isempty(plot_syn_against_single_depv)
    plot_syn_against_single_depv = 1;
end
if ~exist('nrmd', 'var') || isempty(nrmd)
    nrmd = [];
end
if ~exist('tinds', 'var') || isempty(tinds)
    tinds = 1:floor(size(depv, 1)/8);
    if numel(tinds)>700
        tinds = tinds(1:700);
    end
end


fprintf("creating " + num2str(numsyndepv) + " synthetic depv" + newline)

if doplt
    if plot_syn_against_single_depv
        depv = repmat(depv(:,1), [1 numsyndepv]);
    else
        if numsyndepv>size(depv, 2) %this is just for plotting: if making more synthetic depv than there are real depv, repeat the final one for plotting against synthetic
            depv = cat(2, depv, repmat(depv(:,end), [1 numsyndepv-size(depv, 2)]));
        else %otherwise just take the first numsyndepv for plotting against syndepv
            depv = depv(:,1:numsyndepv);
        end
    end
end


ftsyn = [];
pred_syn = zeros(size(depv, 1), numsyndepv, 'single');
for i = 1:numsyndepv
    ftsyn(i,:) = mdl_synpars(opp.x0, opp.lb, opp.ub); %make synthetic model params, within bounds
    pred_syn(:,i) = mdl(ftsyn(i,:), indv, supp); %replace depv with synthetic depv
end

if doplt
    mdlplt(mdl, supp, depv, pred_syn, ftsyn, indv, nrmd, tinds)
end


end


