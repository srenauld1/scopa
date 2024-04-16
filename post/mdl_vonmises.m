function [depvp, hax, binmns] = mdl_vonmises(pars, indv, supp, optin)


hax = [];
binmns = [];
make_figure = 0;


if exist('optin', 'var') && ~isempty(optin)

    make_figure = 1;
    supp.extra_xlim_fac = 0.1;
    supp.fontsmall = 10;


    if (iscell(optin) && any(strcmp(cellfun(@(x) get(x, 'type'), optin, 'UniformOutput', false), 'axes'))) || ...
            (~iscell(optin) && strcmp(get(optin, 'type'), 'axes')) %add to existing figure passed as optin

        optin_is_figure = 1;
        hax = optin;

    elseif ischar(optin) || isstring(optin) %create new figure with filename optin

        optin_is_figure = 0;
        supp.starting_hax = 0;
        supp.framecount = 1;
        pthspre = optin;

        pth_save = [pthspre '_MODELCOMPS.gif'];
        [~, fn_save, ~] = fileparts(pth_save);
        fn_save = strrep(fn_save, '_', ' ');

        indvmin = min(indv(:));
        indvmax = max(indv(:));
        % extrax = supp.extra_xlim_fac*range(indv(:));

        fontmedium = 20;
        numrows_plot = 1;%supp.num_model_functions;
        numcolumns_plot = 1;%supp.num_dim_indvpre*supp.num_unit;
        margins_fig = 0.03;
        margins_subfig = 0.06;

        [axx, axy, axw, axh] = arrange_subplots(numrows_plot, numcolumns_plot, margins_fig, margins_subfig);

        hfg = figure( 'Units', 'Normalized', 'Color', 'white', 'visible', 'on') ;
        hfg.Position = [0 0 0.5 0.5]; %make square inner size (excludes top menu bar), plot in bottom left
        bgax = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
        htx = text( 0.05, 0.99, '', 'FontSize', supp.fontsmall, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;
        for si = 1:length(axx)
            hax{si} = axes( 'Parent', hfg, 'Position', [axx(si), axy(si), axw, axh] );
        end

    else

        error("optin must be string/char or figure axes")

    end


end


depvp = pars(1)*exp(pars(2)*cos(indv-pars(3)))+pars(4);


if make_figure

    sfi_tmp = 1;
    sfi = sfi_tmp;
    % sfi = sfi_tmp+supp.num_model_functions*(LN_unit_count-1);
    sfi = sfi+supp.starting_hax;

    [indvsort, indvsortidx] = sort(indv);

    if supp.framecount==1

        plot(hax{sfi}, indvsort, depvp(indvsortidx)); %sort to avoid weird plotting error

        xlm = hax{sfi}.XLim;
        extrax = supp.extra_xlim_fac*range(xlm(:));
        hax{sfi}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
        hax{sfi}.XAxis.TickLabelFormat = '%.2f';
        hax{sfi}.XAxis.FontSize = supp.fontsmall;
        hax{sfi}.XLim = [xlm(1) - extrax xlm(2) + extrax];

    else

        hax{sfi}.Children.XData = indvsort;
        hax{sfi}.Children.YData = depvp(indvsortidx);

    end

    pars_str_L = sprintf('%.2f,  ', pars);
    pars_str_L = pars_str_L(1:end-3);% strip final comma

    hax{sfi}.Title.String = {pars_str_L};
    hax{sfi}.Title.FontSize = supp.fontsmall;

    if ~optin_is_figure
        if LN_unit_count==supp.num_neuron_total
            htx.String = fn_save;
            fig2gif(hfg, framecount, pth_save)
        end
    end


end


end
