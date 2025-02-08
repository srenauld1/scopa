function [indvpaug, num_dim_indv, num_samp_mdl, levs_full_hot] = ...
    mdl_ohevar(mdlname, indvpaug, num_dim_indvp, num_samp_mdl, pthpre, doplt)

numbinhot = sscanf(mdlname, 'ohe%d');
collapse_input_by_ineractions = 1; %default for now

if doplt
    hfg = figure; hax = axes('Parent', hfg); hp1 = plot(hax,1); yyaxis right; hp2 = plot(hax,1);
end

maxhotcombos = numbinhot^(num_dim_indvp*num_samp_mdl); %this does all possible, which may not exist or potentially smaller, unique(indvin_hot(:));

indvin_hot = zeros(size(indvpaug));
for ivai = 1:size(indvpaug, 1)
    indvin_hot(ivai,:) = quantileranks(indvpaug(ivai,:), numbinhot);
    if doplt
        hp1.YData = indvpaug(ivai,1:100); yyaxis right; hp2.YData = indvin_hot(ivai,1:100);
        filename_save_hot = [pthpre '_dischot_.gif'];
        fig2gif(hfg, ivai, filename_save_hot)
    end
end

levs_each_hot = repmat({[1:numbinhot]}, [num_dim_indvp*num_samp_mdl 1]);
hotcombos = cell2mat(table2cell(combinations(levs_each_hot{:})));
[~, levs_full_hot] = ismember(indvin_hot.',hotcombos,'rows');

if collapse_input_by_ineractions
    indshot = [1:maxhotcombos];
    indvpaug = levs_full_hot.'==indshot.';
else
    indshot = reshape([1:maxhotcombos], [1 1 maxhotcombos]);
    indvpaug = levs_full_hot==indshot;
    indvpaug = reshape(permute(indvpaug, [1 3 2]), [], num_samp_indvpaug); %index of each entry is num_dim_indvp*num_samp_mdl*(indvaug_bin_value-1)+indvaug_dim_ind
    % indvpaug = reshape(permute(indvpaug, [3 1 2]), [], num_samp_indvpaug); %alternative organization to above, index of each entry is num_dim_indvp*num_samp_mdl*nhotbin*(indvaug_dim_ind-1)+indvaug_bin_value
end

indvpaug = double(indvpaug);
num_dim_indv = size(indvpaug, 1);
% num_samp_mdl = 1;

if doplt
    filename_save_hot_levels = [pthpre '_hotlevels_.png'];
    figure; imagesc(hotcombos)
    saveas(gcf, filename_save_hot_levels)
end
