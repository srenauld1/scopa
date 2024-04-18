
function [depvp, hax, binmns] = mdl_fnet(pars, indv, supp, optin)

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

plotcols = distinguishable_colors(supp.num_total_model_functions);

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
        numrows_plot = supp.max_num_fun_per_unit;
        numcolumns_plot = supp.num_unit_total;
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
doplots_fun = 0;

for ui = 1:supp.num_unit_total %loop over all units, indexing into input/output according to layer and channel fields 

    fun_count_single_layer = 0;
    if do_increment_framecount
        framecount = framecount + 1;
    end

    fnettmp = supp.fnet(ui,:);

    if fnettmp.layer_in_index==1 %this if clause for now, soon intermediate layers will also get reorganized the same way indv is in fitmdl_prepvars (fine for now since not using intermediate multi sample layers)
        indv_chan_inds = [1:supp.num_samp_mdl]*supp.num_dim_indvpre-(supp.num_dim_indvpre-fnettmp.channel_in); %since indv is organized this way, dims alternate in vec
    else
        indv_chan_inds = fnettmp.channel_in;
    end
    indvtmp = indv(:,indv_chan_inds);

    for fi = 1:fnettmp.num_fun %loop over each function in the unit

        binmns = [];

        fun_count_single_layer = fun_count_single_layer+1;

        tmp = num2cell(pars(fnettmp.pind{fi}));

        need to accumulate output for input
        [depvptmp, filt] = fnettmp.funh{fi}(indvtmp, fnettmp.funstr{fi}, doplots_fun, outflag, tmp{:});

        % "how to deal with ohe without linear preceding? is it fine as is"

        if make_figure
            depvpplot = depvptmp; %save this for plotting after optimization, don't want to add variable if not plotting to keep optimization code light
        end

        tmp = num2cell(pars(fnettmp.pind(fi).N));
        if ~isempty(tmp) || startsWith(fnettmp.fnetspec.stract{fi}, 'h') || strcmp(fnettmp.fnetspec.stract{fi}, 'y')
            if startsWith(fnettmp.fnetspec.stract{fi}, 'h') || strcmp(fnettmp.fnetspec.stract{fi}, 'y')
                if isempty(fnettmp.fnetspec.independently_discretized_hot_dims{fi}) || strcmp(fnettmp.fnetspec.independently_discretized_hot_dims{fi}, 'x')
                    depvptmp2(:,fun_count_single_layer) = depvptmp;
                    depvptmp(:) = 0;
                    if strcmp(fnettmp.fnetspec.independently_discretized_hot_dims{fi}, 'x') %after all input channels and current neurons
                        [depvptmp, binmns] = fnettmp.actfun{fi}(doplots_fun, outflag, pthspre, depvptmp2, fnettmp.fnetspec.numbinhot{fi}, fnettmp.fnetspec.independently_discretized_hot_dims{fi}, cell2mat(tmp));
                    end
                elseif ismember(fnettmp.fnetspec.independently_discretized_hot_dims{fi}, {'c', 't', 'n'})
                    [depvptmp, binmns] = fnettmp.actfun{fi}(doplots_fun, outflag, pthspre, depvptmp, fnettmp.fnetspec.numbinhot{fi}, fnettmp.fnetspec.independently_discretized_hot_dims{fi}, cell2mat(tmp));
                end
            else
                depvptmp = fnettmp.actfun{fi}(depvptmp, tmp{:}); %apply activation function
            end
        end
        depvp = depvp + depvptmp; %sum outputs across loop


        if make_figure

            sfi_tmp = 1;
            sfi = sfi_tmp+fnettmp.max_num_fun_per_unit*(fun_count_single_layer-1);
            sfi = sfi+supp.starting_hax;

            if framecount==1
                if strcmp(fnettmp.fnetspec.stract{fi}, 'y') || startsWith(fnettmp.fnetspec.stract{fi}, 'h')
                    filtcol = plotcols(fun_count_single_layer,:);
                else
                    filtcol = plotcols(1,:);
                end
                plot(hax{sfi}, filt, 'Color', filtcol);

                xlm = hax{sfi}.XLim;
                extrax = supp.extra_xlim_fac*range(xlm(:));
                hax{sfi}.XAxis.TickValues = linspace(0, supp.num_samp_mdl, 3);
                hax{sfi}.XAxis.TickLabels = round(hax{sfi}.XAxis.TickValues*supp.dtmni, 2);
                hax{sfi}.XAxis.TickLabelFormat = '%.1f';
                hax{sfi}.XAxis.FontSize = supp.fontsmall;
                hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];

            else
                hax{sfi}.Children.YData = filt;
            end

            lpars_adj = pars(fnettmp.pind(fi).L);
            lpars_adj(2) = lpars_adj(2) * supp.dtmni;
            pars_str_L = sprintf('%.2f,  ', lpars_adj);
            pars_str_L = pars_str_L(1:end-3);% strip final comma
            pars_str_N = sprintf('%.2f,  ', pars(fnettmp.pind(fi).N));
            pars_str_N = pars_str_N(1:end-3);% strip final comma
            if ~isempty(pars_str_N)
                pars_str_N = ['::' pars_str_N];% strip final comma
            end
            hax{sfi}.Title.String = {['dim ' num2str(ci) ', LN ' num2str(fi)]; [pars_str_L pars_str_N]};
            hax{sfi}.Title.FontSize = supp.fontsmall;

            if ~isempty(pars_str_N)

                sfi_tmp = 2;
                sfi = sfi_tmp+fnettmp.max_num_fun_per_unit*(fun_count_single_layer-1);
                sfi = sfi+supp.starting_hax;

                [depvpplot, idx] = sort(depvpplot);

                if framecount==1
                    if binmns
                        % scatter3(hax{sfi}, depvptmp2(:,1), depvptmp2(:,2), depvptmp, 'filled'); %sorting prevents an odd plotting error
                        % scatter3(hax{sfi}, binmns(1,:), binmns(2,:), pars(fnettmp.pind(fi).N), 'filled'); %sorting prevents an odd plotting error
                        for bmi = 1:size(binmns, 1)
                            scatter(hax{sfi}, binmns(bmi,:), pars(fnettmp.pind(fi).N), 15, plotcols(bmi,:), 'filled'); hold on; %sorting prevents an odd plotting error
                        end
                    else
                        plot(hax{sfi}, depvpplot, depvptmp(idx)); %sorting prevents an odd plotting error
                    end
                else
                    if binmns
                        for bmi = 1:size(binmns, 1)
                            hax{sfi}.Children(bmi).XData = binmns(bmi,:);
                            hax{sfi}.Children(bmi).YData = pars(fnettmp.pind(fi).N);
                            % hax{sfi}.Children(bmi).XData = binmns(bmi,:);
                            % hax{sfi}.Children(bmi).YData = binmns(bmi,:);
                            % hax{sfi}.Children(bmi).ZData = pars(fnettmp.pind(fi).N);
                        end
                    else
                        hax{sfi}.Children.XData = depvpplot;
                        hax{sfi}.Children.YData = depvptmp(idx);
                    end
                end

                hax{sfi}.XAxis.Limits = [min(depvpplot(:)) max(depvpplot(:))];
                xlm = hax{sfi}.XLim;
                hax{sfi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
                hax{sfi}.XAxis.TickLabels = hax{sfi}.XAxis.TickValues;
                hax{sfi}.XAxis.TickLabelFormat = '%.2f';
                hax{sfi}.XAxis.FontSize = supp.fontsmall;
                extrax = supp.extra_xlim_fac*range(xlm);
                hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];
                % pars_str = sprintf('%.2f,  ', pars(supp.pind(fi).N));
                % pars_str = pars_str(1:end-1);% strip final comma
                % % hax{sfi}.Title.String = {['unit ' num2str(jj)]; pars_str};
                % hax{sfi}.Title.String = {pars_str};
                % hax{sfi}.Title.FontSize = supp.fontsmall;

            end

            if ~optin_is_figure
                if fun_count_single_layer==supp.num_unit_total
                    htx.String = fn_save;
                    framecount = 1;
                    fig2gif(hfg, framecount, pth_save)
                end
            end



        end
    end


end


end
