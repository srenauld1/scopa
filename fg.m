function h = fg(opt)

arguments
    opt.h = struct
    opt.doui = 1
    opt.gifvis = 'on'
    opt.szf = 1
    opt.fontsz = 8
    opt.alignh = 'center' %horizontal alignment, 'left', 'center', 'right'
    opt.cbshort = 0 %1 to convert callback keys to their short name (if one exists); for example, 'shift+semicolon' converted to 'colon'; cbshort is used in function cb_key, which is set here as callback function if doui=1
end
h = opt.h;
doui = opt.doui;
gifvis = opt.gifvis;
szf = opt.szf;
fontsz = opt.fontsz;
alignh = opt.alignh;
cbshort = opt.cbshort;

marginfg = 0.01;

if ~isfield(h, 'fg') %if no figure has been initialized yet, initialize the axes that won't change

    szftmp = figsz(szf);
    h.fg = figure( 'Units', 'Pixels', 'Color', 'white', 'visible', gifvis, 'WindowStyle', 'normal');
    h.fg.Position = [0 0 szftmp];

    if doui

        h.fg.KeyPressFcn = @(src,evnt)cb_key(src,evnt,cbshort=cbshort);

        % h.fgd = figure('Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
        % h.fgd.Position = [h.fg.Position(1)+h.fg.Position(3) 0 0.9-h.fg.Position(3) h.fg.Position(4)];
        % uib = uicontrol('Parent', h.fgd, 'Units', 'Normalized', 'Style', 'popupmenu');
        % uib.Position = [0 0 1 1];
        % uib.Callback = @(src,evnt)cb_dlg(src,evnt,fnuic,fnuis);
        % uib.String = labsp;

    end

    h.axm = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;

    h.axm.Toolbar.Visible = 'off';

    if strcmp(alignh, 'center')
        textposition = [0.5, 1-marginfg];
    elseif strcmp(alignh, 'left')
        textposition = [0+marginfg, 1-marginfg];
    end
    h.ttl = text( h.axm, textposition(1), textposition(2), '', 'FontSize', fontsz, 'HorizontalAlignment', alignh, 'VerticalAlignment', 'top', 'FontWeight', 'bold' );

end