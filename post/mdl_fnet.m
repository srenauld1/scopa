
function [outtmpall, hax, out2] = mdl_fnet(pars, indv, supp, optin)

%function network, with optional plotting
%could change how indv is organized before this function for speed (since it's organized for linear fits right now)
%plotting currently is one layer per frame, with units as rows and functions as columns; for each function, plots show input, output, transfer function, and params

make_figure = 0; %0 to not make figure (during optimization), 1 to make and save here, 2 if plotting on axes that are passed in as argument (and not saving here)
margins_fig = 0.03; %if not passing in figure
margins_subplot = 0.06;%if not passing in figure
extra_xlim_fac = 0.1;%if not passing in figure
fontsmall = 8;
outflag = 0; %made 1 if making figures; flag to make some functions output an extra variable for plotting

if exist('optin', 'var') && ~isempty(optin)

    outflag = 1;
    plotcolors = distinguishable_colors(supp.num_total_model_functions);

    if ischar(optin) || isstring(optin) %create new figure with filename optin

        make_figure = 1;
        framecount_gif = 1;
        hfg = []; hax = []; htx = []; numrows_plot = 0; numcolumns_plot = 0; %init figure handle so figinit knows to make figure, rather than update existing figure
        supp.starting_hax = 0;

        pth_save = [optin 'MODELCOMPS_.gif'];
        [~, fn_save, ~] = fileparts(pth_save);
        fn_save = strrep(fn_save, '_', ' ');

    elseif (iscell(optin) && any(strcmp(cellfun(@(x) get(x, 'type'), optin, 'UniformOutput', false), 'axes'))) || ...
            (~iscell(optin) && strcmp(get(optin, 'type'), 'axes')) %plot onto existing figure passed in as 'optin'

        make_figure = 2;
        hax = optin;
        newaxes = 1;
        if isfield(supp, 'framecount')
            if supp.framecount>1
                newaxes = 0;
            end
        end

    end

end

doplots_fun = 0;
layer_index_previous = 0;

for k = 1:supp.num_unit_total %loop over all units, indexing into input/output according to layer and channel fields

    fnetunit = supp.fnet(k,:);

    layer_in_index = supp.fnet(k,:).layer_in_index;
    chanout = fnetunit.channel_out;

    if layer_in_index~=layer_index_previous
        fragile_layer_out_index_variable = layer_in_index+1;
        allchanout_currlayer = unique([supp.fnet([supp.fnet.layer_out_index]==fragile_layer_out_index_variable).channel_out]);
        if k~=1
            intmp = outtmpall;
        end
        outtmpall = zeros(size(indv,1), numel(allchanout_currlayer));
        layer_index_previous = layer_in_index;
        fun_count_curr_layer = 0;
        unit_count_curr_layer = 0;
        max_num_fun_curr_layer = max([supp.fnet([supp.fnet.layer_in_index]==layer_in_index).num_fun]);
        num_unit_curr_layer = numel(supp.fnet([supp.fnet.layer_in_index]==layer_in_index));
        if make_figure==1
            if num_unit_curr_layer~=numrows_plot && max_num_fun_curr_layer~=numcolumns_plot %only update axes ('hax') if layout must change  
                newaxes = 1;
                numrows_plot = num_unit_curr_layer;
                numcolumns_plot = max_num_fun_curr_layer;
                [hfg, hax, htx] = figinit(hfg, hax, htx, numrows_plot, numcolumns_plot, margins_fig, margins_subplot, fontsmall);
            end
        end
    end

    if fnetunit.layer_in_index==1 %this if clause for now, soon intermediate layers will also get reorganized the same way indv is in mfit_prepvars (fine for now since not using intermediate multi sample layers)
        chan_in_inds = [1:supp.num_samp_mdl]*supp.num_dim_indvp-(supp.num_dim_indvp-vec(fnetunit.channel_in)); %since indv is organized this way, dims alternate in vec
        outtmp = indv(:,chan_in_inds);
    else
        chan_in_inds = fnetunit.channel_in;
        outtmp = intmp(:,chan_in_inds);
    end

    unit_count_curr_layer = unit_count_curr_layer+1;
    fun_count_curr_unit = 0;
    for fi = 1:fnetunit.num_fun %loop over each function in the unit

        fun_count_curr_unit = fun_count_curr_unit+1;
        fun_count_curr_layer = fun_count_curr_layer+1;
        pars_curr_fun = pars(fnetunit.pind{fi});

        % outtmpplot = fnettmp.funh{fi}(outtmp, fnettmp.funstr{fi}, doplots_fun, outflag, pars_this_fun);
        % outtmpplot = interp1(1:numel(outtmpplot), outtmpplot, 1:numel(outtmp(:)));
        % [outtmpplot, idx] = sort(outtmpplot);
        % figure; plot(outtmpplot, outtmp(idx));

        if make_figure
            outtmpplot_in = outtmp;
        end

        [outtmp, out2] = fnetunit.funh{fi}(outtmp, fnetunit.funstr{fi}, doplots_fun, outflag, pars_curr_fun); %apply function

        if make_figure

            sfi = fun_count_curr_unit+max_num_fun_curr_layer*(unit_count_curr_layer-1);
            sfi = sfi+supp.starting_hax; %in case you pass in figure handle as argument 'optin'

            if any(strcmp(fnetunit.funstr{fi}, {'s', 'r', 'd', 'c', 'f'}))

                if newaxes

                    plotcolor_onefun = plotcolors(1,:);

                    plot(hax{sfi}, out2, 'Color', plotcolor_onefun);

                    xlm = hax{sfi}.XLim;
                    hax{sfi}.XAxis.TickValues = linspace(0, numel(out2), 3); %linspace(0, supp.num_samp_mdl, 3);
                    hax{sfi}.XAxis.TickLabels = round(hax{sfi}.XAxis.TickValues*supp.sampper, 2);

                else
                    hax{sfi}.Children.YData = out2;
                end

                if ~strcmp(fnetunit.funstr{fi}, 'f')
                    pars_plot = pars_curr_fun;
                    pars_plot(2) = pars_plot(2) * supp.sampper;
                end

            else

                [outtmpplot_in, idx] = sort(outtmpplot_in);

                if newaxes
                    if startsWith(fnetunit.funstr{fi}, 'h')
                        for bmi = 1:size(out2, 1)
                            scatter(hax{sfi}, out2(bmi,:), pars_curr_fun, 15, plotcolors(bmi,:), 'filled'); hold on; %sorting prevents an odd plotting error
                        end
                    else
                        plot(hax{sfi}, outtmpplot_in, outtmp(idx), 'r-'); %sorting prevents an odd plotting error
                    end
                else
                    if startsWith(fnetunit.funstr{fi}, 'h')
                        for bmi = 1:size(out2, 1)
                            hax{sfi}.Children(bmi).XData = out2(bmi,:);
                            hax{sfi}.Children(bmi).YData = pars_curr_fun;
                        end
                    else
                        hax{sfi}.Children.XData = outtmpplot_in;
                        hax{sfi}.Children.YData = outtmp(idx);
                    end
                end

                hax{sfi}.XAxis.Limits = [min(outtmpplot_in(:)) max(outtmpplot_in(:))];
                xlm = hax{sfi}.XLim;
                hax{sfi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
                hax{sfi}.XAxis.TickLabels = hax{sfi}.XAxis.TickValues;

                pars_plot = pars_curr_fun;

            end

            extrax = extra_xlim_fac*range(xlm(:));
            hax{sfi}.XAxis.TickLabelFormat = '%.1f';
            hax{sfi}.XAxis.FontSize = fontsmall;
            hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];

            pars_str = sprintf('%.2f,  ', pars_plot);
            pars_str = pars_str(1:end-3); %strip final comma

            hax{sfi}.Title.String = pars_str; %{['dim ' num2str(ci) ', LN ' num2str(fi)]; [pars_str pars_str_N]};
            hax{sfi}.Title.FontSize = fontsmall;

            if make_figure==1
                if unit_count_curr_layer==num_unit_curr_layer && fi==fnetunit.num_fun 
                    htx.String = fn_save;
                    fig2gif(hfg, framecount_gif, pth_save)
                    framecount_gif = framecount_gif+1;
                end
            end

        end
    end

    outtmpall(:, chanout) = outtmp;

end

if size(outtmpall, 2)>1
    error("output should be vector")
end

end
