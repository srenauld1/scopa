function h = fg(opt)

arguments
    opt.h = struct
    opt.doui = 1
    opt.gifvis = 'on'
    opt.szf = 1
    opt.fontsz = 8
    opt.alignh = 'center' %horizontal alignment, 'left', 'center', 'right'
    opt.cbshort = 0 %1 to convert callback keys to their short name (if one exists); for example, 'shift+semicolon' converted to 'colon'; cbshort is used in function cb_key, which is set here as callback function if doui=1
    opt.releasekeys = []; %empty or cell vector of char vectors listing keys that get flagged when released with KeyReleaseFcn cb_keyup (only if doui=1)
end
h = opt.h;
doui = opt.doui;
gifvis = opt.gifvis;
szf = opt.szf;
fontsz = opt.fontsz;
alignh = opt.alignh;
cbshort = opt.cbshort;
releasekeys = opt.releasekeys;

marginfg = 0.01;

if ~isfield(h, 'fg') %if no figure has been initialized yet, initialize the axes that won't change

    szftmp = figsz(szf);
    h.fg = figure( 'Units', 'Pixels', 'Color', 'white', 'visible', gifvis, 'WindowStyle', 'normal');
    h.fg.Position = [0 0 szftmp];

    if doui

        h.fg.KeyPressFcn = @(src,event)cb_key(src,event,cbshort=cbshort);
        h.fg.KeyReleaseFcn = @(src,event)cb_keyup(src,event,releasekeys=releasekeys);

        % h.fgd = figure('Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
        % h.fgd.Position = [h.fg.Position(1)+h.fg.Position(3) 0 0.9-h.fg.Position(3) h.fg.Position(4)];
        % uib = uicontrol('Parent', h.fgd, 'Units', 'Normalized', 'Style', 'popupmenu');
        % uib.Position = [0 0 1 1];
        % uib.Callback = @(src,event)cb_dlg(src,event,fnuic,fnuis);
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