function hndls = init_axes_ftvid(hndls, ax, stack, cmap, overlay_variable, text_variable, display_range, sector_ind, subplot_ind, widfac, htfac, fontsz, axorder)

arguments
    hndls struct
    ax struct
    stack
    cmap double = [] %if no cmap passed as argument, stack assumed to be rgb
    overlay_variable = []
    text_variable = []
    display_range = [0,1]
    sector_ind = 1
    subplot_ind = 1:size(stack,3)
    widfac = 1
    htfac = 1
    fontsz = [6 11 15]
    axorder char = 'rowmajor'
end

numsubplot = numel(subplot_ind);
fontsmall = fontsz(1);
fontmedium = fontsz(2);
fontlarge = fontsz(3);

numxpix = size(stack,2);
numypix = size(stack,1);
numim_per_frame = size(stack,3); %after reshaping, size of 3rd dim is number of figures (for each input stack) in a single frame (will be singleton if framenumdims==2)
numframes = size(stack,4); %after reshaping, size of 4th dim is number gif frames
dummyim = nan(numypix, numxpix);
stackmin = double(min(stack(:)));
stackmax = double(max(stack(:)));
stackrange = stackmax-stackmin;
imalpha = ones(size(dummyim))*0.5;


for j = 1:numsubplot

    hax{j} = axes('Parent', hndls.hfg, 'Units', 'Normalized', 'PositionConstraint', 'InnerPosition');
    hax{j}.InnerPosition(1) = ax(sector_ind).(axorder).xp(subplot_ind(j));
    hax{j}.InnerPosition(2) = ax(sector_ind).(axorder).yp(subplot_ind(j));
    hax{j}.InnerPosition(3) = ax(sector_ind).xe(widfac);
    hax{j}.InnerPosition(4) = ax(sector_ind).ye(htfac);
    hax{j}.Toolbar.Visible = 'off';

    hax{j}.DataAspectRatio = [1 1 1]; %don't think this is necessary
    hax{j}.XLim = [1 numxpix];
    hax{j}.YLim = [1 numypix];
    hax{j}.CLim = stackrange*display_range+stackmin;
    colormap(hax{j}, cmap);
    % hax{j}.XLabel.String = xlab;
    % hax{j}.YLabel.String = ylab;
    axis off
    axis ij

    hold(hax{j}, 'on')

    hpl{j} = image(hax{j}, 'CData', dummyim); %dummy_index_dim5=1 will work to initialize for roi_type pixel and roi
    hpl{j}.CDataMapping = 'scaled'; %this way, full range of any data type will be mapped to cmap range
    if ~isempty(overlay_variable) %if there are roi variables
        hol{j} = image(dummyim, 'AlphaData', imalpha);
    else
        hol{j} = [];
    end

    hlnx{j} = xline(hax{j}, nan, 'w', 'LineStyle', 'none');
    hlny{j} = yline(hax{j}, nan, 'w', 'LineStyle', 'none');
    if ~isempty(text_variable)
        htx{j} = text(hax{j}, size(stack, 2), size(stack, 1), num2str(text_variable(j)), 'Units', 'data', 'FontSize', fontmedium, 'Color', 'white');
    else
        htx{j} = [];
    end
    htx{j}.HorizontalAlignment = 'right';
    htx{j}.VerticalAlignment = 'bottom';

    hold(hax{j}, 'off')

end


hndls.ftv.hax = hax;
hndls.ftv.hpl = hpl;
hndls.ftv.hol = hol;
hndls.ftv.hlnx = hlnx;
hndls.ftv.hlny = hlny;
hndls.ftv.htx = htx;


end

