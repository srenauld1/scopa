function plot_gif(in1, filename, ncol, cmap, flipdim, overlay_scatter, titopt, qplot)

szo = size(in1);
numdims = ndims(in1);


if ~exist('gif_visibility', 'var') 
    gif_visibility = 1;
end

if ~exist('flipdim', 'var')
    flipdim = 0;
end

if numdims==2
    sznew = [size(in1) 1];
elseif numdims==3
    sznew = size(in1);
    if exist('overlay_scatter', 'var') & size(overlay_scatter,2) == 4
        szo(end+1) = 1;
    end
elseif numdims>3
    if flipdim
        in1 = permute(in1, [1 2 4 3]);
        szo = size(in1);
        if exist('overlay_scatter', 'var') & size(overlay_scatter,2) == 4
            overlay_scatter(:,3:4) = fliplr(overlay_scatter(:,3:4));
        end
    end
    in1 = reshape(in1, size(in1,1), size(in1,2), []);
    sznew = size(in1);
end

h = figure;
for i = 1:sznew(end)

    if exist('qplot', 'var')
        subplot(2,1,1)
    end
    
    if i==1

        if exist('cmap', 'var')
            if ~strcmp(class(in1), 'double') & ~strcmp(class(in1), 'single')
                "MAKE IT DOUBLE OR SINGLE TO MAP 1 TO FIRST ELEMENT OF CMAP"
                "for INT and bool 0 will map to first element of cmap"
                "passing cmap to imshow assumes array is indexed image"
                error
            end
            if min(in1(:))<1
                "MAKE IT DOUBLE OR SINGLE TO MAP 1 TO FIRST ELEMENT OF CMAP"
                error
            end
            %round because otherwise cmap in imshow will take floor
            himg = imshow(round(in1(:,:,i)), cmap, 'InitialMagnification', 'fit');
        else
            himg = imshow(in1(:,:,i), 'InitialMagnification', 'fit');
        end

    else

        if exist('cmap', 'var')
            himg.CData = round(in1(:,:,i));
        else
            himg.CData = in1(:,:,i);

        end

    end
    hold on; axis off; axis image;
    g = gca;
    
    if exist('overlay_scatter', 'var')
        if size(overlay_scatter,2) == 2
            scatter(overlay_scatter(:,2), overlay_scatter(:,1), '.r')
        elseif size(overlay_scatter,2) == 3
            idxx = find(overlay_scatter(:,3) == mod(i-1, szo(3))+1);
            scatter(overlay_scatter(idxx,2), overlay_scatter(idxx,1), '.r')
        elseif size(overlay_scatter,2) == 4
            idxx = find(sub2ind(szo(3:end), overlay_scatter(:,3), overlay_scatter(:,4)) == i);
            scatter(overlay_scatter(idxx,2), overlay_scatter(idxx,1), '.r')
        end
        xlim(g.XLim)
        ylim(g.XLim)
    end
    
    if exist('qplot', 'var')
        subplot(2,1,2)
        [X,Y] = meshgrid(1,1);
        U = titopt{i,2}*sin(titopt{i,1});
        V = titopt{i,2}*cos(titopt{i,1});
        % U = ones(size(X))*sin(titopt{i,1});
        % V = ones(size(Y))*cos(titopt{i,1});
        quiver(X,Y,U,V,0, "LineWidth", 5, 'color', 'r')
        xlim([0 2])
        ylim([0 2])
        axis square

    end

    if exist('titopt', 'var')
        sgtitle(['pd ' num2str(rad2deg(titopt{i,1})) ' gof ' num2str(titopt{i,2})])
    end

    frame = getframe(h);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im,ncol);

    if i == 1
        imwrite(imind,cm,filename, 'DelayTime', 0, 'Loopcount',inf);
    else
        imwrite(imind,cm,filename,'DelayTime', 0,'WriteMode','append');
    end
end

end