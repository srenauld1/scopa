function plot_gif_rgb(in1, filename)

%in1 is 4d rgb image (4th dim is frames)

ncol = 128;

h = figure;
for i = 1:size(in1, 4)
    
    image(in1(:,:,:,i))
    hold on; axis off; axis image;

    frame = getframe(h);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im,ncol);

    if i == 1
        imwrite(imind,cm,filename, 'DelayTime', 0, 'Loopcount',inf);
    else
        imwrite(imind,cm,filename,'DelayTime', 0,'WriteMode','append');
    end

end