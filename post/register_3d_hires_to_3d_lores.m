function stack_hires_mnt_reg = register_3d_hires_to_3d_lores(stack_hires_mnt, ...
    pth_hires_mat_matreg, stack_lores_mnt, map_hires_lores, opts_hires)



%% preprocess and downsample hires_ds stack to match stack_lores_mnt stack size

stack_lores_mnt = stack_lores_mnt - min(stack_lores_mnt(:));
stack_hires_mnt = stack_hires_mnt - min(stack_hires_mnt(:));

stack_lores_mnt = single(stack_lores_mnt);
stack_hires_mnt = single(stack_hires_mnt);

%pad stack_lores_mnt with one frame on both sides, and pad hires_ds with num frames corresponding to one stack_lores_mnt frame
stack_lores_mnt = padarray(stack_lores_mnt, [0 0 1], 0, 'both');
padnum = unique(diff(find(diff(map_hires_lores))));
map_hires_lores = map_hires_lores + 1;
map_hires_lores = padarray(map_hires_lores, [0 padnum], 1, 'pre');
map_hires_lores = padarray(map_hires_lores, [0 padnum], map_hires_lores(end)+1, 'post');
stack_hires_mnt = padarray(stack_hires_mnt, [0 0 padnum], 0, 'both');

%downsample by averaging stack_hires_mnt frames that map to each stack_lores_mnt frame
%rather than decimate,imresize,etc because this is how the stacks correspond to each other
stack_hires_mnt_ds = zeros(size(stack_lores_mnt));
for i = 1:size(stack_hires_mnt_ds, 3)
    stack_hires_mnt_ds(:,:,i) = mean(stack_hires_mnt(:,:,map_hires_lores==i,:), 3);
end

stack_lores_mnt(stack_lores_mnt~=0) = rescale(stack_lores_mnt(stack_lores_mnt~=0));
stack_hires_mnt_ds(stack_hires_mnt_ds~=0) = rescale(stack_hires_mnt_ds(stack_hires_mnt_ds~=0)); %only rescale nonzeros in case of mask


%% register hires_ds to lores

%register downsampled hires_ds to stack_lores_mnt (in 3d)

[stack_hires_mnt_ds_reg, tform] = register_one_stack_to_another_in_3d(stack_hires_mnt_ds, stack_lores_mnt, opts_hires.disttype, opts_hires.regtype);

%apply transformation to the hires that has not been downsampled
stack_hires_mnt_reg = imwarp(stack_hires_mnt,tform,"OutputView",imref3d(size(stack_hires_mnt)));

%remove padding
stack_hires_mnt_ds_reg(:,:,[1 end]) = [];
stack_lores_mnt(:,:,1) = []; %keep the final zero for the upsampling interp below
stack_hires_mnt_reg(:,:,1:padnum) = [];
stack_hires_mnt_reg(:,:,end-padnum+1:end) = [];

%upsample stack_lores_mnt to match registered hires_ds (just for plotting)
lores_to_hires_map = linspace(1, size(stack_lores_mnt,3), size(stack_hires_mnt_reg, 3)+1); %include samples from the final non-pad frame
lores_to_hires_map = lores_to_hires_map(1:end-1);
F2 = griddedInterpolant(stack_lores_mnt, 'linear');
stack_lores_mnt_us = F2({ 1:size(stack_lores_mnt,1), 1:size(stack_lores_mnt,2), lores_to_hires_map });

stack_lores_mnt(:,:,end) = []; %now you can get rid of the pad zero at the end

stack_hires_mnt_ds_reg(stack_hires_mnt_ds_reg~=0) = rescale(stack_hires_mnt_ds_reg(stack_hires_mnt_ds_reg~=0));
stack_hires_mnt_reg(stack_hires_mnt_reg~=0) = rescale(stack_hires_mnt_reg(stack_hires_mnt_reg~=0));
stack_lores_mnt_us(stack_lores_mnt_us~=0) = rescale(stack_lores_mnt_us(stack_lores_mnt_us~=0));


%% save

save(pth_hires_mat_matreg, 'stack_hires_mnt_reg', '-v7.3', '-mat')


%% plots


if opts_hires.doplt

    % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
    % volshow(stack_hires_mnt_reg,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[0 1 0],Alphamap=0.1);
    % volshow(loreshr,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[1 0 1],Alphamap=0.1);
    %
    % stack2fig(stack_hires_mnt_reg, pthgif=[pth_hires_mat_matreg(1:end-4) 'stack_hires_mnt_reg.gif'])
    %
    % regplot = stack_hires_mnt_reg;
    % pct = prctile(regplot(:), 98);
    % regplot(regplot>pct) = pct;
    %
    % loresplot = loreshr;
    % pct = prctile(loresplot(:), 5);
    % pct2 = prctile(loresplot(:), 97);
    % loresplot(loresplot<pct) = pct;
    % loresplot(loresplot>pct2) = pct2;
    %
    % catreg = cat(1, rescale(loresplot), rescale(regplot));
    %
    % stack2fig(catreg, pthgif=[pth_hires_mat_matreg(1:end-4) 'catreg.gif'])
    %
    % figure; montage(catreg)
    % saveas( gcf, [pth_hires_mat_matreg(1:end-4) 'catreg_montage.png'])

    for i = 1:size(stack_lores_mnt_us, 3)
        C(:,:,:,i) = imfuse(stack_lores_mnt_us(:,:,i),stack_hires_mnt_reg(:,:,i),"Scaling","none");
    end
    pthgif = [pth_hires_mat_matreg(1:end-4) 'regfusion.gif'];
    plot_gif_rgb(C, pthgif)


    figure; imagesc(mean(stack_hires_mnt, 3)); axis image; title("hires stack before registration mean z, mean t");
    saveas( gcf, [pth_hires_mat_matreg(1:end-4) '_meanmean_.png'])
    stack2fig(stack_hires_mnt, pthgif=[pth_hires_mat_matreg(1:end-4) 'hires_mean_notreg_.gif'])

    lrthr = 0.3; % stack_lores_mnt binariztion threshold to help vis
    hrthr = 0.3;% hires_ds binariztion threshold to help vis

    tmp = mean(mean(stack_lores_mnt, 4), 3);
    tmp = rescale(tmp);
    tmp(tmp<lrthr) = 0;
    tmp(tmp~=0) = 1;

    tmp2 = mean(stack_hires_mnt_reg, 3);
    tmp2 = rescale(tmp2);
    tmp2(tmp2<hrthr) = 0;
    tmp2(tmp2~=0) = 1;

    tmpall(:,:,1) = tmp;
    tmpall(:,:,2) = tmp2;
    tmpall(:,:,3) = rescale(tmp+tmp2);
    figure;
    for tti = 1:size(tmpall, 3)
        subplot(size(tmpall, 3), 1, tti)
        imshow(tmpall(:,:,tti));
        axis image; axis off
    end

    sgtitle("binarized stack lores mnt, registered hires ds, and overlay")
    saveas( gcf, [pth_hires_mat_matreg(1:end-4) '_lores_hiresreg__overlay_.png'])


end
