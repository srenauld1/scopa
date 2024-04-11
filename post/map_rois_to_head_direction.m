
function [resptmp, domain] = map_rois_to_head_direction(stack, fitin, ...
    roiinfo, md, fitopt, halfcent, numcluster_for_bump_domain_resample, resample_smoothfac, doplots)

resptmp = fitin.depvpre;

[~, ~, prefang] = fitmdl(stack, fitin, roiinfo, md, fitopt);

prefang = prefang{1}(:)';


%% resample functional domain

if numcluster_for_bump_domain_resample

    sprintf("resampling compass from " + num2str(size(resptmp, 1)) + " rois to " + num2str(halfcent*2) + " rois")

    if size(resptmp,1)<numcluster_for_bump_domain_resample*2
        sprintf("WARNING, \nREQUESTED RESAMPLE WITH MORE OUTPUT SAMPLES THAN INPUT SAMPLES")
    end

    %this resamples the compass into one circle but might be wrong
    angrange = 4*pi;
    [resptmp2, domain2] = resample_compass(resptmp, prefang, angrange, halfcent*2, resample_smoothfac, doplots);


    %this resamples each half of the compass, then puts them together
    rois_left = 1:size(resptmp, 1)/2;
    rois_right = size(resptmp, 1)/2+1:size(resptmp, 1);
    angrange = 2*pi;

    [dfc_left, domain_left] = resample_compass(resptmp(rois_left,:), prefang(rois_left), angrange, halfcent, resample_smoothfac, doplots);
    [dfc_right, domain_right] = resample_compass(resptmp(rois_right,:), prefang(rois_right), angrange, halfcent, resample_smoothfac, doplots);

    resptmp = cat(1, dfc_left, dfc_right);
    domain = [domain_left domain_right];


else

    domain = prefang;

end


if doplots

    %preferred heading plot
    figure;
    subplot(3,1,1)
    plot(prefang)
    ylim([-4 4])
    subplot(3,1,2)
    plot(mod(prefang, 2*pi))
    ylim([0 8])
    subplot(3,1,3)
    uwtmp = unwrap(mod(prefang, 2*pi));
    uwtmp = uwtmp - uwtmp(1);
    plot(uwtmp)
    ylim([0 16])
    saveas( gcf, [fitin.fn_save_prefix '_PREFHD_.png'])
    %%

    %resampled compass plot
    if numcluster_for_bump_domain_resample
        numtinds = 100;
        filename_save = [fitin.fn_save_prefix '_RESAMPCOMP_.gif'];
        hfg = figure;
        hax = axes( 'Parent', hfg); %make the subplot
        framecount_gif = 0;
        for ind = round(linspace(1, size(resptmp, 2), numtinds))
            framecount_gif = framecount_gif + 1;

            if framecount_gif==1
                hpl1 = plot(hax, 1:size(resptmp, 1), resptmp(:,ind));
                hold(hax, 'on');
                hpl2 = plot(hax, 1:size(resptmp2, 1), resptmp2(:,ind));
                yyaxis right;
                hpl3 = plot(hax, linspace(1, size(resptmp, 1), size(fitin.depvpre, 1)), fitin.depvpre(:,ind));
                hold(hax, 'off');
            else
                hpl1.YData = resptmp(:,ind);
                hpl2.YData = resptmp2(:,ind);
                hpl3.YData = fitin.depvpre(:,ind);

            end

            fig2gif(hfg, framecount_gif, filename_save)


        end
    end
    %%

end


