function h = axim(im, opt)

% initialize axes for images 

arguments
    im
    opt.h = []
    opt.ax = []
    opt.ydir = 'reverse' %default reverses y for images because we typically think of them top-to-bottom 
    opt.cmap = gray(256) %cmap or 'rgb'
    opt.txtvar = []
    opt.dr = [0,1]
    opt.sector_ind = 1
    opt.subplot_ind = 1:size(im,3)
    opt.widfac = 1
    opt.htfac = 1
    opt.fontsz = [6 11 15]
    opt.colmaj = 0
    opt.dool = 0
    opt.doui = 0
    opt.notim = 0 %if what you're plotting is not actually an image (e.g., if it's some neural responses, concatenated along one dimension), let matlab determine the aspect ratio
    opt.notb = 0
    opt.noax = 1
    opt.nm = 'im'
    opt.axidx = [] %index of image axes you want to create, corresponds to index into nonscalar struct for holding image axes and their children 
end
h = opt.h;
ax = opt.ax;
ydir = opt.ydir;
cmap = opt.cmap;
txtvar = opt.txtvar;
dr = opt.dr;
sector_ind = opt.sector_ind;
subplot_ind = opt.subplot_ind;
widfac = opt.widfac;
htfac = opt.htfac;
fontsz = opt.fontsz;
colmaj = opt.colmaj;
dool = opt.dool;
doui = opt.doui;
notim = opt.notim;
notb = opt.notb;
noax = opt.noax;
nm = opt.nm;
axidx = opt.axidx;

if isempty(h)
    h = fg();
end
if isfield(h, 'fg') && ~isscalar(h.fg)
    error("h.fg input to axim must be scalar (choose one figure to initialize the axes)")
end

if isempty(axidx)
    if isfield(h, nm)
        q = numel(h.(nm))+1; %index of image axes named nm (nonscalar struct index)
    else
        q = 1; %only one axes named nm
    end
else
    q = axidx;
end

if isfield(h, nm)
    if q<=numel(h.(nm))
        if ~isempty(h.(nm)(q))
            for k = 1:numel(h.(nm).ax)
                delete(h.(nm).ax{k}) %delete actual graphics object
            end
            h = rmfield(h, nm); %remove field holding graphics object also
        end
    end
end

if isempty(ax)
    ax = axarr(im);
end

numax = numel(subplot_ind);
fontmedium = fontsz(2);

[ny, nx, nz, nt, nc] = size(im);

imroi = zeros(ny, nx, 3, 'single'); %ones here, so only alphadata has to change later (showing the ones where the roi is located, scaled by alphafac)
imroialpha = zeros(ny, nx, 'single');

immin = double(min(im(:)));
immax = double(max(im(:)));
imrange = immax-immin;


for j = 1:numax

    h.(nm)(q).ax{j} = axes('Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    hold(h.(nm)(q).ax{j}, 'on')

    if colmaj
        h.(nm)(q).ax{j}.InnerPosition(1) = ax(sector_ind).colmaj.x(subplot_ind(j));
        h.(nm)(q).ax{j}.InnerPosition(2) = ax(sector_ind).colmaj.y(subplot_ind(j));
    else
        h.(nm)(q).ax{j}.InnerPosition(1) = ax(sector_ind).x(subplot_ind(j));
        h.(nm)(q).ax{j}.InnerPosition(2) = ax(sector_ind).y(subplot_ind(j));
    end
    h.(nm)(q).ax{j}.InnerPosition(3) = ax(sector_ind).w(widfac);
    h.(nm)(q).ax{j}.InnerPosition(4) = ax(sector_ind).h(htfac);
    if ~notim
        h.(nm)(q).ax{j}.DataAspectRatio = [1 1 1]; 
    end
    % h.(nm)(q).ax{j}.XLim = [1 nx]; %this cuts edge pixels in half, which makes aspect ratio actually wrong; does it do anything else? why do this instead of axis image or dataaspectratio 1 1 1????
    % h.(nm)(q).ax{j}.YLim = [1 ny]; %this cuts edge pixels in half, which makes aspect ratio actually wrong; does it do anything else? why do this instead of axis image or dataaspectratio 1 1 1???
    if imrange==0
        h.(nm)(q).ax{j}.CLim = dr+immin;
        h.(nm)(q).tx2{j} = text(h.(nm)(q).ax{j}, 0.5, 0.5, '\color{red} IMAGE \color{green} IS \color{blue} A \color{yellow} CONSTANT', 'Units', 'normalized', 'FontSize', fontmedium, 'Color', 'red');
        h.(nm)(q).tx2{j}.PickableParts = 'none'; %so you can capture click on image beneath the text
        h.(nm)(q).tx2{j}.HorizontalAlignment = 'center';
        h.(nm)(q).tx2{j}.VerticalAlignment = 'middle';
    else
        h.(nm)(q).ax{j}.CLim = imrange*dr+immin;
        h.(nm)(q).tx2{j} = [];
    end

    if notb
        h.(nm)(q).ax{j}.Toolbar.Visible = 'off';
    end

    % h.(nm)(q).ax{j}.XLabel.String = xlab;
    % h.(nm)(q).ax{j}.YLabel.String = ylab;

    h.(nm)(q).ax{j}.Colormap = cmap;
    if noax
        h.(nm)(q).ax{j}.Visible = 'off';
    else
        axis tight;
    end
    h.(nm)(q).ax{j}.YDir = ydir;

    h.(nm)(q).pl{j} = image(h.(nm)(q).ax{j}, CData=im(:,:,j)); %if there are non singleton 4th and higher dimensions, this just plots first of them, since this function is just for initialization of the axes
    h.(nm)(q).pl{j}.CDataMapping = 'scaled'; %scaled maps full range of any data type to colormap range

    if dool
        h.(nm)(q).ol{j} = image(h.(nm)(q).ax{j}, CData=imroi, AlphaData=imroialpha); %overlay image, color and alpha (e.g. for rois)
    else
        h.(nm)(q).ol = [];
    end

    if doui
        if dool
            h.(nm)(q).pl{j}.ButtonDownFcn = 'callbacks for this image are assigned to overlay image with handle h.(nm)(q).ol';
            h.(nm)(q).ol{j}.ButtonDownFcn = @(src,event)cb_click(src,event);
            h.(nm)(q).ol{j}.PickableParts = 'visible';
            h.(nm)(q).ol{j}.HitTest = 'on';
        else
            h.(nm)(q).pl{j}.ButtonDownFcn = @(src,event)cb_click(src,event);
            h.(nm)(q).pl{j}.PickableParts = 'visible';
            h.(nm)(q).pl{j}.HitTest = 'on';
        end
    end

    h.(nm)(q).lnx{j} = xline(h.(nm)(q).ax{j}, nan, 'w', 'LineStyle', 'none');
    h.(nm)(q).lny{j} = yline(h.(nm)(q).ax{j}, nan, 'w', 'LineStyle', 'none');
    if ~isempty(txtvar)
        h.(nm)(q).tx{j} = text(h.(nm)(q).ax{j}, nx, ny, num2str(txtvar(j), 4), 'Units', 'data', 'FontSize', fontmedium, 'Color', 'white');
    else
        h.(nm)(q).tx{j} = [];
    end
    h.(nm)(q).tx{j}.PickableParts = 'none'; %so you can capture click on image beneath the text
    h.(nm)(q).tx{j}.HorizontalAlignment = 'right';
    h.(nm)(q).tx{j}.VerticalAlignment = 'bottom';

    hold(h.(nm)(q).ax{j}, 'off')

end


end



