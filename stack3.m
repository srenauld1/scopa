function stack3(stack, opt)

arguments
    stack
    opt.iz = []
    opt.it = []
    opt.ic = []
    opt.cmap = []
    opt.style = []
    opt.rot = []
    opt.grad = 0
    opt.dn = 0
    opt.pthsv = []
end
iz = opt.iz;
it = opt.it;
ic = opt.ic;
cmap = opt.cmap;
style = opt.style;
grad = opt.grad;
dn = opt.dn;
rot = opt.rot;
pthsv = opt.pthsv;

maxnumframes = 500;

if isempty(it)
    it = 1:size(stack,4);
end
it = indsmake(it, indsall=size(stack,4));
if numel(it)>maxnumframes
    it = it(1:maxnumframes);
    fprintf("you have requested a volume with more than 500 frames, just plotting the first 200 frames of the set; if you want you can change maxnumframes (hard coded in stack3)")
end

if isempty(cmap)
    cmap = gray(256);
end

if isempty(rot)
    rot = [30 -25 -35];
end
if isempty(style)
    style = "GradientOpacity";
end
if isempty(pthsv)
    pthsv = pthauto(suffix='.gif', usetime=1);
end


if ndims(stack)<3
    error("stack must be >=3d")
end

if ~isempty(ic) && ~isequal(ic(:)', [1 2])
    stack = stack(:,:,:,:,ic);
end
if ~isempty(iz) && ~isequal(iz(:)', 1:size(stack,3))
    stack = stack(:,:,iz,:,:);
end

if ~isequal(it, 1:size(stack,4))
    stack = stack(:,:,:,it);
end


if grad
    stack = single(stack);
    dt = diff(stack, 1, 4);
    stack(:,:,:,1) = [];
    for k = 2:size(stack,4)
        [Gx, Gy, Gz] = imgradientxyz(stack(:,:,:,k));
        Gmag = sqrt(Gx.^2 + Gy.^2 + Gz.^2 + double(dt(:,:,:,k)).^2);
        % [Gmag, ~, ~] = imgradient3(stack(:,:,:,k), 'sobel');
        stack(:,:,:,k) = single(Gmag);
    end
    
    ncol = 256; %hard coding for now
    cmap = cmapmake(nodes={'r', 'k', 'b'}, ncol=ncol);
    maxabs = max(abs(vec(stack)));
    xref = linspace(-maxabs, maxabs, size(cmap,1)); %zero-centered colormap
    dref = linspace(min(stack(:)), max(stack(:)), size(cmap,1)); %zero-centered colormap
    cmap = interp1(xref, cmap, dref);
end

f = findall(groot(),'Type','figure');
for k = 1:numel(f)
    if isa(f(k).Children.Children, 'images.ui.graphics.Volume')
        close(f(k))
    end
end
vwr = viewer3d();
hfg = vwr.Parent;

if dn
    vwr.Denoising = 1;
    vwr.DenoisingDegreeOfSmoothing = 0.5;
    vwr.DenoisingSigma = 4;
end

vwr.CameraPosition = rot; %[10 60 -20]; %[60 -40 30];
vwr.Lighting='off';
vwr.BackgroundGradient='off';
vwr.GradientColor=[0 0 0.2];
vwr.BackgroundColor=[1 1 1];

% vwr.CropRegion = [5 5 5; 20 20 20];

vwr.CameraTarget = [32.5000 12.5000 10.5000];
vwr.CameraPosition = [32.3812 71.5100 11.2466];

vsh(1) = volshow(stack(:,:,:,1,1), Parent=vwr);

vsh(1).RenderingStyle=style;
vsh(1).OverlayRenderingStyle="GradientOverlay";
vsh(1).GradientOpacityValue = 0.3;
vsh(1).Colormap = cmap;
vsh(1).Alphamap = 0.9;

if size(stack,5)>1
    %or don't use vsh(2) and instead use vsh(1).OverlayData = stack(:,:,:,:,2):
    vsh(2) = volshow(stack(:,:,:,1,2), Parent=vwr);
    vsh(2).RenderingStyle=style;
    vsh(2).OverlayRenderingStyle="GradientOverlay";
    vsh(1).GradientOpacityValue=0.1;
    vsh(1).Colormap=cmap;
    vsh(2).Alphamap=0.1;
end



for k = 1:size(stack,4)
    vsh(1).Data = stack(:,:,:,k);
    fig2gif(hfg, k, pthsv)
end

close(vwr.Parent)

end
