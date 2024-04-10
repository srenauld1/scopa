function [indvaug, num_dim_indvaug, num_samp_model, levs_full_hot] = ...
    one_hot_encode_input(modeltype, indvaug, num_dim_indv_pre, num_samp_model, pth_fitdata_prefix, doplots)

numbinhot = sscanf(modeltype, 'ohe%d');
collapse_input_by_ineractions = 1; %default for now

if doplots
    hfg = figure; hax = axes('Parent', hfg); hp1 = plot(hax,1); yyaxis right; hp2 = plot(hax,1);
end

maxhotcombos = numbinhot^(num_dim_indv_pre*num_samp_model); %this does all possible, which may not exist or potentially smaller, unique(indvin_hot(:));

indvin_hot = zeros(size(indvaug));
for ivai = 1:size(indvaug, 1)
    indvin_hot(ivai,:) = quantileranks(indvaug(ivai,:), numbinhot);
    if doplots
        hp1.YData = indvaug(ivai,1:100); yyaxis right; hp2.YData = indvin_hot(ivai,1:100);
        filename_save_hot = [pth_fitdata_prefix '_dischot_.gif'];
        fig2gif(hfg, ivai, filename_save_hot)
    end
end

levs_each_hot = repmat({[1:numbinhot]}, [num_dim_indv_pre*num_samp_model 1]);
hotcombos = cell2mat(table2cell(combinations(levs_each_hot{:})));
[~, levs_full_hot] = ismember(indvin_hot.',hotcombos,'rows');

if collapse_input_by_ineractions
    indshot = [1:maxhotcombos];
    indvaug = levs_full_hot.'==indshot.';
else
    indshot = reshape([1:maxhotcombos], [1 1 maxhotcombos]);
    indvaug = levs_full_hot==indshot;
    indvaug = reshape(permute(indvaug, [1 3 2]), [], num_samp_indvaug_full); %index of each entry is num_dim_indv_pre*num_samp_model*(indvaug_bin_value-1)+indvaug_dim_ind
    % indvaug = reshape(permute(indvaug, [3 1 2]), [], num_samp_indvaug_full); %alternative organization to above, index of each entry is num_dim_indv_pre*num_samp_model*nhotbin*(indvaug_dim_ind-1)+indvaug_bin_value
end

indvaug = double(indvaug);
num_dim_indvaug = size(indvaug, 1);
% num_samp_model = 1;

if doplots
    filename_save_hot_levels = [pth_fitdata_prefix '_hotlevels_.png'];
    figure; imagesc(hotcombos)
    saveas(gcf, filename_save_hot_levels)
end
