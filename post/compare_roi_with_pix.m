function compare_roi_with_pix(respfit, stackcrop, pixinds_fit, pthgif_prefix)

ncol = 256;

pthgif = [pthgif_prefix(1:end-4) '_pix_v_roi_.gif'];


tindies = 1:1000;

stackcrop = reshape(stackcrop, [], size(stackcrop, 4));

hfg = figure;
hax = axes( 'Parent', hfg);
first = 1;
for rfi = 1:size(respfit, 1)
    respfit2 = stackcrop(pixinds_fit{rfi}, :);
    ymin = min([respfit(:); respfit2(:)]);
    ymax = max([respfit(:); respfit2(:)]);
    for rf2i = 1:size(respfit2, 1)

        if first
            first = 0;
            hold(hax, 'on')
            p1 = plot(hax, respfit(rfi,tindies), 'b');
            p2 = plot(hax, respfit2(rf2i, tindies), 'r');
            ylim([ymin ymax])
        else
            hax.YLim = [ymin ymax];
            p1.YData = respfit(rfi,tindies);
            p2.YData = respfit2(rf2i,tindies);

        end


        fig2gif(hfg, rf2i, pthgif)

    end
end