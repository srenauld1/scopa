function h = axim(im, opt)

% initialize axis for images 

arguments
    im
    opt.h = []
    opt.ax = []
    opt.ydir = 'reverse' %default reverses y for images because we typically think of them top-to-bottom 
    opt.stackp = [] %hack for rgb image for now
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
end
h = opt.h;
ax = opt.ax;
ydir = opt.ydir;
stackp = opt.stackp;
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

if isempty(h)
    h = fg();
end
if isempty(ax)
    ax = axarr(im);
end
if ~isempty(stackp)
    im = stackp;
    stackp = [];
end

numsubplot = numel(subplot_ind);
fontsmall = fontsz(1);
fontmedium = fontsz(2);
fontlarge = fontsz(3);

numxpix = size(im,2);
numypix = size(im,1);
numim_per_frame = size(im,3); %after reshaping, size of 3rd dim is number of figures (for each input im) in a single frame (will be singleton if fdimnum==2)
numframes = size(im,4); %after reshaping, size of 4th dim is number gif frames
dummyim = nan(numypix, numxpix);

imroi = zeros(numypix, numxpix, 3, 'single'); %make ones here, so only alphadata has to change later (showing the ones where the roi is located, scaled by alphafac)
imroialpha = zeros(numypix, numxpix, 'single');

stackmin = double(min(im(:)));
stackmax = double(max(im(:)));
stackrange = stackmax-stackmin;


for j = 1:numsubplot

    h.ax{j} = axes('Parent', h.fg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    hold(h.ax{j}, 'on')

    if colmaj
        h.ax{j}.InnerPosition(1) = ax(sector_ind).colmaj.x(subplot_ind(j));
        h.ax{j}.InnerPosition(2) = ax(sector_ind).colmaj.y(subplot_ind(j));
    else
        h.ax{j}.InnerPosition(1) = ax(sector_ind).x(subplot_ind(j));
        h.ax{j}.InnerPosition(2) = ax(sector_ind).y(subplot_ind(j));
    end
    h.ax{j}.InnerPosition(3) = ax(sector_ind).w(widfac);
    h.ax{j}.InnerPosition(4) = ax(sector_ind).h(htfac);
    if ~notim
        h.ax{j}.DataAspectRatio = [1 1 1]; 
    end
    % h.ax{j}.XLim = [1 numxpix]; %this cuts edge pixels in half, which makes aspect ratio actually wrong; does it do anything else?why do this instead of axis image or dataaspectratio 1 1 1????
    % h.ax{j}.YLim = [1 numypix]; %this cuts edge pixels in half, which makes aspect ratio actually wrong; does it do anything else?why do this instead of axis image or dataaspectratio 1 1 1???
    if stackrange==0
        h.ax{j}.CLim = dr+stackmin;
        h.tx2{j} = text(h.ax{j}, 0.5, 0.25, 'im IS A CONSTANT', 'Units', 'normalized', 'FontSize', fontmedium, 'Color', 'red');
        h.tx2{j} = text(h.ax{j}, 0.5, 0.5, 'im IS A CONSTANT', 'Units', 'normalized', 'FontSize', fontmedium, 'Color', 'green');
        h.tx2{j} = text(h.ax{j}, 0.5, 0.75, 'im IS A CONSTANT', 'Units', 'normalized', 'FontSize', fontmedium, 'Color', 'blue');
        h.tx2{j}.PickableParts = 'none'; %so you can capture click on image beneath the text
        h.tx2{j}.HorizontalAlignment = 'center';
        h.tx2{j}.VerticalAlignment = 'middle';
    else
        h.ax{j}.CLim = stackrange*dr+stackmin;
        h.tx2{j} = [];
    end

    if notb
        h.ax{j}.Toolbar.Visible = 'off';
    end

    % h.ax{j}.XLabel.String = xlab;
    % h.ax{j}.YLabel.String = ylab;

    h.ax{j}.Colormap = cmap;
    if noax
        h.ax{j}.Visible = 'off';
    else
        axis tight;
    end
    h.ax{j}.YDir = ydir;

    h.pl{j} = image(h.ax{j}, 'CData', im(:,:,j)); %if there are non singleton 4th and higher dimensions, this just plots first of them, since this function is just for initialization of the axis
    h.pl{j}.CDataMapping = 'scaled'; %scaled maps full range of any data type to colormap range

    if dool
        h.ol{j} = image(h.ax{j}, 'CData', imroi, 'AlphaData', imroialpha); %overlay image, color and alpha (e.g. for rois)
    else
        h.ol = [];
    end

    if doui
        if dool
            h.pl{j}.ButtonDownFcn = 'callbacks for this image are assigned to overlay image with handle h.ol';
            h.ol{j}.ButtonDownFcn = @(src,evnt)cb_click(src,evnt);
            h.ol{j}.PickableParts = 'visible';
            h.ol{j}.HitTest = 'on';
        else
            h.pl{j}.ButtonDownFcn = @(src,evnt)cb_click(src,evnt);
            h.pl{j}.PickableParts = 'visible';
            h.pl{j}.HitTest = 'on';
        end
    end


    h.lnx{j} = xline(h.ax{j}, nan, 'w', 'LineStyle', 'none');
    h.lny{j} = yline(h.ax{j}, nan, 'w', 'LineStyle', 'none');
    if ~isempty(txtvar)
        h.tx{j} = text(h.ax{j}, size(im, 2), size(im, 1), num2str(txtvar(j), 4), 'Units', 'data', 'FontSize', fontmedium, 'Color', 'white');
    else
        h.tx{j} = [];
    end
    h.tx{j}.PickableParts = 'none'; %so you can capture click on image beneath the text
    h.tx{j}.HorizontalAlignment = 'right';
    h.tx{j}.VerticalAlignment = 'bottom';

    hold(h.ax{j}, 'off')

end


end



