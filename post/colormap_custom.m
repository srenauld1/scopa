function cmap = colormap_custom(method, ncol_each, ...
    startcol1, endcol1, saturation_factor1, ...
    startcol2, endcol2, saturation_factor2)

switch method
    case '1d'
        
        %1d interp (linspace) makes straight line from first color
        % to center of 2d colorwheel (white), then to next color
        cmap1 = repmat(endcol1, [ncol_each 1]);
        ncol_adj_bg = round(ncol_each*saturation_factor1);
        rr = linspace(startcol1(1),endcol1(1),ncol_adj_bg);
        gg = linspace(startcol1(2),endcol1(2),ncol_adj_bg);
        bb = linspace(startcol1(3),endcol1(3),ncol_adj_bg);
        cmap1(1:length(rr),:) = [rr(:), gg(:), bb(:)];

        if exist('startcol2', 'var') & exist('endcol2', 'var')
            cmap2 = repmat(endcol2, [ncol_each 1]);
            ncol_adj_roi = round(ncol_each*saturation_factor2);
            rr = linspace(startcol2(1),endcol2(1),ncol_adj_roi);
            gg = linspace(startcol2(2),endcol2(2),ncol_adj_roi);
            bb = linspace(startcol2(3),endcol2(3),ncol_adj_roi);
            cmap2(1:length(rr),:) = [rr(:), gg(:), bb(:)];

            cmap = [cmap1; cmap2];
        else
            cmap = cmap1;
        end

    case '2d'
        
        %%2d interp makes straight line through 2d colorwheel from one color to next

        ncol = ncol_each*2;
        cmap(1,:) = [1 0 0];
        cmap(2,:) = [1 1 1];
        cmap(3,:) = [0 0 1];

        [xx,yy] = meshgrid([1:3],[1:ncol]);

        cmap = interp2(xx([1,ceil(ncol/2),ncol],:),yy([1,ceil(ncol/2),ncol],:),cmap,xx,yy);

end