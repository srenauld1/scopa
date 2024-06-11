function scatterplots(varsx, varsy, varsz, labsx, labsy, labsz, epochinds_all, stack, roiinfo, ti, epochinds_ts_i, plot_z_as_color, gif_visibility, fn_prefix)


%plots xy and optional z with optional lags in xy and xy-z;
% z can be assigned color instead of spatial dimension

% will need a switch to crop to model timeseries numel
threshold_data = 0;
maxlagxy = 10;
maxlagz = 10;
roomfac_x = 0.1;

rdummy1_lbnd = 0.1;
rdummy1_ubnd = 0.45;
rdummy2_lbnd = 0.5;
rdummy2_ubnd = 0.85;

pval_siglev = 0.05;

theta_ticks = [0 90 180 270];
theta_tick_labels = {'0', '', '180', ''};

if plot_z_as_color
    dimstring = '2dcol';
else
    dimstring = '3d';
end

mkrsz = 4; %scatter marker size
fontmedium = 15;
xlim_makeroomfac = 0.1;
extrax = 2*maxlagxy*xlim_makeroomfac;

numrows = 2;
numcolumns = 3; %keep room for 2nd polar scatterplot
margins_fig = 0.03;
margins_subfig = 0.05;
[axx, axy, axw, axh] = arrange_subplots(numrows, numcolumns, margins_fig, margins_subfig);


if isempty(varsz)
    z_is_empty = 1;
    varsz = ones(size(varsx(1,:)));
    labsz = {''};
    maxlagz = 0;
else
    z_is_empty = 0;
end


lagsxy = -maxlagxy:maxlagxy;
lagsz = -maxlagz:maxlagz;
count = 0;
%this will repeatedly plot the xy lag numel(lagz) times
for lzi = lagsz
    for lxyi = lagsxy
        count = count + 1;
        lagsall(count) = lxyi;
    end
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
                    lagcount = 0;
                    for lxyi = 1:numel(lagsxy)
                        for lzi = 1:numel(lagsz)
                            lagcount = lagcount+1;

                            %first apply xy lag
                            if lagsxy(lxyi)<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
                                varx_lagxy = vec(varx(1+abs(lagsxy(lxyi)):end));
                                vary_lagxy = vec(vary(1:end-abs(lagsxy(lxyi))));
                            else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
                                varx_lagxy = vec(varx(1:end-abs(lagsxy(lxyi))));
                                vary_lagxy = vec(vary(1+abs(lagsxy(lxyi)):end));
                            end

                            %now apply 3rd variable lag (color lag, lagsz)
                            if lagsz(lzi)<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
                                varx_lagxyz = vec(varx_lagxy(1+abs(lagsz(lzi)):end));
                                vary_lagxyz = vec(vary_lagxy(1+abs(lagsz(lzi)):end));
                                varz_lagxyz = vec(varz(1:end - (abs(lagsxy(lxyi))+abs(lagsz(lzi))) )); %also include lagxy for 3rd var
                            else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
                                varx_lagxyz = vec(varx_lagxy(1:end-abs(lagsz(lzi))));
                                vary_lagxyz = vec(vary_lagxy(1:end-abs(lagsz(lzi))));
                                varz_lagxyz = vec(varz( (1+abs(lagsxy(lxyi))+abs(lagsz(lzi)) ) :end));
                            end


                            %remove nans
                            keepind = ~(isnan(varx_lagxyz) | isnan(vary_lagxyz));
                            varz_lagxyz_isnan = isnan(varz_lagxyz);
                            if ~isempty(varz_lagxyz_isnan)
                                keepind = keepind | varz_lagxyz_isnan;
                                plotz{lagcount} = varz_lagxyz(keepind);
                            end
                            plotx{lagcount} = varx_lagxyz(keepind);
                            ploty{lagcount} = vary_lagxyz(keepind);
                            if isempty(varz_lagxyz_isnan)
                                plotz{lagcount} = ones(numel(plotx{lagcount}), 1);
                            end



                            %threshold if requested
                            if threshold_data
                                if contains(laball{1}, 'ball.vel')
                                    [histdt, histx] = hist(abs(plotx{lagcount}(:)), 500);
                                    thrbin = triangle_threshold(histdt, 'R', 0);
                                    thrvel = histx(thrbin);
                                    excludeinds = abs(plotx{lagcount})<thrvel;
                                elseif contains(laball{2}, 'ball.vel')
                                    [histdt, histx] = hist(abs(ploty{lagcount}(:)), 500);
                                    thrbin = triangle_threshold(histdt, 'R', 0);
                                    thrvel = histx(thrbin);
                                    excludeinds = abs(ploty{lagcount})<thrvel;
                                end
                                plotx{lagcount}(excludeinds) = [];
                                ploty{lagcount}(excludeinds) = [];
                                plotz{lagcount}(excludeinds) = [];
                            end


                            %sort for color plot (if plot_z_as_color)
                            if z_is_empty | (~z_is_empty & ~plot_z_as_color)
                                cmp{lagcount} = [0 0 1];
                            elseif ~z_is_empty & plot_z_as_color
                                [~, idx4] = sort(plotz{lagcount});
                                plotx{lagcount} = plotx{lagcount}(idx4);
                                ploty{lagcount} = ploty{lagcount}(idx4);
                                cmp{lagcount} = jet(numel(idx4));
                            end


                            %dummy variables for possible polar plots
                            r_dummy1{lagcount} = rdummy1_lbnd + (rdummy1_ubnd-rdummy1_lbnd)*rand(size(plotx{lagcount}));
                            r_dummy2{lagcount} = rdummy2_lbnd + (rdummy2_ubnd-rdummy2_lbnd)*rand(size(ploty{lagcount}));

                            %find corr coeffs
                            switch num2str(indpolar)
                                case ''
                                    [ccr(lagcount) ccpv(lagcount)] = corr(plotx{lagcount}, ploty{lagcount}); %linear-linear
                                    % [ccr(lagcount) ccpv(lagcount)] = corr(plotz{lagcount}, ploty{lagcount}); %linear-linear
                                case '1'
                                    [ccr(lagcount) ccpv(lagcount)] = circ_corrcl(plotx{lagcount}, ploty{lagcount}); %circ-linear
                                case '2'
                                    [ccr(lagcount) ccpv(lagcount)] = circ_corrcl(ploty{lagcount}, plotx{lagcount}); %circ-linear (and switch input order)
                                case '1  2'
                                    [ccr(lagcount) ccpv(lagcount)] = circ_corrcc(plotx{lagcount}, ploty{lagcount}); %circ-circ
                            end
                        end
                    end

                    %now the plotting loop
                    lagcount = 0;
                    for lxyi = 1:numel(lagsxy)
                        for lzi = 1:numel(lagsz)
                            lagcount = lagcount+1;
                            if lagcount==1


                                spind = 1;
                                hax1 = axes( 'Parent', hfg, 'Position', [axx(spind), axy(spind), axw(spind), axh(spind)] );
                                hax1.PlotBoxAspectRatio = [1 1 1];

                                hbr = gobjects(numlags);
                                %cla()
                                hold on

                                for i = 1:numlags
                                    hbr(i)=bar(lagsall(i),ccr(i));
                                    pval_norm = pval_siglev-ccpv(i);
                                    if pval_norm<0
                                        pval_norm = 0;
                                    end
                                    set(hbr(i), 'FaceColor', 'b', 'FaceAlpha', pval_norm);
                                end

                                %hbr = bar(hax1, laginds, ccr);

                                %hax1.XLim = [-maxlagxy - extrax1 maxlagxy + extrax1];
                                hax1.YLim = [-1 1];
                                hlin = xline(hax1, lagsall(lagcount), 'k');


                                spind = 4;
                                hax2 = axes( 'Parent', hfg, 'Position', [axx(spind), axy(spind), axw(spind)*2, axh(spind)*2] );

                                switch num2str(indpolar)
                                    case ''
                                        if plot_z_as_color
                                            hsc1 = scatter(hax2, plotx{lagcount}, ploty{lagcount}, mkrsz, cmp{lagcount}, 'filled');
                                        else
                                            hsc1 = scatter3(hax2, plotx{lagcount}, ploty{lagcount}, plotz{lagcount}, mkrsz, cmp{lagcount}, 'filled');
                                        end
                                        hax2.XLabel.String = labx;
                                        hax2.YLabel.String = laby;
                                        % hax2.ZLabel.String = labz;
                                    otherwise
                                        hpax1 = polaraxes('Units', hax2.Units, 'Position', hax2.Position);
                                        if isequal(indpolar, 1)
                                            hsc1 = polarscatter(hpax1, plotx{lagcount}, ploty{lagcount}, mkrsz, cmp{lagcount}, 'filled'); %switch input order
                                            hold(hpax1, 'on')
                                        elseif isequal(indpolar, 2)
                                            hsc1 = polarscatter(hpax1, ploty{lagcount}, plotx{lagcount}, mkrsz, cmp{lagcount}, 'filled');
                                            hold(hpax1, 'on')
                                        elseif isequal(indpolar, [1, 2])
                                            hsc1 = polarscatter(hpax1, plotx{lagcount}, r_dummy1{lagcount}, mkrsz, 'filled');
                                            hold(hpax1, 'on')
                                            hsc2 = polarscatter(hpax1, ploty{lagcount}, r_dummy2{lagcount}, mkrsz, 'filled');
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

                                hlin.Value = lagsall(lagcount);

                                switch num2str(indpolar)
                                    case ''
                                        hsc1.XData = plotx{lagcount};
                                        hsc1.YData = ploty{lagcount};
                                        hsc1.CData = cmp{lagcount};
                                        if ~plot_z_as_color
                                            hsc1.ZData = plotz{lagcount};
                                        end
                                    case '1'
                                        %hpax1.RTickLabel = [];
                                        hsc1.ThetaData = plotx{lagcount};
                                        hsc1.RData = ploty{lagcount};
                                        hsc1.CData = cmp{lagcount};
                                    case '2'
                                        hpax1.RTickLabel = [];
                                        hsc1.ThetaData = ploty{lagcount};
                                        hsc1.RData = plotx{lagcount};
                                        hsc1.CData = cmp{lagcount};
                                    case '1  2'
                                        hpax1.RTickLabel = [];
                                        hsc1.ThetaData = plotx{lagcount};
                                        hsc1.RData = r_dummy1{lagcount};
                                        hsc2.ThetaData = ploty{lagcount};
                                        hsc2.RData = r_dummy2{lagcount};
                                end


                            end

                            fig2gif(hfg, lagcount, fngif)

                            if ~plot_z_as_color
                                saveas( gcf, [fngif(1:end-4) num2str(lagsxy(lxyi)) '_.fig']) %save 3d plots as fig so you can rotate
                            end

                        end
                    end
                end
                %close all


            end
        end
    end

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
