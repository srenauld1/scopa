
function [depvp, hax, binmns] = mdl_ann(pars, indv, supp, optin)

%could change how indv is organized before this function for speed (since
%it's organized for pure linear fits right now)

% artificial neural network: sums of outputs of LN units
% (1d linear filters with static nonlinearities)
% nonlinearity is generalized logistic function
% single layer
% each indv dim gets numLN LN units
% pass nonempty pthspre to plot/save model params


hax = [];
binmns = [];
make_figure = 0;
outflag = 0;
pthspre = supp.pthspre; %default here, can be overwritten by input 'optin'
if isfield(supp, 'framecount')
    framecount = supp.framecount;
    do_increment_framecount = 0;
else
    framecount = 0;
    do_increment_framecount = 1;
end

if exist('optin', 'var') && ~isempty(optin)

    make_figure = 1;
    outflag = 1;
    supp.extra_xlim_fac = 0.1;
    supp.fontsmall = 2;

    if ischar(optin) || isstring(optin) %create new figure with filename optin

        optin_is_figure = 0;
        supp.starting_hax = 0;
        pthspre = optin;

        pth_save = [pthspre '_MODELCOMPS.gif'];
        [~, fn_save, ~] = fileparts(pth_save);
        fn_save = strrep(fn_save, '_', ' ');

        indvmin = min(indv(:));
        indvmax = max(indv(:));
        extrax = supp.extra_xlim_fac*range(indv(:));

        supp.fontsmall = 10;
        fontmedium = 20;
        numrows_plot = supp.max_num_fun_per_neuron;
        numcolumns_plot = supp.num_neuron_total;
        margins_fig = 0.03;
        margins_subfig = 0.06;

        [axx, axy, axw, axh] = arrange_subplots(numrows_plot, numcolumns_plot, margins_fig, margins_subfig);

        hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', 'on') ;
        hfg.Position = [0 0 0.5 0.5]; %make square inner size (excludes top menu bar), plot in bottom left
        bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
        htx = text( 0.05, 0.99, '', 'FontSize', supp.fontsmall, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
        for si = 1:length(axx)
            hax{si} = axes( 'Parent', hfg, 'Position', [axx(si), axy(si), axw(si), axh(si)] );
        end

    elseif (iscell(optin) && any(strcmp(cellfun(@(x) get(x, 'type'), optin, 'UniformOutput', false), 'axes'))) || ...
            (~iscell(optin) && strcmp(get(optin, 'type'), 'axes')) %add to existing figure passed as optin

        optin_is_figure = 1;
        hax = optin;
    
    end

end



depvp = zeros(size(indv, 1), 1);
doplots_filt = 0;
doplots_hot = 0;

fnl = fieldnames(supp.ann);
num_lay = length(fnl);

plotcols = distinguishable_colors(supp.num_neuron_total);

for li = 1:num_lay

    fnc = fieldnames(supp.ann.(fnl{li}));
    num_chan = length(fnc);
    neuron_count_single_layer = 0;
    if do_increment_framecount
        framecount = framecount + 1;
    end


    for ci = 1:num_chan %1:supp.num_dim_indvpre %loop over input channels (indv dims in layer 1)

        anntmp = supp.ann.(fnl{li}).(fnc{ci});

        ivinds = [1:supp.num_samp_mdl]*supp.num_dim_indvpre-(supp.num_dim_indvpre-ci); %since indv is organized this way, dims alternate in vec
        indvtmp = indv(:,ivinds);

        for ni = 1:anntmp.num_neuron %supp.num_neuron %loop over artificial neurons

            binmns = [];

            neuron_count_single_layer = neuron_count_single_layer+1;

            tmptmp = num2cell(pars(anntmp.pind(ni).L));
            if length(tmptmp)==3
                tmp = tmptmp(1:2);
                filtbias = tmptmp{3};
            else
                tmp = tmptmp;
                filtbias = 0;
            end
            if strcmp(anntmp.annspec.strlin{ni}, 'l')
                error("how to deal with this when onehot nonlin?")
            else
                if strcmp(anntmp.annspec.strlin{ni}, 'f')
                    filt = cell2mat(tmp); %optimize filter weights directly
                elseif strcmp(anntmp.annspec.strlin{ni}, 's')
                    flagdiff = 0;
                    filt = anntmp.linfun(flagdiff, doplots_filt, tmp{:}); %make linear filter, tau1, tau2, shift, tc, norm, numsamp, doplots
                elseif strcmp(anntmp.annspec.strlin{ni}, 'd')
                    flagdiff = 1;
                    filt = anntmp.linfun(flagdiff, doplots_filt, tmp{:});
                    % 'differentiating_old' approach here (messier) ---> filt = linear_filter_1d_deprecated(supp.num_samp_mdl, filtnorm, doplots_filt, tmp{:}); %make linear filter, tau1, tau2, shift, tc, norm, numsamp, doplots
                end
                depvptmp = sum(indvtmp.*filt, 2); %apply linear filter
                depvptmp = depvptmp + filtbias;
            end

            if make_figure
                depvplin = depvptmp; %save this for plotting after optimization, don't want to add variable if not plotting to keep optimization code light
            end

            tmp = num2cell(pars(anntmp.pind(ni).N));
            if ~isempty(tmp) || startsWith(anntmp.annspec.stract{ni}, 'h') || strcmp(anntmp.annspec.stract{ni}, 'y') 
                if startsWith(anntmp.annspec.stract{ni}, 'h') || strcmp(anntmp.annspec.stract{ni}, 'y') 
                    if isempty(anntmp.annspec.independently_discretized_hot_dims{ni}) || strcmp(anntmp.annspec.independently_discretized_hot_dims{ni}, 'x')
                        depvptmp2(:,neuron_count_single_layer) = depvptmp;
                        depvptmp(:) = 0;
                        if strcmp(anntmp.annspec.independently_discretized_hot_dims{ni}, 'x') %after all input channels and current neurons
                            [depvptmp, binmns] = anntmp.actfun{ni}(doplots_hot, outflag, pthspre, depvptmp2, anntmp.annspec.numbinhot{ni}, anntmp.annspec.independently_discretized_hot_dims{ni}, cell2mat(tmp));
                        end
                    elseif ismember(anntmp.annspec.independently_discretized_hot_dims{ni}, {'c', 't', 'n'})
                        [depvptmp, binmns] = anntmp.actfun{ni}(doplots_hot, outflag, pthspre, depvptmp, anntmp.annspec.numbinhot{ni}, anntmp.annspec.independently_discretized_hot_dims{ni}, cell2mat(tmp));
                    end
                else
                    depvptmp = anntmp.actfun{ni}(depvptmp, tmp{:}); %apply activation function
                end
            end
            depvp = depvp + depvptmp; %sum outputs across loop


            if make_figure

                sfi_tmp = 1;
                sfi = sfi_tmp+anntmp.max_num_fun_per_neuron*(neuron_count_single_layer-1);
                sfi = sfi+supp.starting_hax;

                if framecount==1
                    if strcmp(anntmp.annspec.stract{ni}, 'y') || startsWith(anntmp.annspec.stract{ni}, 'h')
                        filtcol = plotcols(neuron_count_single_layer,:);
                    else
                        filtcol = plotcols(1,:);
                    end
                    plot(hax{sfi}, filt, 'Color', filtcol);

                    xlm = hax{sfi}.XLim;
                    extrax = supp.extra_xlim_fac*range(xlm(:));
                    hax{sfi}.XAxis.TickValues = linspace(0, supp.num_samp_mdl, 3);
                    hax{sfi}.XAxis.TickLabels = round(hax{sfi}.XAxis.TickValues*supp.dt, 2);
                    hax{sfi}.XAxis.TickLabelFormat = '%.1f';
                    hax{sfi}.XAxis.FontSize = supp.fontsmall;
                    hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];

                else
                    hax{sfi}.Children.YData = filt;
                end

                lpars_adj = pars(anntmp.pind(ni).L);
                lpars_adj(2) = lpars_adj(2) * supp.dt;
                pars_str_L = sprintf('%.2f,  ', lpars_adj);
                pars_str_L = pars_str_L(1:end-3);% strip final comma
                pars_str_N = sprintf('%.2f,  ', pars(anntmp.pind(ni).N));
                pars_str_N = pars_str_N(1:end-3);% strip final comma
                if ~isempty(pars_str_N)
                    pars_str_N = ['::' pars_str_N];% strip final comma
                end
                hax{sfi}.Title.String = {['dim ' num2str(ci) ', LN ' num2str(ni)]; [pars_str_L pars_str_N]};
                hax{sfi}.Title.FontSize = supp.fontsmall;

                if ~isempty(pars_str_N)

                    sfi_tmp = 2;
                    sfi = sfi_tmp+anntmp.max_num_fun_per_neuron*(neuron_count_single_layer-1);
                    sfi = sfi+supp.starting_hax;

                    [depvplin, idx] = sort(depvplin);

                    if framecount==1
                        if binmns
                            % scatter3(hax{sfi}, depvptmp2(:,1), depvptmp2(:,2), depvptmp, 'filled'); %sorting prevents an odd plotting error
                            % scatter3(hax{sfi}, binmns(1,:), binmns(2,:), pars(anntmp.pind(ni).N), 'filled'); %sorting prevents an odd plotting error
                            for bmi = 1:size(binmns, 1)
                                scatter(hax{sfi}, binmns(bmi,:), pars(anntmp.pind(ni).N), 15, plotcols(bmi,:), 'filled'); hold on; %sorting prevents an odd plotting error
                            end
                        else
                            plot(hax{sfi}, depvplin, depvptmp(idx)); %sorting prevents an odd plotting error
                        end
                    else
                        if binmns
                            for bmi = 1:size(binmns, 1)
                                hax{sfi}.Children(bmi).XData = binmns(bmi,:);
                                hax{sfi}.Children(bmi).YData = pars(anntmp.pind(ni).N);
                                % hax{sfi}.Children(bmi).XData = binmns(bmi,:);
                                % hax{sfi}.Children(bmi).YData = binmns(bmi,:);
                                % hax{sfi}.Children(bmi).ZData = pars(anntmp.pind(ni).N);
                            end
                        else
                            hax{sfi}.Children.XData = depvplin;
                            hax{sfi}.Children.YData = depvptmp(idx);
                        end
                    end

                    hax{sfi}.XAxis.Limits = [min(depvplin(:)) max(depvplin(:))];
                    xlm = hax{sfi}.XLim;
                    hax{sfi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
                    hax{sfi}.XAxis.TickLabels = hax{sfi}.XAxis.TickValues;
                    hax{sfi}.XAxis.TickLabelFormat = '%.2f';
                    hax{sfi}.XAxis.FontSize = supp.fontsmall;
                    extrax = supp.extra_xlim_fac*range(xlm);
                    hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];
                    % pars_str = sprintf('%.2f,  ', pars(supp.pind(ni).N));
                    % pars_str = pars_str(1:end-1);% strip final comma
                    % % hax{sfi}.Title.String = {['neuron ' num2str(jj)]; pars_str};
                    % hax{sfi}.Title.String = {pars_str};
                    % hax{sfi}.Title.FontSize = supp.fontsmall;

                end

                if ~optin_is_figure
                    if neuron_count_single_layer==supp.num_neuron_total
                        htx.String = fn_save;
                        framecount = 1;
                        fig2gif(hfg, framecount, pth_save)
                    end
                end



            end
        end

    end

end


end
