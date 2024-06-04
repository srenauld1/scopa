
function scatterplots_2d(xvars, yvars, colvars, do3d, threshold_data, ...
        epochinds, epochstring, fn_prefix, gif_visibility)

maxlagxy = 10;
lagsxy = -maxlagxy:maxlagxy;
maxlagcol = 0;
lagscol = -maxlagcol:maxlagcol;
count = 0;
for lci = lagscol
    for lxyi = lagsxy
        count = count + 1;
        lagsall(count) = lxyi;
    end
end
numlags = length(lagsxy) * length(lagscol);
roomfac_x = 0.1;

if do3d
    dimstring = '3d';
else
    dimstring = '2dcol';
end

ncol = 256; %num colors
mkrsz = 4; %scatter marker size
xlim_makeroomfac = 0.1;
extrax1 = 2*maxlagxy*xlim_makeroomfac;
numr = 2;
numc = 2; %keep room for 2nd polar scatterplot
numtot = numr*numc;

font1 = 10;

room_for_sgtitle = 0.03;
room_for_labels = 0.03;
subplot_size_fill = 1; %make 1 bc redundant with room_for* above

%positions/size of subplots including labels
xlab = linspace( 0+room_for_labels, 1-room_for_sgtitle, numr+1 ) ; %we want this to be same as y so scatterplots are axis square (was originally  linspace( 0+room_for_labels, 1, numc+1 )
xlab = xlab(1:end-1);

if numc==1
    wlab = 1 -room_for_sgtitle - room_for_labels; %we want this to be same as y so scatterplots are axis square (was originally equal to 1 if numc==1
else
    wlab = subplot_size_fill * diff( xlab(1:2) ) ;
end

ylab = linspace( 0+room_for_labels, 1-room_for_sgtitle, numr+1 ) ;
ylab = ylab(1:end-1);

if numr==1
    hlab = 1 -room_for_sgtitle - room_for_labels;
else
    hlab = subplot_size_fill * diff( ylab(1:2) ) ;
end

%positions/size of subplots excluding labels
xp = xlab + room_for_labels;
wp = wlab - room_for_labels; % can do *2 to make room for yyaxis right
yp = ylab + room_for_labels;
hp = hlab - room_for_labels;

for cvi = 1:length(colorvars)

    if isempty(colorvars{cvi})
        datcolor = [];
        labcolor = '';
    else
        datcolor = eval(colorvars{cvi});
        labcolor = colorvars{cvi};
    end

    for vci = 1:size(varscombos, 1)

        eval(['dattmp1 = ' keepvars{varscombos(vci,1)} ';']) %get the values
        eval(['dattmp2 = ' keepvars{varscombos(vci,2)} ';']) %get the values
        eval('labtmp1 =  keepvars{varscombos(vci,1)} ;') %get the name
        eval('labtmp2 =  keepvars{varscombos(vci,2)} ;') %get the name

        skipplot = 0; %some combos will not be plotted (criteria below)
        allvars = who; %all workspace vars
        labvarsall = allvars(startsWith(allvars, 'labtmp'));
        for kvi = 1:length(labvarsall)
            labvarsvals{kvi} = eval(labvarsall{kvi}); %get the labels (var names) to apply exclusion criteria
        end

        % if ~any(endsWith(labvarsvals, 'vel')) & ~any(endsWith(labvarsvals, 'speed'))
        %     skipplot = 1;
        % end
        %
        % if numel(unique(labvarsvals(:)))~=numel(labvarsvals(:)) %must not have duplicate vars
        %     skipplot = 1;
        % end
        % if any(strcmp(labvarsvals, 'cuevel')) & skip_cuevel %must not have cuevel if skip_cuevel
        %     skipplot = 1;
        % end
        % if ((any(strcmp(labvarsvals, 'respgal')) | any(strcmp(labvarsvals, 'respgar'))) & any(strcmp(labvarsvals, 'respgalrmean'))) | ... %must not have no and ga from "same side" (not connected)
        %         ((any(strcmp(labvarsvals, 'respnol')) | any(strcmp(labvarsvals, 'respnor'))) & any(strcmp(labvarsvals, 'respnolrmean')))
        %     skipplot = 1;
        % end
        % if (any(endsWith(labvarsvals, 'gar')) & any(endsWith(labvarsvals, 'no_r'))) | ... %must not have no and ga from "same side" (not connected)
        %         (any(endsWith(labvarsvals, 'gal')) & any(endsWith(labvarsvals, 'no_l')))
        %     skipplot = 1;
        % end
        %


        indpolar = find(endsWith(labvarsvals, 'ang')); %indices of polar variables

        if ~skipplot

            if isequal(indpolar, 2)
                tittmp = [labtmp2 '_xth_' labtmp1 '_yr_' labcolor '_colz_epoch_' epochstring '_' dimstring ]; %switch order
            else
                tittmp = [labtmp1 '_xth_' labtmp2 '_yr_' labcolor '_colz_epoch_' epochstring '_' dimstring ]; %keep order
            end
            fngif = [fn_prefix '_' tittmp '_.gif' ];
            figure_title = strrep(tittmp, '_', ' ');

            hfg = figure( 'Units', 'normalized', 'Position', [0.8, 0.8, 0.8, 0.8], ...
                'Color', 'white', 'visible', gif_visibility) ;
            bgAxes = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
                'XLim', [0, 1], 'YLim', [0, 1] ) ;
            text( 0.5, 0.99, figure_title, 'FontSize', font1, ...
                'HorizontalAlignment', 'center', 'FontWeight', 'bold' ) ;


            dattmp1lag = cell(1, length(lagsxy));
            dattmp2lag = cell(1, length(lagsxy));
            coltmplag = cell(1, length(lagsxy));
            r_dummy1 = cell(1, length(lagsxy));
            r_dummy2 = cell(1, length(lagsxy));
            cmp = cell(1, length(lagsxy));
            ccr = zeros(1, length(lagsxy));
            ccpv = zeros(1, length(lagsxy));

            lagcount = 0;
            for lxyi = 1:length(lagsxy) %finding ccr in seperate initial loop because of plot hold problem in plot loop below

                for lci = 1:length(lagscol) %finding ccr in seperate initial loop because of plot hold problem in plot loop below

                    lagcount = lagcount+1;


                    %first apply xy lag
                    if lagsxy(lxyi)<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
                        dtmptmp1 = vec(dattmp1(1+abs(lagsxy(lxyi)):end));
                        dtmptmp2 = vec(dattmp2(1:end-abs(lagsxy(lxyi))));
                    else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
                        dtmptmp1 = vec(dattmp1(1:end-abs(lagsxy(lxyi))));
                        dtmptmp2 = vec(dattmp2(1+abs(lagsxy(lxyi)):end));
                    end

                    %now apply 3rd variable lag (color lag, lagscol)
                    if lagscol(lci)<=0 %negative lag, first variable follows second (first var shifted left) (but should be opposite prob)
                        dtmp1 = vec(dtmptmp1(1+abs(lagscol(lci)):end));
                        dtmp2 = vec(dtmptmp2(1+abs(lagscol(lci)):end));
                        ctmp = vec(datcolor(1:end - (abs(lagsxy(lxyi))+abs(lagscol(lci))) )); %also include lagxy for 3rd var
                    else %positive lag first variable precedes second (first var shifted right) (but should be opposite prob)
                        dtmp1 = vec(dtmptmp1(1:end-abs(lagscol(lci))));
                        dtmp2 = vec(dtmptmp2(1:end-abs(lagscol(lci))));
                        ctmp = vec(datcolor( (1+abs(lagsxy(lxyi))+abs(lagscol(lci)) ) :end));
                    end


                    keepind = ~(isnan(dtmp1) | isnan(dtmp2));
                    ctmpisnan = isnan(ctmp);
                    if ~isempty(ctmpisnan)
                        keepind = keepind | ctmpisnan;
                        coltmplag{lagcount} = ctmp(keepind);
                    end
                    dattmp1lag{lagcount} = dtmp1(keepind);
                    dattmp2lag{lagcount} = dtmp2(keepind);
                    if isempty(ctmpisnan)
                        coltmplag{lagcount} = ones(length(dattmp1lag{lagcount}), 1);
                    end



                    if threshold_data
                        if strcmp('ballvel', labvarsvals{1})
                            [histdt, histx] = hist(abs(dattmp1lag{lagcount}(:)), 500);
                            thrbin = triangle_threshold(histdt, 'R', 0);
                            thrvel = histx(thrbin);
                            excludeinds = abs(dattmp1lag{lagcount})<thrvel;
                        elseif strcmp('ballvel', labvarsvals{2})
                            [histdt, histx] = hist(abs(dattmp2lag{lagcount}(:)), 500);
                            thrbin = triangle_threshold(histdt, 'R', 0);
                            thrvel = histx(thrbin);
                            excludeinds = abs(dattmp2lag{lagcount})<thrvel;
                        end
                        dattmp1lag{lagcount}(excludeinds) = [];
                        dattmp2lag{lagcount}(excludeinds) = [];
                        coltmplag{lagcount}(excludeinds) = [];
                    end


                    if isempty(datcolor) | (~isempty(datcolor) & do3d)
                        cmp{lagcount} = [0 0 1];
                    elseif ~isempty(datcolor) & ~do3d
                        [~, idx4] = sort(coltmplag{lagcount});
                        dattmp1lag{lagcount} = dattmp1lag{lagcount}(idx4);
                        dattmp2lag{lagcount} = dattmp2lag{lagcount}(idx4);
                        cmp{lagcount} = jet(length(idx4));
                    end

                    lbnd1 = 0.1;
                    ubnd2 = 0.45;
                    r_dummy1{lagcount} = lbnd1 + (ubnd2-lbnd1)*rand(size(dattmp1lag{lagcount}));
                    lbnd2 = 0.5;
                    ubnd2 = 0.85;
                    r_dummy2{lagcount} = lbnd2 + (ubnd2-lbnd2)*rand(size(dattmp2lag{lagcount}));

                    switch num2str(indpolar)
                        case ''
                            [ccr(lagcount) ccpv(lagcount)] = corr(dattmp1lag{lagcount}, dattmp2lag{lagcount}); %linear-linear
                            % [ccr(lagcount) ccpv(lagcount)] = corr(coltmplag{lagcount}, dattmp2lag{lagcount}); %linear-linear
                        case '1'
                            [ccr(lagcount) ccpv(lagcount)] = circ_corrcl(dattmp1lag{lagcount}, dattmp2lag{lagcount}); %circ-linear
                        case '2'
                            [ccr(lagcount) ccpv(lagcount)] = circ_corrcl(dattmp2lag{lagcount}, dattmp1lag{lagcount}); %circ-linear (and switch input order)
                        case '1  2'
                            [ccr(lagcount) ccpv(lagcount)] = circ_corrcc(dattmp1lag{lagcount}, dattmp2lag{lagcount}); %circ-circ
                    end
                end
            end

            lagcount = 0;
            for lxyi = 1:length(lagsxy) %finding ccr in seperate initial loop because of plot hold problem in plot loop below

                for lci = 1:length(lagscol) %finding ccr in seperate initial loop because of plot hold problem in plot loop below

                    lagcount = lagcount+1;
                    if lagcount==1

                        cind = 1;
                        rind = 1;
                        hax1 = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rind), wp, hp] );
                        hax1.PlotBoxAspectRatio = [1 1 1];

                        hbr = gobjects(numlags);
                        %cla()
                        hold on
                        siglev = 0.05;

                        for i = 1:numlags
                            hbr(i)=bar(lagsall(i),ccr(i));
                            pval_norm = siglev-ccpv(i);
                            if pval_norm<0
                                pval_norm = 0;
                            end
                            set(hbr(i), 'FaceColor', 'b', 'FaceAlpha', pval_norm);
                        end

                        %hbr = bar(hax1, laginds, ccr);

                        %hax1.XLim = [-maxlagxy - extrax1 maxlagxy + extrax1];
                        hax1.YLim = [-1 1];
                        hlin = xline(hax1, lagsall(lagcount), 'k');

                        cind = 1;
                        rind = 2;
                        hax2 = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rind), wp, hp] );

                        switch num2str(indpolar)
                            case ''
                                if do3d
                                    hsc1 = scatter3(hax2, dattmp1lag{lagcount}, dattmp2lag{lagcount}, coltmplag{lagcount}, mkrsz, cmp{lagcount}, 'filled');
                                else
                                    hsc1 = scatter(hax2, dattmp1lag{lagcount}, dattmp2lag{lagcount}, mkrsz, cmp{lagcount}, 'filled');
                                end
                            otherwise
                                hpax1 = polaraxes('Units', hax2.Units, 'Position', hax2.Position);
                                if isequal(indpolar, 1)
                                    hsc1 = polarscatter(hpax1, dattmp1lag{lagcount}, dattmp2lag{lagcount}, mkrsz, cmp{lagcount}, 'filled'); %switch input order
                                    hold(hpax1, 'on')
                                elseif isequal(indpolar, 2)
                                    hsc1 = polarscatter(hpax1, dattmp2lag{lagcount}, dattmp1lag{lagcount}, mkrsz, cmp{lagcount}, 'filled');
                                    hold(hpax1, 'on')
                                elseif isequal(indpolar, [1, 2])
                                    hsc1 = polarscatter(hpax1, dattmp1lag{lagcount}, r_dummy1{lagcount}, mkrsz, 'filled');
                                    hold(hpax1, 'on')
                                    hsc2 = polarscatter(hpax1, dattmp2lag{lagcount}, r_dummy2{lagcount}, mkrsz, 'filled');
                                end
                                hax2.YAxis.Visible = 'off';
                                hax2.XAxis.Visible = 'off';
                                %hpax1.RTickLabel = [];
                                %hsc3 = polarplot(hpax1, [-pi/12 -pi/12], [min(hsc1.RData) max(hsc1.RData)], 'r');

                                hpax1.RLim = [min(hsc1.RData) - range(hsc1.RData)*roomfac_x max(hsc1.RData) + range(hsc1.RData)*roomfac_x];
                                hsc3 = polarplot(hpax1, [-pi/12 -pi/12], hpax1.RLim, 'r');

                                hpax1.ThetaTick = [0 90 180 270];
                                hpax1.ThetaTickLabel = {'0', '', '180', ''};


                                hold(hpax1, 'on')

                        end
                        set(hax1,'box','off')
                        set(hax2,'box','off')
                        hax2.PlotBoxAspectRatio = [1 1 1];

                        hax1.XLabel.String = 'lag';
                        hax1.YLabel.String = 'corr coeff';
                        hax2.XLabel.String = labtmp1;
                        hax2.YLabel.String = labtmp2;
                        hax2.ZLabel.String = labcolor;

                    else

                        hlin.Value = lagsall(lagcount);

                        switch num2str(indpolar)
                            case ''
                                hsc1.XData = dattmp1lag{lagcount};
                                hsc1.YData = dattmp2lag{lagcount};
                                hsc1.CData = cmp{lagcount};
                                if do3d
                                    hsc1.ZData = coltmplag{lagcount};
                                end
                            case '1'
                                %hpax1.RTickLabel = [];
                                hsc1.ThetaData = dattmp1lag{lagcount};
                                hsc1.RData = dattmp2lag{lagcount};
                                hsc1.CData = cmp{lagcount};
                            case '2'
                                hpax1.RTickLabel = [];
                                hsc1.ThetaData = dattmp2lag{lagcount};
                                hsc1.RData = dattmp1lag{lagcount};
                                hsc1.CData = cmp{lagcount};
                            case '1  2'
                                hpax1.RTickLabel = [];
                                hsc1.ThetaData = dattmp1lag{lagcount};
                                hsc1.RData = r_dummy1{lagcount};
                                hsc2.ThetaData = dattmp2lag{lagcount};
                                hsc2.RData = r_dummy2{lagcount};
                        end


                    end

                    fig2gif(hfg, lagcount, fngif)

                    if do3d
                        saveas( gcf, [fngif(1:end-4) num2str(lagsxy(lxyi)) '_.fig'])
                    end

                end
            end
        end
        %close all

    end
end
