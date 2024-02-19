

function cx_plot_bump_and_image(dosort, numgifframes, ...
    muplot, md, pltind1, centinds, dff_cluster, ...
    rhoplot, filenameGIF, ncol, maskx, masky, tmpnew, makeroomfac_rho, ...
    makeroomfac_mu, muasnum, halfcent)


    nc = 256;

    Rc = linspace(0,1,nc);  %// Red from 1 to 0
    Bc = zeros(size(Rc));  %// Blue from 0 to 1
    Gc = linspace(0,1,nc);   %// Green all zero

    cm1 = [Rc(:), Gc(:), Bc(:)];  %// create colormap

    plotcolz = {'b', 'g', 'y', 'm'};

    firstind = 1;
    lastind = 100;
   
    if dosort
        [~, indz] = sort(muplot(:,pltind1));
        %xf2 = md.ti(indz);
    else
        [~,idd1] = min(abs(md.ti-firstind));
        [~,idd2] = min(abs(md.ti-lastind));
        indz = idd1:idd2;
    end

    h = figure;

    for ii = round(linspace(1, length(indz), numgifframes))

        ax1 = subplot(4,3,1);
        plot(dff_cluster(centinds{pltind1}, indz(ii)), plotcolz{pltind1})
        hold(ax1, 'on')
        xline(muasnum(pltind1,indz(ii)), plotcolz{pltind1})
        xline(muasnum(pltind1,indz(ii))+halfcent, plotcolz{pltind1})
        if ~dosort
            if plot_two_metrics
                plot(dff_cluster(centinds{pltind2}, indz(ii)), plotcolz{pltind2})
                xline(muasnum(pltind2,indz(ii)), plotcolz{pltind2})
            end
        end
        ylim([min(dff_cluster(:)) max(dff_cluster(:))])
        xlabel("glomeruli (oversampled)")
        title("DFF (PVA = vertical line) ", 'FontSize',6)
        %    title("DFF in right PB (red) vs left PB (black) - PVA = vertical line ", 'FontSize',6)
        hold(ax1, 'off')

        ax2 = subplot(4,3,2);
        hold(ax2, 'on')
        if dosort
            plot(md.ti, muplot(indz, pltind1), plotcolz{pltind1}, 'Marker', 'none');
            h11 = xline(md.ti(ii), 'k');
        else
            plot(md.ti(indz), muplot(indz, pltind1), plotcolz{pltind1}, 'Marker', 'none');
            if plot_two_metrics
                plot(md.ti(indz), muplot(indz, pltind2), plotcolz{pltind2}, 'Marker', 'none');
            end
            xlim([md.ti(indz(1)) md.ti(indz(end))])
            h11 = xline(md.ti(indz(ii)), 'k');
        end
        ylim([-5 5])
        xlabel("seconds")
        title("PVA", 'FontSize',6)
        %    title("PVA in right PB (red) vs left PB (black)", 'FontSize',6)
        hold(ax2, 'off')

        ax3 = subplot(4,3,3);
        hold(ax3, 'on')

        yyaxis left
        if dosort
            plot(md.ti, -unwrap(muplot(indz, pltind1)), plotcolz{pltind1}, 'Marker', 'none');
            h12 = xline(md.ti(ii), 'k');
        else
            plot(md.ti(indz), -unwrap(muplot(indz, pltind1)), plotcolz{pltind1}, 'Marker', 'none');
            if plot_two_metrics
                plot(md.ti(indz), -unwrap(muplot(indz, pltind2)), plotcolz{pltind2}, 'Marker', 'none');
                %plot(md.ti(indz), -unwrap(muplot(indz, pltind3)), plotcolz{pltind3}, 'Marker', 'none');
            end
            xlim([md.ti(indz(1)) md.ti(indz(end))])
            h12 = xline(md.ti(indz(ii)), 'k');
        end
        ylim([min(vec(-unwrap(muplot(indz, :))))*makeroomfac_mu max(vec(-unwrap(muplot(indz, :))))])

        yyaxis right
        if ~dosort
            plot(md.ti(indz), rhoplot(indz, pltind1), plotcolz{pltind1}, 'Marker', 'none', 'LineStyle', '--');
            if plot_two_metrics
                plot(md.ti(indz), rhoplot(indz, pltind2), plotcolz{pltind2}, 'Marker', 'none');
            end
        end
        ylim([0 1 * makeroomfac_rho])
        title("unwrapped PVA (rho = dashed)", 'FontSize',6)
        %    title("unwrapped PVA in right PB (red) vs left PB (black)", 'FontSize',6)
        xlabel("seconds")
        hold(ax3, 'off')

        for sp2i = 1:size(tmpnew,3)
            subplot(4,3,sp2i+3);
            imshow(tmpnew(:,:,sp2i,indz(ii)),"InitialMagnification","fit")
            xlim([min(maskx) max(maskx)])
            ylim([min(masky) max(masky)])
            colormap(cm1)
        end


        frame = getframe(h);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im,ncol);

        if ii == 1
            imwrite(imind,cm,filenameGIF, 'DelayTime', 0, 'Loopcount',inf);
        else
            imwrite(imind,cm,filenameGIF,'DelayTime', 0,'WriteMode','append');
        end
        delete(h11)
        delete(h12)
    end
