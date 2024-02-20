function reghr = register_3d_hires_to_lores(lores, hires_original, map_hires_lores, ...
    pth_hires_mat_matreg, doplots)


%% preprocess and downsample hires stack to match lores stack size 

lores = lores - min(lores(:));
hires_original = hires_original - min(hires_original(:));

lores = single(lores);
hires_original = single(hires_original);

%pad lores with one frame on both sides, and pad hires with num frames corresponding to one lores frame 
lores = padarray(lores, [0 0 1], 0, 'both');
padnum = unique(diff(find(diff(map_hires_lores))));
map_hires_lores = map_hires_lores + 1;
map_hires_lores = padarray(map_hires_lores, [0 padnum], 1, 'pre');
map_hires_lores = padarray(map_hires_lores, [0 padnum], map_hires_lores(end)+1, 'post');
hires_original = padarray(hires_original, [0 0 padnum], 0, 'both');

%downsample by averaging hires frames mapping to each lores frame 
%rather than decimate,imresize,etc because this is how the stacks correspond to each other 
hires = zeros(size(lores));
for i = 1:size(hires, 3)
    hires(:,:,i) = mean(hires_original(:,:,map_hires_lores==i,:), 3);
end

lores(lores~=0) = rescale(lores(lores~=0));
hires(hires~=0) = rescale(hires(hires~=0)); %only rescale nonzeros in case of mask

%% register hires to lores 

%register downsampled hires to lores (in 3d)
disttype = 'monomodal'; % multimodal monomodal
regtype = 'rigid';  
[reglr, tform] = register_one_stack_to_another(hires, lores, disttype, regtype);

%apply transformation to hires 
reghr = imwarp(hires_original,tform,"OutputView",imref3d(size(hires_original)));

%remove padding 
reglr(:,:,[1 end]) = [];
lores(:,:,1) = []; %keep the final zero for the upsampling interp below 
reghr(:,:,1:padnum) = [];
reghr(:,:,end-padnum+1:end) = [];

%upsample lores to match registered hires (just for plotting) 
lores_to_hires_map = linspace(1, size(lores,3), size(reghr, 3)+1); %include samples from the final non-pad frame
lores_to_hires_map = lores_to_hires_map(1:end-1);
F2 = griddedInterpolant(lores, 'linear');
loreshr = F2({ 1:size(lores,1), 1:size(lores,2), lores_to_hires_map });

lores(:,:,end) = []; %now you can get rid of the pad zero at the end

reglr(reglr~=0) = rescale(reglr(reglr~=0));
reghr(reghr~=0) = rescale(reghr(reghr~=0));
loreshr(loreshr~=0) = rescale(loreshr(loreshr~=0));

if doplots

    % viewerRegistered = viewer3d(BackgroundColor="black",BackgroundGradient="off");
    % volshow(reghr,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[0 1 0],Alphamap=0.1);
    % volshow(loreshr,Parent=viewerRegistered,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
    %     Colormap=[1 0 1],Alphamap=0.1);
    % 
    % plot_gif(reghr, [pth_hires_mat_matreg(1:end-4) 'reghr.gif'], 256)
    % 
    % regplot = reghr;
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
    % plot_gif(catreg, [pth_hires_mat_matreg(1:end-4) 'catreg.gif'], 256)
    % 
    % figure; montage(catreg)
    % saveas( gcf, [pth_hires_mat_matreg(1:end-4) 'catreg_montage.png'])

    for i = 1:size(loreshr, 3)
        C(:,:,:,i) = imfuse(loreshr(:,:,i),reghr(:,:,i),"Scaling","none");
    end
    fngif = [pth_hires_mat_matreg(1:end-4) 'regfusion.gif'];
    plot_gif_rgb(C, fngif)


end


