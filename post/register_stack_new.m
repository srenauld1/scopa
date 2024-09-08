function stackreg = register_stack_new(stack, pthsv)

arguments
    stack
    pthsv = []
end


if isempty(pthsv)
    pthsv = pthauto(pthsv, suffix='.gif', usetime=1);
end


%% preprocess and downsample hires_ds stack to match template stack size

template = median(stack,4);

template = template - min(template(:));
stack = stack - min(stack(:));

stack = stack(:,:,:,1:100);

% template = single(template);
% stack = single(stack);
% 
% dopad = 0;
% if dopad
%     template = padarray(template, [0 0 1], 0, 'both');
%     stack = padarray(stack, [0 0 1], 0, 'both');
% end
% 
% template(template~=0) = rescale(template(template~=0));
% stack(stack~=0) = rescale(stack(stack~=0)); %only rescale nonzeros in case of mask



smsdspace = 0.5;
if smsdspace
    for tind = 1:size(stack,4)
        stack(:,:,:,tind) = smooth3(stack(:,:,:,tind), 'gaussian', [3 3 3], 0.65);
    end
end

vwr = viewer3d();
vsh(1) = volshow(stack(:,:,:,1), Parent=vwr);
%% 

vwr.CameraPosition= [30 -25 -35]; %[10 60 -20]; %[60 -40 30];
vwr.Lighting='off';
vwr.BackgroundGradient='on';
vwr.GradientColor=[0 0 0.2];
vwr.BackgroundColor=[0 0 0];
vsh(1).RenderingStyle="GradientOpacity";
vsh(1).RenderingStyle="Isosurface";
vsh(1).OverlayRenderingStyle="GradientOverlay";
vsh(1).GradientOpacityValue=0.1;
vsh(1).GradientOpacityValue=0.1;
vsh(1).IsosurfaceValue = 0.4; 
vsh(1).Colormap=[1 0 1];
vsh(1).Alphamap=0.1;

% vsh(2) = volshow(template,Parent=vwr);
% vsh(2).RenderingStyle="GradientOpacity";
% vsh(2).Colormap=[0 1 0];
% vsh(2).OverlayRenderingStyle="GradientOverlay";
% vsh(2).Alphamap=0.1;

for k = 1:size(stack,4)
    vsh.Data = stack(:,:,:,k);
    fig2gif(vwr.Parent, k, pthsv)
end

%% 


disttype = 'monomodal';
disttype = 'multimodal';
regtype = 'rigid';

for k = 1:size(stack,4)
    [stackreg(:,:,:,k), tform] = register_one_stack_to_another_in_3d(stack(:,:,:,k), template, disttype, regtype);
    vsh(1).Data = stackreg(:,:,:,k);
    vsh(2).Data = template;
    fig2gif(vwr.Parent, k, pthsv)
end

% imshowpair(template(:,:,5),squeeze(stackreg(:,:,5,k)),"Scaling","joint")


if dopad
    stackreg(:,:,[1 end]) = [];
    template(:,:,1) = []; %keep the final zero for the upsampling interp below
end

stackreg(stackreg~=0) = rescale(stackreg(stackreg~=0));

% save(pthsv, 'stackreg', '-v7.3', '-mat')

doplots = 1;
if doplots

    vwr = viewer3d(BackgroundColor="black",BackgroundGradient="off");
    volshow(stackreg,Parent=vwr,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
        Colormap=[0 1 0],Alphamap=0.1);
    volshow(template,Parent=vwr,RenderingStyle="Isosurface",IsosurfaceValue=0.1, ...
        Colormap=[1 0 1],Alphamap=0.1);
    %
    % stack2fig(stack_hires_mnt_reg, pthgif=[pthsv(1:end-4) 'stack_hires_mnt_reg.gif'])
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
    % stack2fig(catreg, pthgif=[pthsv(1:end-4) 'catreg.gif'])
    %
    % figure; montage(catreg)
    % saveas( gcf, [pthsv(1:end-4) 'catreg_montage.png'])

    for i = 1:size(template, 3)
        C(:,:,:,i) = imfuse(template(:,:,i),stackreg(:,:,i),"Scaling","none");
    end
    pthsv = [pthsv(1:end-4) 'regfusion.gif'];
    plot_gif_rgb(C, pthsv)


    figure; imagesc(mean(stack, 3)); axis image; title("hires stack before registration mean z, mean t");
    saveas( gcf, [pthsv(1:end-4) '_meanmean_.png'])
    stack2fig(stack, pthgif=[pthsv(1:end-4) 'hires_mean_notreg_.gif'])

    lrthr = 0.3; % template binariztion threshold to help vis
    hrthr = 0.3;% hires_ds binariztion threshold to help vis

    tmp = mean(mean(template, 4), 3);
    tmp = rescale(tmp);
    tmp(tmp<lrthr) = 0;
    tmp(tmp~=0) = 1;

    tmp2 = mean(stackreg, 3);
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
    saveas( gcf, [pthsv(1:end-4) '_lores_hiresreg__overlay_.png'])


end
