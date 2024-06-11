function scatterplots(varsx, varsy, varsz, labsx, labsy, labsz, epochinds_all, stack, roiinfo, ti, epochinds_ts_i, maxlagxy, maxlagz, plot_z_as_color, plot_zero_lag_only, gif_visibility, fn_prefix)


% plots xy and optional z with optional lags in x-y and xy-z;
% z can be assigned color instead of spatial dimension
% todo: will need a switch to crop to model timeseries numel
% todo: z lag not plotted yet

threshold_data = 0;
pval_siglev = 0.05; %pval bar gets colored if below pval_siglev

roomfac_x = 0.1;

rdummy1_lbnd = 0.1;
rdummy1_ubnd = 0.45;
rdummy2_lbnd = 0.5;
rdummy2_ubnd = 0.85;

theta_ticks = [0 90 180 270];
theta_tick_labels = {'0', '', '180', ''};

mkrsz = 4; %scatter marker size
fontmedium = 15;
xlim_makeroomfac = 0.1;
extrax = 2*maxlagxy*xlim_makeroomfac;

numrows = 2;
numcolumns = 3; %keep room for 2nd polar scatterplot
margins_fig = 0.03;
margins_subfig = 0.05;
[axx, axy, axw, axh] = arrange_subplots(numrows, numcolumns, margins_fig, margins_subfig);

if plot_z_as_color
    dimstring = '2dcol';
else
    dimstring = '3d';
end

if isempty(varsz)
    z_is_empty = 1;
    varsz = ones(size(varsx(1,:)));
    labsz = {''};
    if maxlagz
        disp("changing maxlagz to zero since there is no z variable")
        maxlagz = 0;
    end
else
    z_is_empty = 0;
end


lagsxy = -maxlagxy:maxlagxy;
lagsz = -maxlagz:maxlagz;
lagind = 0;
for lzi = lagsz 
    for lxyi = lagsxy
        lagind = lagind + 1;
        lagsall(1, lagind) = lxyi; 
        lagsall(2, lagind) = lzi; 
    end
end

if plot_zero_lag_only
else
    laginds_to_plot = 1:size(lagsall, 2);
end

numlags = numel(lagsxy) * numel(lagsz);


for rind = 1:numel(epochinds_all)

    epochinds = epochinds_all{rind};
    epochstring = sprintf('%.0f,' , epochinds);
    epochstring = epochstring(1:end-1);
    tinds = find(ismember_each_element(epochinds_ts_i, epochinds));
    tinew = ti(tinds);


    for zi = 1:size(varsz, 1)
        for yi = 1:size(varsy, 1)
            for xi = 1:size(varsx, 1)

                varx = varsx(xi, tinds);
                vary = varsy(yi, tinds);
                varz = varsz(zi, tinds);

                labx = strrep(strrep(strrep(labsx{xi}, '_', ' '), '.', ' '), 'ts', '');
                laby = strrep(strrep(strrep(labsy{yi}, '_', ' '), '.', ' '), 'ts', '');
                labz = strrep(strrep(strrep(labsz{zi}, '_', ' '), '.', ' '), 'ts', '');

                laball = {labx, laby, labz};

                skipplot = 0;
                % skipplot = skip_plot_criteria(laball);

                indpolar = [];
                if contains(labx, 'yaw') || contains(labx, 'angle')
                    indpolar = [indpolar 1];
                end
                if contains(laby, 'yaw') || contains(laby, 'angle')
                    indpolar = [indpolar 2];
                end
                if contains(labz, 'yaw') || contains(labz, 'angle')
                    indpolar = [indpolar 3];
                end

                axtype = set_axtype(indpolar, z_is_empty, plot_z_as_color);

                if numel(indpolar)>1 || any(indpolar==3)
                    error("can't use multiple polar variables yet, or z polar")
                end

                if ~skipplot

                    if isequal(indpolar, 2)
                        figure_title = {[axtype{1} laby]; [axtype{2} labx]; [axtype{3} labz]; ['e' epochstring ' ' dimstring ]}; %switch order
                        labt = laby;
                        labr = labx;
                    else
                        figure_title = {[axtype{1} labx]; [axtype{2} laby]; [axtype{3} labz]; ['e' epochstring ' ' dimstring ]}; %switch order
                        labt = labx;
                        labr = laby;
                    end
                    fngif = [fn_prefix '_' strrep(strjoin(figure_title), ' ', '_') '_.gif' ];

                    hfg = figure( 'Units', 'normalized', 'Position', [0.8, 0.8, 0.8, 0.8], 'Color', 'white', 'visible', gif_visibility) ;
                    bgAxes = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;
                    text( 0.5, 0.95, figure_title, 'FontSize', fontmedium, 'HorizontalAlignment', 'center', 'FontWeight', 'bold' ) ;


                    plotx = cell(1, numel(lagsxy));
                    ploty = cell(1, numel(lagsxy));
                    plotz = cell(1, numel(lagsxy));
                    r_dummy1 = cell(1, numel(lagsxy));
                    r_dummy2 = cell(1, numel(lagsxy));
                    cmp = cell(1, numel(lagsxy));
                    ccr = zeros(1, numel(lagsxy));
                    ccpv = zeros(1, numel(lagsxy));

                    %hack: first find ccr in seperate initial loop because of plot hold problem in plot loop below
                    lagind = 0;
                    for lxyi = 1:numel(lagsxy)
                        for lzi = 1:numel(lagsz)
                            lagind = lagind+1;

                            [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagsxy(lxyi), lagsz(lzi));

                            %remove nans
                            keepind = ~(isnan(varx_lagxyz) | isnan(vary_lagxyz));
                            varz_lagxyz_isnan = isnan(varz_lagxyz);
                            if ~isempty(varz_lagxyz_isnan)
                                keepind = keepind | varz_lagxyz_isnan;
                                plotz{lagind} = varz_lagxyz(keepind);
                            end
                            plotx{lagind} = varx_lagxyz(keepind);
                            ploty{lagind} = vary_lagxyz(keepind);
                            if isempty(varz_lagxyz_isnan)
                                plotz{lagind} = ones(numel(plotx{lagind}), 1);
                            end



                            %threshold if requested
                            if threshold_data
                                if contains(laball{1}, 'ball.vel')
                                    [histdt, histx] = hist(abs(plotx{lagind}(:)), 500);
                                    thrbin = triangle_threshold(histdt, 'R', 0);
                                    thrvel = histx(thrbin);
                                    excludeinds = abs(plotx{lagind})<thrvel;
                                elseif contains(laball{2}, 'ball.vel')
                                    [histdt, histx] = hist(abs(ploty{lagind}(:)), 500);
                                    thrbin = triangle_threshold(histdt, 'R', 0);
                                    thrvel = histx(thrbin);
                                    excludeinds = abs(ploty{lagind})<thrvel;
                                end
                                plotx{lagind}(excludeinds) = [];
                                ploty{lagind}(excludeinds) = [];
                                plotz{lagind}(excludeinds) = [];
                            end


                            %sort for color plot (if plot_z_as_color)
                            if z_is_empty | (~z_is_empty & ~plot_z_as_color)
                                cmp{lagind} = [0 0 1];
                            elseif ~z_is_empty & plot_z_as_color
                                [~, idx4] = sort(plotz{lagind});
                                plotx{lagind} = plotx{lagind}(idx4);
                                ploty{lagind} = ploty{lagind}(idx4);
                                cmp{lagind} = jet(numel(idx4));
                            end


                            %dummy variables for possible polar plots
                            r_dummy1{lagind} = rdummy1_lbnd + (rdummy1_ubnd-rdummy1_lbnd)*rand(size(plotx{lagind}));
                            r_dummy2{lagind} = rdummy2_lbnd + (rdummy2_ubnd-rdummy2_lbnd)*rand(size(ploty{lagind}));

                            %find corr coeffs
                            switch num2str(indpolar)
                                case ''
                                    [ccr(lagind) ccpv(lagind)] = corr(plotx{lagind}, ploty{lagind}); %linear-linear
                                    % [ccr(lagind) ccpv(lagind)] = corr(plotz{lagind}, ploty{lagind}); %linear-linear
                                case '1'
                                    [ccr(lagind) ccpv(lagind)] = circ_corrcl(plotx{lagind}, ploty{lagind}); %circ-linear
                                case '2'
                                    [ccr(lagind) ccpv(lagind)] = circ_corrcl(ploty{lagind}, plotx{lagind}); %circ-linear (and switch input order)
                                case '1  2'
                                    [ccr(lagind) ccpv(lagind)] = circ_corrcc(plotx{lagind}, ploty{lagind}); %circ-circ
                            end
                        end
                    end


                    %now the plotting loop
                    for lagind = laginds_to_plot
                        
                        if lagind==1

                            spind = 1;
                            hax1 = axes( 'Parent', hfg, 'Position', [axx(spind), axy(spind), axw(spind), axh(spind)] );
                            hax1.PlotBoxAspectRatio = [1 1 1];

                            hbr = gobjects(numlags);
                            %cla()
                            hold on

                            for li = 1:numlags
                                hbr(li) = bar(lagsall(1,li),ccr(li));
                                pval_norm = pval_siglev-ccpv(li);
                                if pval_norm<0
                                    pval_norm = 0;
                                end
                                set(hbr(li), 'FaceColor', 'b', 'FaceAlpha', pval_norm);
                            end

                            %hbr = bar(hax1, laginds, ccr);

                            %hax1.XLim = [-maxlagxy - extrax1 maxlagxy + extrax1];
                            hax1.YLim = [-1 1];
                            hlin = xline(hax1, lagsall(1,lagind), 'k');


                            spind = 4;
                            hax2 = axes( 'Parent', hfg, 'Position', [axx(spind), axy(spind), axw(spind)*2, axh(spind)*2] );

                            switch num2str(indpolar)
                                case ''
                                    if plot_z_as_color
                                        hsc1 = scatter(hax2, plotx{lagind}, ploty{lagind}, mkrsz, cmp{lagind}, 'filled');
                                    else
                                        hsc1 = scatter3(hax2, plotx{lagind}, ploty{lagind}, plotz{lagind}, mkrsz, cmp{lagind}, 'filled');
                                    end
                                    hax2.XLabel.String = labx;
                                    hax2.YLabel.String = laby;
                                    % hax2.ZLabel.String = labz;
                                otherwise
                                    hpax1 = polaraxes('Units', hax2.Units, 'Position', hax2.Position);
                                    if isequal(indpolar, 1)
                                        hsc1 = polarscatter(hpax1, plotx{lagind}, ploty{lagind}, mkrsz, cmp{lagind}, 'filled'); %switch input order
                                        hold(hpax1, 'on')
                                    elseif isequal(indpolar, 2)
                                        hsc1 = polarscatter(hpax1, ploty{lagind}, plotx{lagind}, mkrsz, cmp{lagind}, 'filled');
                                        hold(hpax1, 'on')
                                    elseif isequal(indpolar, [1, 2])
                                        hsc1 = polarscatter(hpax1, plotx{lagind}, r_dummy1{lagind}, mkrsz, 'filled');
                                        hold(hpax1, 'on')
                                        hsc2 = polarscatter(hpax1, ploty{lagind}, r_dummy2{lagind}, mkrsz, 'filled');
                                    end
                                    hax2.YAxis.Visible = 'off';
                                    hax2.XAxis.Visible = 'off';
                                    %hpax1.RTickLabel = [];
                                    %hsc3 = polarplot(hpax1, [-pi/12 -pi/12], [min(hsc1.RData) max(hsc1.RData)], 'r');

                                    hpax1.RLim = [min(hsc1.RData) - range(hsc1.RData)*roomfac_x max(hsc1.RData) + range(hsc1.RData)*roomfac_x];
                                    hsc3 = polarplot(hpax1, [-pi/12 -pi/12], hpax1.RLim, 'r');

                                    hpax1.ThetaTick = theta_ticks;
                                    hpax1.ThetaTickLabel = theta_tick_labels;

                                    hold(hpax1, 'on')

                                    % hpax1.RAxis.Label.String = ['Rho: ' labr];
                                    hpax1.ThetaAxis.Label.String = {['Theta: ' labt]; ['Rho: ' labr]};
                                    hpax1.ThetaAxis.Label.Position = [-90, 155, 0];
                                    hpax1.ThetaAxis.Label.Rotation = 0;
                                    % hpax1.zaxis??

                            end
                            set(hax1,'box','off')
                            set(hax2,'box','off')
                            hax2.PlotBoxAspectRatio = [1 1 1];

                            hax1.XLabel.String = 'lag';
                            hax1.YLabel.String = 'corr coeff';


                        else

                            hlin.Value = lagsall(1, lagind);

                            switch num2str(indpolar)
                                case ''
                                    hsc1.XData = plotx{lagind};
                                    hsc1.YData = ploty{lagind};
                                    hsc1.CData = cmp{lagind};
                                    if ~plot_z_as_color
                                        hsc1.ZData = plotz{lagind};
                                    end
                                case '1'
                                    %hpax1.RTickLabel = [];
                                    hsc1.ThetaData = plotx{lagind};
                                    hsc1.RData = ploty{lagind};
                                    hsc1.CData = cmp{lagind};
                                case '2'
                                    hpax1.RTickLabel = [];
                                    hsc1.ThetaData = ploty{lagind};
                                    hsc1.RData = plotx{lagind};
                                    hsc1.CData = cmp{lagind};
                                case '1  2'
                                    hpax1.RTickLabel = [];
                                    hsc1.ThetaData = plotx{lagind};
                                    hsc1.RData = r_dummy1{lagind};
                                    hsc2.ThetaData = ploty{lagind};
                                    hsc2.RData = r_dummy2{lagind};
                            end


                        end

                        fig2gif(hfg, lagind, fngif)

                        if ~plot_z_as_color & isequal(lagsall(:,lagind), [0;0])
                            saveas( gcf, [fngif(1:end-4) 'nolag_.fig']) %save 3d plots as fig so you can rotate
                        end

                    end %lags
                end %skip

                close all

            end %x
        end %y
    end %z
end %epoch


end %function



function [varx_lagxyz, vary_lagxyz, varz_lagxyz] = lagvars(varx, vary, varz, lagxy, lagz)


%first apply xy lag
if lagxy<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
    varx_lagxy = vec(varx(1+abs(lagxy):end));
    vary_lagxy = vec(vary(1:end-abs(lagxy)));
else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
    varx_lagxy = vec(varx(1:end-abs(lagxy)));
    vary_lagxy = vec(vary(1+abs(lagxy):end));
end

%now apply 3rd variable lag
if lagz<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
    varx_lagxyz = vec(varx_lagxy(1+abs(lagz):end));
    vary_lagxyz = vec(vary_lagxy(1+abs(lagz):end));
    varz_lagxyz = vec(varz(1:end - (abs(lagxy)+abs(lagz)) )); %also include lagxy for 3rd var
else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
    varx_lagxyz = vec(varx_lagxy(1:end-abs(lagz)));
    vary_lagxyz = vec(vary_lagxy(1:end-abs(lagz)));
    varz_lagxyz = vec(varz( (1+abs(lagxy)+abs(lagz) ) :end));
end

end

function skipplot = skip_plot_criteria(laball)

if ~any(endsWith(laball, 'vel')) & ~any(endsWith(laball, 'speed'))
    skipplot = 1;
end

if numel(unique(laball(:)))~=numel(laball(:)) %must not have duplicate vars
    skipplot = 1;
end

if any(strcmp(laball, 'cuevel')) & skip_cuevel %must not have cuevel if skip_cuevel
    skipplot = 1;
end

if ((any(strcmp(laball, 'respgal')) | any(strcmp(laball, 'respgar'))) & any(strcmp(laball, 'respgalrmean'))) | ... %must not have no and ga from "same side" (not connected)
        ((any(strcmp(laball, 'respnol')) | any(strcmp(laball, 'respnor'))) & any(strcmp(laball, 'respnolrmean')))
    skipplot = 1;
end

if (any(endsWith(laball, 'gar')) & any(endsWith(laball, 'no_r'))) | ... %must not have no and ga from "same side" (not connected)
        (any(endsWith(laball, 'gal')) & any(endsWith(laball, 'no_l')))
    skipplot = 1;
end

end


function axtype = set_axtype(indpolar, z_is_empty, plot_z_as_color)

if isempty(indpolar)
    axtype = {'X', 'Y'};
else
    axtype = {'T', 'R'};
end
if z_is_empty
    axtype{3} = '';
else
    if plot_z_as_color
        axtype{3} = 'C';
    else
        axtype{3} = 'Z';
    end
end

end
