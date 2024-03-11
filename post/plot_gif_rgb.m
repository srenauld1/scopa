function plot_gif_rgb(in1, filename)

%in1 is 4d rgb image (4th dim is frames)

h = figure;
for i = 1:size(in1, 4)

    image(in1(:,:,:,i))
    hold on; axis off; axis image;

    fig2gif(h, i, filename)

end