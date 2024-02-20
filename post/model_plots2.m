
function model_plots(hsvmap, respin_nan, predresp_nan, predresp_nan_sort, ...
    modeltype, lenfit_sec, lenfit_samp, ...
    lag_samp, epochinds, epochind_for_top, filename_in, ...
    figsz, fontsmall, fontmedium, fontlarge, fonthuge, plotinds, ...
    numzslice, numrows, numrowsplit, ...
    xp, yp, wp, hp, img, roiinds, cmap_im, quivercenter_xy, ...
    quivermaxlen, roipixvals_edges, roipixvals_binned, ...
    minstimraw, axroomstim, maxstimraw, plot_inds_t, ...
    stimauge, stimauge_sort, ncol, gif_visibility, ...
    numcols, hueshift, hsv_background, plot_3d)

numhue = 256; %arbitrary
hueshift_rs = interp1([0 1], [0 numhue-1], hueshift);
cmaphsv = colormap( circshift( hsv(numhue), -hueshift_rs, 1 ) ); %colormap( hsv( ceil( max( hRange ) ) ) );
cmapgray = colormap(gray(numhue));
img = rescale(img, 1, numhue);

size_imgnew = [size(img, 1)  size(img, 2)  size(img, 3) 3];
imgnew = zeros(size_imgnew); %specify size(img, 3) in case it's 1
for si = 1:size(img, 3)
    imgnew(:,:,si,:) = ind2rgb(uint8(img(:,:,si)), cmapgray);
end
imgnew = reshape(imgnew, [], size(imgnew, 4));

switch hsv_background
    case 'pixels'
        for ri = 1:length(plotinds)
            imgnew(roiinds{plotinds(ri)}, :) = hsv2rgb( hsvmap(plotinds(ri), :) );
        end
    case 'rois'
        imgnew = repmat(imgnew, [ones(1, ndims(imgnew)) length(plotinds)]);
        for ri = 1:length(plotinds)
            rgbmap = hsv2rgb( hsvmap(plotinds(ri), :));
            rgbmap = repmat(rgbmap, [numel(roiinds{plotinds(ri)}) 1]);
            imgnew(roiinds{plotinds(ri)}, :, ri) = rgbmap;
        end
    case 'raw'

end

imgnew = reshape(imgnew, [size_imgnew, size(imgnew, ndims(imgnew))]);


%colorbar;
%freezeColors;
% if firstplot
%     cbfreeze( colorbar );
% end

title_add_all = [modeltype '_' num2str(lenfit_sec) 'sec' num2str(lenfit_samp) 'samp_' num2str(lag_samp) 'samplag' ];
ind_epochind_for_top = find(cellfun(@isequal,epochinds(:),repmat({epochind_for_top},length(epochinds),1)));



title_add_each = 'MODELFIT';
figext = '.gif';
filename_save = [filename_in(1:end-4) '_' title_add_all '_' title_add_each '_' figext];
tittmp = strsplit(filename_save(1:end-4), '/');
figure_title = {strrep(tittmp{end}, '_', ' ')};

hfg = figure( 'Units', 'normalized', 'Position', ones(1,4)*figsz, ...
    'Color', 'white', 'visible', gif_visibility) ;
bgAxes = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
    'XLim', [0, 1], 'YLim', [0, 1] ) ;
text( 0.02, 0.99, figure_title, 'FontSize', fontmedium, ...
    'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;


rind_with_title = 2; %row with titles
plotframecount = 0;
for ri = 1:length(plotinds)
    for zi = 1:numzslice
        plotframecount = plotframecount + 1;

        for rind = 1:numrows/numrowsplit

            epi = rind - 1;

            rindo = rind+rind-1; %odds
            rinde = rind+rind; %evens
            spco = [1:numcols]+numcols*(rinde-1);
            spce = [1:numcols]+numcols*(rinde-1);

            if plotframecount==1

                if rind==1 %bottom plots common to all epochs

                    cind = 1;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp*2, hp*2] );
                    hold(hax{spce(cind)}, 'on');


                    hpl{spce(cind)} = imshow(round(img(:,:,zi,plotinds(ri))), cmap_im, 'border', 'tight'); %round because imshow will take floor if passing a cmap
                    axis image
                    title(hax{spce(cind)}, ['roi ' num2str(roi_indices(plotinds(ri))) '    ' num2str(rcor(plotinds(ri)), '%.2f') ' / ' num2str(rsnr(plotinds(ri)), '%.2f') '    (sp. cor / snr) '], 'fontsize', fontlarge); %model-extracted feature (predresp) tuning for raw stim
                    hold(hax{spce(cind)}, 'off');


                    cind = 3;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    hold(hax{spce(cind)}, 'on');
                    if stim_is_circular | strcmp(fit_method, 'complex')
                        viscircles(hax{spce(cind)}, quivercenter_xy, quivermaxlen, 'color', 'k', 'linewidth', supp_line_width);
                        line([quivercenter_xy(1) quivercenter_xy(1)+quivermaxlen], [quivercenter_xy(2) quivercenter_xy(2)], 'color', 'k', 'linewidth', supp_line_width);
                        qx = ones(1, lenfit_samp_upsamp)*quivercenter_xy(1);
                        qy = ones(1, lenfit_samp_upsamp)*quivercenter_xy(2);
                        qu = gof{ind_epochind_for_top}(plotinds(ri))*cos(smrinterp{ind_epochind_for_top}(1,:,plotinds(ri)));
                        qv = gof{ind_epochind_for_top}(plotinds(ri))*sin(smrinterp{ind_epochind_for_top}(1,:,plotinds(ri)));
                        hpl{spce(cind)} = quiver(hax{spce(cind)}, qx,qy,qu,qv,0, "LineWidth", 2, 'color', [0 0 1]);
                        if size(smrinterp{ind_epochind_for_top}, 2)~=1 %if model length is not 1, plot the last coefficient in time also
                            qu = gof{ind_epochind_for_top}(plotinds(ri))*cos(smrinterp{ind_epochind_for_top}(1,end,plotinds(ri)));
                            qv = gof{ind_epochind_for_top}(plotinds(ri))*sin(smrinterp{ind_epochind_for_top}(1,end,plotinds(ri)));
                            hpl2{spce(cind)} = quiver(hax{spce(cind)}, quivercenter_xy(1),quivercenter_xy(2),qu,qv,0, "LineWidth", 2, 'color', [1 0 0]);
                        end
                        xlim([quivercenter_xy(1) - quivermaxlen quivercenter_xy(2) + quivermaxlen])
                        xlim([quivercenter_xy(1) - quivermaxlen quivercenter_xy(2) + quivermaxlen])
                        axis equal
                        axis off
                        hold(hax{spce(cind)}, 'off');
                    else
                        hpl{spce(cind)} = plot(hax{spce(cind)}, stim_at_max_resp{ind_epochind_for_top}(1, :, plotinds(ri)));
                        hax{spce(cind)}.XLim = [0 size(stim_at_max_resp{ind_epochind_for_top}, 2)];
                        hax{spce(cind)}.YLim = [minstimraw - axroomstim maxstimraw + axroomstim];
                    end
                    if rind==rind_with_title
                        title(hax{spce(cind)}, 'prefstim', 'fontsize', fontsmall); %model-extracted feature (predresp) tuning for raw stim
                    end
                    hold(hax{spce(cind)}, 'off');



                    cind = 4;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    set(gca,'color','none')
                    hax{spce(cind)}.XAxis.Visible='off';
                    hax{spce(cind)}.YAxis.Visible='off';
                    texbox_xy = [0.3 0.6]; %relative to subplot
                    textinsertnew = cat(2, {'R2 (epoch)'}, textinsert{plotinds(ri)});
                    hpl{spce(cind)} = text(hax{spce(cind)},  texbox_xy(1), texbox_xy(2), ...
                        textinsertnew, 'FontSize', fonthuge, ...
                        'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;


                    cind = 5;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    hpl{spce(cind)} = bar(hax{spce(cind)}, roipixvals_edges{plotinds(ri)}, roipixvals_binned{plotinds(ri)}, 'FaceColor', [0 0 1]);
                    title(hax{spce(cind)}, ['pixel energy (numpix ' num2str(roinumpix(plotinds(ri))) ')'], 'fontsize', fontmedium); %model-extracted feature (predresp) tuning for raw stim




                else %then epoch-specific plots

                    cind = 1;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    hold(hax{spce(cind)}, 'on');
                    hpl{spce(cind)} = scatter(hax{spce(cind)}, respin_nan{epi}( :, plotinds(ri)), predresp_nan{epi}( :, plotinds(ri)), 5, 'filled');
                    hpl2{spce(cind)} = plot(respin_nan{epi}( :, plotinds(ri)), respin_nan{epi}( :, plotinds(ri)), 'k');
                    xline(hax{spce(cind)}, 0)
                    yline(hax{spce(cind)}, 0)
                    minis = min([min(respin_nan{epi}( :, plotinds(ri))), min(predresp_nan{epi}( :, plotinds(ri)))]);
                    maxis = max([max(respin_nan{epi}( :, plotinds(ri))), max(predresp_nan{epi}( :, plotinds(ri)))]);

                    hax{spce(cind)}.XLim = [minis maxis];
                    xlm = hax{spce(cind)}.XLim;
                    hax{spce(cind)}.XAxis.TickValues = linspace(xlm(1), xlm(2), 3);
                    hax{spce(cind)}.XAxis.TickLabelFormat = '%.1f';
                    hax{spce(cind)}.XAxis.FontSize = fontsmall;

                    hax{spce(cind)}.YLim = [minis maxis];
                    ylm = hax{spce(cind)}.YLim;
                    hax{spce(cind)}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hax{spce(cind)}.YAxis.TickLabelFormat = '%.1f';
                    hax{spce(cind)}.YAxis.FontSize = fontsmall;

                    if rind==numrows/numrowsplit
                        xlabel('resp')
                    else
                        hax{spce(cind)}.XAxis.Visible='off';
                    end
                    % ylabel('pred')
                    if rind==rind_with_title
                        title(hax{spce(cind)}, 'pred vs resp', 'fontsize', fontsmall); %model-extracted feature (predresp) tuning for raw stim
                    end
                    hold(hax{spce(cind)}, 'off');


                    cind = 2;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    hold(hax{spce(cind)}, 'on');
                    hpl{spce(cind)} = plot(hax{spce(cind)}, respin_nan{epi}( plot_inds_t{epi}, plotinds(ri)), 'color', [0 0 1]);
                    hpl2{spce(cind)} = plot(hax{spce(cind)}, predresp_nan{epi}( plot_inds_t{epi}, plotinds(ri)), 'color', [1 0 0]);
                    yline(hax{spce(cind)}, 0)

                    hax{spce(cind)}.YLim = [minis maxis];
                    ylm = hax{spce(cind)}.YLim;
                    hax{spce(cind)}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hax{spce(cind)}.YAxis.TickLabelFormat = '%.1f';
                    hax{spce(cind)}.YAxis.FontSize = fontsmall;

                    if rind==numrows/numrowsplit
                        xlabel('time (sec)')
                    else
                        hax{spce(cind)}.XAxis.Visible='off';
                    end
                    hax{spce(cind)}.YAxis.Visible='off';
                    % ylabel('dff')
                    if rind==rind_with_title
                        title(hax{spce(cind)}, ['pred(r) resp (b) ' truncstr], 'fontsize', fontsmall); %model-extracted feature (predresp) tuning for raw stim
                    end
                    hold(hax{spce(cind)}, 'off');


                    cind = 3;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    hold(hax{spce(cind)}, 'on');
                    hpl{spce(cind)} = scatter(hax{spce(cind)}, stimauge{epi}, respin_nan{epi}(:,plotinds(ri)), 5, 'filled');
                    hpl2{spce(cind)} = plot(hax{spce(cind)}, stimauge_sort{epi}, predresp_nan_sort{epi}(:,plotinds(ri)));
                    yline(hax{spce(cind)}, 0)

                    hax{spce(cind)}.YLim = [minis maxis];
                    ylm = hax{spce(cind)}.YLim;
                    hax{spce(cind)}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                    hax{spce(cind)}.YAxis.TickLabelFormat = '%.1f';
                    hax{spce(cind)}.YAxis.FontSize = fontsmall;
                    % ylim([minallall maxallall])
                    if rind==numrows/numrowsplit
                        xlabel('stim sorted')
                    else
                        hax{spce(cind)}.XAxis.Visible='off';
                    end
                    hax{spce(cind)}.YAxis.Visible='off';
                    % ylabel('dff')
                    if rind==rind_with_title
                        title(hax{spce(cind)}, 'resp vs stimlag', 'fontsize', fontsmall); %raw resp tuning for raw stim raw, response vs raw stim, doesn't include any invalid first indices in resp (if model samples>1)
                    end
                    hold(hax{spce(cind)}, 'off');


                    cind = 4;
                    hax{spce(cind)} = axes( 'Parent', hfg, 'Position', [xp(cind), yp(rinde), wp, hp*2] );
                    hold(hax{spce(cind)}, 'on');
                    if stim_is_circular | strcmp(fit_method, 'complex')
                        viscircles(hax{spce(cind)}, quivercenter_xy, quivermaxlen, 'color', 'k', 'linewidth', supp_line_width);
                        line([quivercenter_xy(1) quivercenter_xy(1)+quivermaxlen], [quivercenter_xy(2) quivercenter_xy(2)], 'color', 'k', 'linewidth', supp_line_width);
                        qx = ones(1, lenfit_samp_upsamp)*quivercenter_xy(1);
                        qy = ones(1, lenfit_samp_upsamp)*quivercenter_xy(2);
                        qu = gof{epi}(plotinds(ri))*cos(smrinterp{epi}(1,:,plotinds(ri)));
                        qv = gof{epi}(plotinds(ri))*sin(smrinterp{epi}(1,:,plotinds(ri)));
                        hpl{spce(cind)} = quiver(hax{spce(cind)}, qx,qy,qu,qv,0, "LineWidth", 2, 'color', [0 0 1]);
                        if size(smrinterp{epi}, 2)~=1 %if model length is not 1, plot the last coefficient in time also
                            qu = gof{epi}(plotinds(ri))*cos(smrinterp{epi}(1,end,plotinds(ri)));
                            qv = gof{epi}(plotinds(ri))*sin(smrinterp{epi}(1,end,plotinds(ri)));
                            hpl2{spce(cind)} = quiver(hax{spce(cind)}, quivercenter_xy(1),quivercenter_xy(2),qu,qv,0, "LineWidth", 2, 'color', [1 0 0]);
                        end
                        xlim([quivercenter_xy(1) - quivermaxlen quivercenter_xy(2) + quivermaxlen])
                        xlim([quivercenter_xy(1) - quivermaxlen quivercenter_xy(2) + quivermaxlen])
                        axis equal
                        axis off
                        hold(hax{spce(cind)}, 'off');
                    else
                        hpl{spce(cind)} = plot(hax{spce(cind)}, stim_at_max_resp{epi}(1, :, plotinds(ri)));
                        hax{spce(cind)}.XLim = [0 size(stim_at_max_resp{epi}, 2)];
                        hax{spce(cind)}.YLim = [minstimraw - axroomstim maxstimraw + axroomstim];
                    end
                    if rind==rind_with_title
                        title(hax{spce(cind)}, 'prefstim', 'fontsize', fontsmall); %model-extracted feature (predresp) tuning for raw stim
                    end
                    hold(hax{spce(cind)}, 'off');

                end

            else



                if rind==1

                    cind = 1;
                    hax{spce(cind)}.Title.String = ['roi ' num2str(roi_indices(plotinds(ri))) '    ' num2str(rcor(plotinds(ri)), '%.2f') ' / ' num2str(rsnr(plotinds(ri)), '%.2f') '    (sp. cor / snr) '];
                    hpl{spce(cind)}.CData = round(img(:,:,zi,plotinds(ri))); %round because imshow will take floor if passing a cmap


                    if zi==1

                        cind = 3;
                        if stim_is_circular | strcmp(fit_method, 'complex')
                            hpl{spce(cind)}.UData = gof{ind_epochind_for_top}(plotinds(ri))*cos(smrinterp{ind_epochind_for_top}(1,:,plotinds(ri)));
                            hpl{spce(cind)}.VData = gof{ind_epochind_for_top}(plotinds(ri))*sin(smrinterp{ind_epochind_for_top}(1,:,plotinds(ri)));
                            if size(smrinterp{ind_epochind_for_top}, 2)~=1 %if model length is not 1, plot the last coefficient in time also
                                hpl2{spce(cind)}.UData = gof{ind_epochind_for_top}(plotinds(ri))*cos(smrinterp{ind_epochind_for_top}(1,end,plotinds(ri)));
                                hpl2{spce(cind)}.VData = gof{ind_epochind_for_top}(plotinds(ri))*sin(smrinterp{ind_epochind_for_top}(1,end,plotinds(ri)));
                            end
                        else
                            hpl{spce(cind)}.YData = stim_at_max_resp{ind_epochind_for_top}(1, :, plotinds(ri));
                        end


                        cind = 4;
                        textinsertnew = cat(2, {'R2 (epoch)'}, textinsert{plotinds(ri)});
                        hpl{spce(cind)}.String = textinsertnew;


                        cind = 5;
                        hax{spce(cind)}.Title.String = ['pixel energy (numpix ' num2str(roinumpix(plotinds(ri))) ')'];
                        hpl{spce(cind)}.XData = roipixvals_edges{plotinds(ri)};
                        hpl{spce(cind)}.YData = roipixvals_binned{plotinds(ri)};

                    end

                else

                    if zi==1

                        cind = 1;
                        hpl{spce(cind)}.XData = respin_nan{epi}(:,plotinds(ri));
                        hpl{spce(cind)}.YData = predresp_nan{epi}(:,plotinds(ri));
                        hpl2{spce(cind)}.XData = respin_nan{epi}(:,plotinds(ri));
                        hpl2{spce(cind)}.YData = respin_nan{epi}(:,plotinds(ri));

                        minis = min([min(respin_nan{epi}( :, plotinds(ri))), min(predresp_nan{epi}( :, plotinds(ri)))]);
                        maxis = max([max(respin_nan{epi}( :, plotinds(ri))), max(predresp_nan{epi}( :, plotinds(ri)))]);
                        hax{spce(cind)}.YLim = [minis maxis];
                        ylm = hax{spce(cind)}.YLim;
                        hax{spce(cind)}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                        hax{spce(cind)}.YAxis.TickLabelFormat = '%.1f';
                        hax{spce(cind)}.YAxis.FontSize = fontsmall;



                        cind = 2;
                        hpl{spce(cind)}.YData = respin_nan{epi}(plot_inds_t{epi},plotinds(ri));
                        hpl2{spce(cind)}.YData = predresp_nan{epi}(plot_inds_t{epi},plotinds(ri));

                        hax{spce(cind)}.YLim = [minis maxis];
                        ylm = hax{spce(cind)}.YLim;
                        hax{spce(cind)}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                        hax{spce(cind)}.YAxis.TickLabelFormat = '%.1f';
                        hax{spce(cind)}.YAxis.FontSize = fontsmall;


                        cind = 3;
                        hpl{spce(cind)}.XData = stimauge{epi};
                        hpl{spce(cind)}.YData = respin_nan{epi}(:,plotinds(ri));
                        hpl2{spce(cind)}.XData = stimauge_sort{epi};
                        hpl2{spce(cind)}.YData = predresp_nan_sort{epi}(:,plotinds(ri));

                        hax{spce(cind)}.YLim = [minis maxis];
                        ylm = hax{spce(cind)}.YLim;
                        hax{spce(cind)}.YAxis.TickValues = linspace(ylm(1), ylm(2), 3);
                        hax{spce(cind)}.YAxis.TickLabelFormat = '%.1f';
                        hax{spce(cind)}.YAxis.FontSize = fontsmall;


                        cind = 4;
                        if stim_is_circular | strcmp(fit_method, 'complex')
                            hpl{spce(cind)}.UData = gof{epi}(plotinds(ri))*cos(smrinterp{epi}(1,:,plotinds(ri)));
                            hpl{spce(cind)}.VData = gof{epi}(plotinds(ri))*sin(smrinterp{epi}(1,:,plotinds(ri)));
                            if size(smrinterp{epi}, 2)~=1 %if model length is not 1, plot the last coefficient in time also
                                hpl2{spce(cind)}.UData = gof{epi}(plotinds(ri))*cos(smrinterp{epi}(1,end,plotinds(ri)));
                                hpl2{spce(cind)}.VData = gof{epi}(plotinds(ri))*sin(smrinterp{epi}(1,end,plotinds(ri)));
                            end
                        else
                            hpl{spce(cind)}.YData = stim_at_max_resp{epi}(1, :, plotinds(ri));
                        end



                    end
                end
            end
        end

        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,ncol);

        if plotframecount==1
            imwrite(imind,cm,filename_save, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filename_save,'DelayTime', 0,'WriteMode','append');
        end


    end
end





if 0

    title_add_each = 'resp_stimlag';
    figext = '.gif';
    filename_save = [filename_in(1:end-4) '_' title_add_all '_' title_add_each '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = {strrep(tittmp{end}, '_', ' ')};

    hfg = figure( 'Units', 'normalized', 'Position', ones(1,4)*figsz, ...
        'Color', 'white', 'visible', gif_visibility) ;
    bgAxes = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', ...
        'XLim', [0, 1], 'YLim', [0, 1] ) ;
    text( 0.1, 0.99, figure_title, 'FontSize', fontsmall, ...
        'HorizontalAlignment', 'left', 'FontWeight', 'bold' ) ;

    num_alternate_frame = 2;
    for frameind = 1:length(epochinds)*num_alternate_frame
        epi = ceil(frameind / num_alternate_frame);
        for ri = 1:length(plotinds)
            ri_cor = mod(numrows_auto*(ri-1)+1, numrows_auto*numcols_auto) + floor((ri-1)/numcols_auto); %convert column major linear index to row major linear index
            [sfm,sfn] = ind2sub([numrows_auto numcols_auto], ri_cor);
            if frameind==1
                hax{sfm,sfn} = axes( 'Parent', hfg, 'Position', sfpos(sfm,:,sfn) );
                hpl{sfm, sfn} = scatter(hax{sfm,sfn}, stimauge{epi}, respin_nan{epi}(:,plotinds(ri)), 5, 'filled');
                hpl{sfm, sfn}.CData = [0 0 1];
                ylim([minrespinall maxrespinall])
                set(gca,'XTick',[])
                set(gca,'YTick',[])
                axis off
            else
                if mod(frameind, num_alternate_frame)==1
                    hpl{sfm, sfn}.XData = stimauge{epi};
                    hpl{sfm, sfn}.YData = respin_nan{epi}(:,plotinds(ri));
                    hpl{sfm, sfn}.CData = [0 0 1];
                elseif mod(frameind, num_alternate_frame)==0
                    hpl{sfm, sfn}.XData = stimauge_sort{epi};
                    hpl{sfm, sfn}.YData = predresp_nan_sort{epi}(:,plotinds(ri));
                    hpl{sfm, sfn}.CData = [1 0 0];
                end

            end
        end

        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,ncol);

        if frameind==1
            imwrite(imind,cm,filename_save, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filename_save,'DelayTime', 0,'WriteMode','append');
        end


    end


    title_add_each = 'resp_or_predresp_stimlag';
    figext = '.png';
    filename_save = [filename_in(1:end-4) '_' title_add_all '_' title_add_each '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = {strrep(tittmp{end}, '_', ' ')};

    hfg = figure;
    num_alternate_plots = 2;
    for subplotind = 1:length(epochinds)*num_alternate_plots
        epi = ceil(subplotind / num_alternate_plots);
        if mod(subplotind, num_alternate_plots)==1
            hax{subplotind} = subplot(length(epochinds), num_alternate_plots, subplotind);
            scatter(hax{subplotind}, stimauge{epi}, respin_nan{epi}, 2, 'filled');
        elseif mod(subplotind, num_alternate_plots)==0
            hax{subplotind} = subplot(length(epochinds), num_alternate_plots, subplotind);
            scatter(hax{subplotind}, stimauge_sort{epi}, predresp_nan_sort{epi}, 2, 'filled');
        end
    end
    sgtitle(figure_title, 'fontsize', fontsmall); %raw resp tuning for model-extracted feature (predresp) , raw response vs predresp (model-transformed stim), doesn't include any invalid first indices in resp (if model samples>1)
    saveas( hfg, filename_save)





    title_add_each = 'resp_pred';
    figext = '.gif';
    filename_save = [filename_in(1:end-4) '_' title_add_all '_' title_add_each '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = {strrep(tittmp{end}, '_', ' ')};

    hfg = figure;
    for epi = 1:length(epochinds)

        scatter(respin_nan{epi}, predresp_nan{epi}, 1, 'filled');
        xlim([minallall - axroomrespall  maxallall + axroomrespall])
        ylim([minallall - axroomrespall  maxallall + axroomrespall])
        xline(0)
        yline(0)
        axis square
        title(figure_title, 'fontsize', fontsmall)

        frame = getframe(hfg);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,ncol);

        if epi==1
            imwrite(imind,cm,filename_save, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filename_save,'DelayTime', 0,'WriteMode','append');
        end


    end


    title_add_each_all = {'prefstim', 'prefstim_cnt', 'prefstim_cnt_sort'};

    for multi_fig_loop_ind = 1:3

        title_add_each = title_add_each_all{multi_fig_loop_ind};
        figext = '.gif';
        filename_save = [filename_in(1:end-4) '_' title_add_all '_' title_add_each '_' figext];
        tittmp = strsplit(filename_save(1:end-4), '/');
        figure_title = {strrep(tittmp{end}, '_', ' ')};

        hfg = figure;
        for epi = 1:length(epochinds)

            switch multi_fig_loop_ind
                case 1
                    hpl = polarscatter(stim_at_max_resp{epi}(:), r_dummy_all(:), mkrsz, cmp_upsamp_allrois, 'filled'); %switch input order
                case 2
                    hpl = polarscatter(smrinterpcnt{epi}(:), r_dummy_all(:), mkrsz, cmp_upsamp_allrois, 'filled'); %switch input order
                case 3
                    hpl = polarscatter(smrinterpcnt_sort{epi}(:), r_dummy_all(:), mkrsz, cmp_upsamp_allrois, 'filled'); %switch input order
            end

            hpl.Parent.RLim = [0 length(plotinds)*3-1];
            hpl.Parent.RTick = [];
            hpl.Parent.ThetaTick = [0];
            hpl.Parent.ThetaTickLabel = {'0', '', '180', ''};

            title(figure_title, 'fontsize', fontsmall)

            frame = getframe(hfg);
            im = frame2im(frame);
            [imind, cm] = rgb2ind(im,ncol);

            if epi==1
                imwrite(imind,cm,filename_save, 'DelayTime', 0, 'Loopcount',inf);
            else
                imwrite(imind,cm,filename_save,'DelayTime', 0,'WriteMode','append');
            end


        end


        delete(hfg)

    end

end

close all



