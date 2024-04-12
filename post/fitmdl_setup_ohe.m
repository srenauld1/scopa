function ann = fitmdl_setup_ohe(ann, annspec, ni, num_dim_indvpre, num_samp_mdl, num_neuron)

hotpower = 1;
if any(contains(annspec.independently_discretized_hot_dims{ni}, 'c')) %input channel or previous layer output channels
    hotpower = num_dim_indvpre;
end
if any(contains(annspec.independently_discretized_hot_dims{ni}, 't')) %time (model samples into the past)
    hotpower = hotpower*num_samp_mdl;
end
if any(contains(annspec.independently_discretized_hot_dims{ni}, 'n')) %artificial neuron output channels for current position (layer & channel), ie each linear function or activation function or linear-activation sequence in the current channel
    hotpower = hotpower*num_neuron; %is this right?
end
maxhotcombos = annspec.numbinhot{ni}^hotpower;
if maxhotcombos>1000
    error("more than 1000 combinations for hot encoding; you may have made a mistake")
end
levs_each_hot = repmat({[1:annspec.numbinhot{ni}]}, [hotpower 1]);
hotcombos = cell2mat(table2cell(combinations(levs_each_hot{:})));
if strcmp(annspec.independently_discretized_hot_dims{ni}, 'x') %artificial neuron output channels for current position (layer & channel), ie each linear function or activation function or linear-activation sequence in the current channel
    hotcombos = repmat(hotcombos, [1 num_dim_indvpre]);
end


ann.actfun{ni} = @ohe_nonlinearity;


%% nested nonlinearity functions


    function [depvp, binmns] = ohe_nonlinearity(doplots, outflag, pthspre, indv, numbinhot, independently_discretized_hot_dims, ft)


        if doplots
            hfg = figure; hax = axes('Parent', hfg); hp1 = plot(hax,1); yyaxis right; hp2 = plot(hax,1);
        end


        % indvin_hot(:) = 0;
        if strcmp(independently_discretized_hot_dims, 'x')
            [indvin_hot, binmns] = probability_bin(indv, numbinhot, outflag);
            % hotcombos = repmat(hotcombos, [1 size(indv, 2)]);
        else
            indvin_hot = zeros(size(indv));
            for i = 1:size(indv, 2) 
                indvin_hot(:,i) = quantileranks(indv(:,i), numbinhot);
                if doplots
                    hp1.YData = indv(1:100,i); yyaxis right; hp2.YData = indvin_hot(1:100,i);
                    filename_save_hot = [pthspre '_dischot_.gif'];
                    fig2gif(hfg, i, filename_save_hot)
                end
            end
        end



        [~, levs_full_hot] = ismember(indvin_hot, hotcombos, 'rows');

        indshot = [1:maxhotcombos]; %this does all possible, which may not exist or potentially smaller, unique(indvin_hot(:));
        indv = levs_full_hot==indshot;

        indv = double(indv);

        if doplots
            filename_save_hot_levels = [pthspre '_hotlevels_.png'];
            figure; imagesc(hotcombos)
            saveas(gcf, filename_save_hot_levels)
        end


        depvp = indv*ft'; %x0 = zeros(81,1);

    end


end
