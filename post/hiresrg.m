function stackmnthr_reg = hiresrg(stackmnthr, ...
    pth_hires_mat_matreg, stack_lores_mnt, hrlr, opts_hires)



%% preprocess and downsample hires_ds stack to match stack_lores_mnt stack size

stack_lores_mnt = stack_lores_mnt - min(stack_lores_mnt(:));
stackmnthr = stackmnthr - min(stackmnthr(:));

stack_lores_mnt = single(stack_lores_mnt);
stackmnthr = single(stackmnthr);

%pad stack_lores_mnt with one frame on both sides, and pad hires_ds with num frames corresponding to one stack_lores_mnt frame
stack_lores_mnt = padarray(stack_lores_mnt, [0 0 1], 0, 'both');
padnum = unique(diff(find(diff(hrlr))));
hrlr = hrlr + 1;
hrlr = padarray(hrlr, [0 padnum], 1, 'pre');
hrlr = padarray(hrlr, [0 padnum], hrlr(end)+1, 'post');
stackmnthr = padarray(stackmnthr, [0 0 padnum], 0, 'both');

%downsample by averaging stackmnthr frames that map to each stack_lores_mnt frame
%rather than decimate,imresize,etc because this is how the stacks correspond to each other
stackmnthr_ds = zeros(size(stack_lores_mnt));
for i = 1:size(stackmnthr_ds, 3)
    stackmnthr_ds(:,:,i) = mean(stackmnthr(:,:,hrlr==i,:), 3);
end

stack_lores_mnt(stack_lores_mnt~=0) = rescale(stack_lores_mnt(stack_lores_mnt~=0));
stackmnthr_ds(stackmnthr_ds~=0) = rescale(stackmnthr_ds(stackmnthr_ds~=0)); %only rescale nonzeros in case of mask


%% register hires_ds to lores

%register downsampled hires_ds to stack_lores_mnt (in 3d)

[stackmnthr_ds_reg, tform] = stackrg3d(stackmnthr_ds, stack_lores_mnt, opts_hires.disttype, opts_hires.regtype);

%apply transformation to the hires that has not been downsampled
stackmnthr_reg = imwarp(stackmnthr,tform,"OutputView",imref3d(size(stackmnthr)));

%remove padding
stackmnthr_ds_reg(:,:,[1 end]) = [];
stack_lores_mnt(:,:,1) = []; %keep the final zero for the upsampling interp below
stackmnthr_reg(:,:,1:padnum) = [];
stackmnthr_reg(:,:,end-padnum+1:end) = [];

%upsample stack_lores_mnt to match registered hires_ds (just for plotting)
lores_to_hires_map = linspace(1, size(stack_lores_mnt,3), size(stackmnthr_reg, 3)+1); %include samples from the final non-pad frame
lores_to_hires_map = lores_to_hires_map(1:end-1);
F2 = griddedInterpolant(stack_lores_mnt, 'linear');
stack_lores_mnt_us = F2({ 1:size(stack_lores_mnt,1), 1:size(stack_lores_mnt,2), lores_to_hires_map });

stack_lores_mnt(:,:,end) = []; %now you can get rid of the pad zero at the end

stackmnthr_ds_reg(stackmnthr_ds_reg~=0) = rescale(stackmnthr_ds_reg(stackmnthr_ds_reg~=0));
stackmnthr_reg(stackmnthr_reg~=0) = rescale(stackmnthr_reg(stackmnthr_reg~=0));
stack_lores_mnt_us(stack_lores_mnt_us~=0) = rescale(stack_lores_mnt_us(stack_lores_mnt_us~=0));


%% save

save(pth_hires_mat_matreg, 'stackmnthr_reg', '-v7.3', '-mat')


%% plots


if opts_hires.doplt

    % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
    % volshow(stackmnthr_reg,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[0 1 0],Alphamap=0.1);
    % volshow(loreshr,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[1 0 1],Alphamap=0.1);
    %
    % stackplt(stackmnthr_reg, pthgif=[pth_hires_mat_matreg(1:end-4) 'stackmnthr_reg.gif'])
    %
    % regplot = stackmnthr_reg;
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
    % stackplt(catreg, pthgif=[pth_hires_mat_matreg(1:end-4) 'catreg.gif'])
    %
    % figure; montage(catreg)
    % saveas( gcf, [pth_hires_mat_matreg(1:end-4) 'catreg_montage.png'])

    for i = 1:size(stack_lores_mnt_us, 3)
        C(:,:,:,i) = imfuse(stack_lores_mnt_us(:,:,i),stackmnthr_reg(:,:,i),"Scaling","none");
    end
    pthgif = [pth_hires_mat_matreg(1:end-4) 'regfusion.gif'];
    plot_gif_rgb(C, pthgif)


    figure; imagesc(mean(stackmnthr, 3)); axis image; title("hires stack before registration mean z, mean t");
    saveas( gcf, [pth_hires_mat_matreg(1:end-4) '_meanmean_.png'])
    stackplt(stackmnthr, pthgif=[pth_hires_mat_matreg(1:end-4) 'hires_mean_notreg_.gif'])

    lrthr = 0.3; % stack_lores_mnt binariztion threshold to help vis
    hrthr = 0.3;% hires_ds binariztion threshold to help vis

    tmp = mean(mean(stack_lores_mnt, 4), 3);
    tmp = rescale(tmp);
    tmp(tmp<lrthr) = 0;
    tmp(tmp~=0) = 1;

    tmp2 = mean(stackmnthr_reg, 3);
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
