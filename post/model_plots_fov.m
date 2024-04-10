function model_plots_fov


%%  FOV PLOT ONLY


if doplots(2)

    title_add_each = 'FOV';
    figext = '.gif';
    filename_save = [pth_fitdata_prefix '_' title_add_each '_' figext];
    tittmp = strsplit(filename_save(1:end-4), '/');
    figure_title = {strrep(tittmp{end}, '_', ' ')};


    hfg = figure( 'Units', 'Normalized', 'WindowState', 'fullscreen') ;

    framecount = 0;
    zslicecount = 0;
    for sit = 1:numplotstop
        framecount = framecount+1;

        [cit, rit] = ind2sub([numrowstop, numcolumnstop], sit); %reverse output since subplots are column-major
        zslicecount = zslicecount+1;


        if zslicecount<size(img{epi}, 3)+1
            hat{sit} = axes( 'Parent', hfg, 'Position', [0 0 1 1] );
            hold(hat{sit}, 'on');
            switch hsv_background
                case 'pixels'
                    hp1t{sit} = image(hat{sit}, squeeze(img{epi}(:,:,zslicecount,:)));
                case 'rois'
                    hp1t{sit} = image(hat{sit}, squeeze(img{epi}(:,:,zslicecount,:,ri)));
            end
            axis image % should not have to call axis image because of how subfig width/height were calculated to maintain aspect ratio above
            axis off
            axis ij
        end

        fig2gif(hfg, framecount, filename_save)


    end
end