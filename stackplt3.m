function stackplt3(stack, opt)

arguments
    stack
    opt.t = []
    opt.epochts = []
    opt.pthstack = []
    opt.iz = []
    opt.it = []
    opt.its = []
    opt.ic = []
    opt.cmap = []
    opt.style = []
    opt.rot = []
    opt.grad = 0
    opt.dn = 0
    opt.svtype = [] %empty to skip saving, bin to save new stack to bin, mat to save new stack to mat; bin is recommended over mat; mat and bin append to file frame by frame, to minimize memory usage; bin is many times faster than mat; mat saves a file with a little compression, and can retain original shape (and has some more functionality that saving to bin does not, although none of it is necessary here); bin you have to reshape after reading in, so original shape is included in filename, along with class
    opt.szf = 1
    opt.pthgif = []
    opt.dogif = 1
end
t = opt.t;
epochts = opt.epochts;
pthstack = opt.pthstack;
iz = opt.iz;
its = opt.its;
it = opt.it;
ic = opt.ic;
cmap = opt.cmap;
style = opt.style;
grad = opt.grad;
dn = opt.dn;
rot = opt.rot;
svtype = opt.svtype;
szf = opt.szf;
pthgif = opt.pthgif;
dogif = opt.dogif;

maxnumframes = 500;


if isempty(pthstack)
    pthstack = glb('pthstack');
end
if isempty(t)
    t = glb('t');
    if isempty(t)
        error("must pass in t or set glb('t')")
    end
end
if isempty(epochts)
    epochts = glb('epochts');
    if isempty(epochts)
        error("must pass in epochts or set glb('epochts')")
    end
end

if ~isempty(svtype) && isempty(pthgif)
    error("")
end

id = idmake(pthstack);
recid = id.recid;

pthpre = [erase(pthstack, '.mat') 'stack3_'];

if ~isempty(it)
    if isempty(t)
        error("if it is nonempty, t must be nonempty")
    end
    if ~isempty(its)
        error("its and it cannot both be nonempty")
    end
    its = t2samp(t, it);
end


if isempty(its)
    its = 1:size(stack,4);
end
its = indsmake(its, indsall=size(stack,4));
if numel(its)>maxnumframes
    its = its(1:maxnumframes);
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
if isempty(pthgif)
    pthgif = pthauto(suffix='.gif', usetime=1);
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
if ~isequal(its, 1:size(stack,4))
    stack = stack(:,:,:,its);
end


sz = size(stack);


if grad
    stack = single(stack);
    if grad==1
        dt = diff(stack, 1, 4);
        stack(:,:,:,1) = [];
    end
    if grad==1 || grad==2
        for k = 2:size(stack,4)
            if grad==1
                [Gx, Gy, Gz] = imgradientxyz(stack(:,:,:,k));
                Gmag = sqrt(Gx.^2 + Gy.^2 + Gz.^2 + double(dt(:,:,:,k)).^2);
            elseif grad==2
                [Gmag, ~, ~] = imgradient3(stack(:,:,:,k), 'sobel');
            end
            stack(:,:,:,k) = single(Gmag);
        end
        if grad==2
            stack = diff(stack, 1, 4);
        end
    end

    if grad==3
        stack = reshape(stack,[], size(stack,4));
        for k = 1:size(stack,1)
            stack(k,:) = movingslope(stack(k,:), 5, 2);
        end
        stack = reshape(stack, sz);
    end

    if grad==2 || grad==3
        ncol = 256; %hard coding for now
        cmap = cmapmake(nodes={'r', 'k', 'b'}, ncol=ncol);
        maxabs = max(abs(vec(stack)));
        xref = linspace(-maxabs, maxabs, size(cmap,1)); %zero-centered colormap
        dref = linspace(min(stack(:)), max(stack(:)), size(cmap,1)); %zero-centered colormap
        cmap = interp1(xref, cmap, dref);
    end
end

f = findall(groot(),'Type','figure');
for k = 1:numel(f)
    try
        if isa(f(k).Children.Children, 'images.ui.graphics.Volume')
            close(f(k))
        end
    catch
    end
end
vwr = viewer3d();
hfg = vwr.Parent;
szftmp = figsz(szf);
hfg.Position = [0 0 szftmp];

if dn
    vwr.Denoising = 1;
    vwr.DenoisingDegreeOfSmoothing = 0.6;
    vwr.DenoisingSigma = 4;
end

vwr.Lighting='off';
vwr.BackgroundGradient='off';
vwr.GradientColor=[0 0 0.2];
vwr.BackgroundColor=[1 1 1];

vsh(1) = volshow(stack(:,:,:,1,1), Parent=vwr);

vsh(1).RenderingStyle=style;
vsh(1).OverlayRenderingStyle="GradientOverlay";
vsh(1).GradientOpacityValue = 0.9;
vsh(1).Colormap = cmap;
vsh(1).Alphamap = 1;

% vwr.CropRegion = [5 5 5; 20 20 20];

switch recid
    case {'20250209_1_1'}
        vwr.ClippingPlanes = [-0.0034    0.9999   -0.0167  -11.5898]; %20250209
        vwr.CameraPosition = [30.1300 -58.6419 12.7833]; %20250209, 20250221_1_2
    case {'20250221_1_2'}
        vwr.ClippingPlanes = [-0.0034    0.9999   -0.0167  -10.1692]; %20250221_1_2
        vwr.CameraPosition = [30.1300 -58.6419 12.7833]; %20250209, 20250221_1_2
    case {'20250316_1_1'}
        vwr.CameraPosition = [60.9303   93.0271   10.0094]; %20250209, 20250221_1_2
        vwr.ClippingPlanes = [-0.0034    0.9999   -0.0167   -8.7669]; %20250221_1_2
end

if size(stack,5)>1
    %or don't use vsh(2) and instead use vsh(1).OverlayData = stack(:,:,:,:,2):
    vsh(2) = volshow(stack(:,:,:,1,2), Parent=vwr);
    vsh(2).RenderingStyle=style;
    vsh(2).OverlayRenderingStyle="GradientOverlay";
    vsh(1).GradientOpacityValue=0.1;
    vsh(1).Colormap=cmap;
    vsh(2).Alphamap=0.1;
end


ttl = title("t: " + num2str(t(1)) + "epoch: " + num2str(epochts(1)));
for k = 1:size(stack,4)

    vsh(1).Data = stack(:,:,:,k);
    ttl.String = "t: " + num2str(t(k)) + "epoch: " + num2str(epochts(k));


    if ~isempty(svtype)
        obj = ancestor(vsh(1),'figure','toplevel');
        I = getframe(obj);
        tmp = I.cdata;
        vclass = class(tmp);
        szstr = sprintf('%.0f_', size(stack));
        szstr = szstr(1:end-1);
        fn = [pthpre 'tmp_' vclass '_' szstr '_.' svtype];

        if strcmp(svtype, 'mat')
            if k==1
                tmp = cat(4, tmp, tmp); %hack to create a 4th dimension, k==2 overwrites
                save(fn, 'tmp', '-v7.3');
                m = matfile(fn, Writable=true);
            else
                m.tmp(:,:,:,k) = tmp;
            end
        elseif strcmp(svtype, 'bin')
            if k==1
                fid = fopen(fn, 'a+');
            end
            fwrite(fid, tmp, vclass);
            if k==size(stack,4)
                fclose(fid);
            end
        end
    end

    if dogif
        fig2gif(hfg, k, pthgif)
    end

end

close(vwr.Parent)

end
