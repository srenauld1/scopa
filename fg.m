function h = fg(opt)

arguments
    opt.h = struct
    opt.doui = 1
    opt.gifvis = 'on'
    opt.szf = 1
    opt.fontsz = 8
end
h = opt.h;
doui = opt.doui;
gifvis = opt.gifvis;
szf = opt.szf;
fontsz = opt.fontsz;


if ~isfield(h, 'fg') %if no figure has been initialized yet, initialize the axes that won't change

    szftmp = figsz(szf);
    h.fg = figure( 'Units', 'Pixels', 'Color', 'white', 'visible', gifvis, 'WindowStyle', 'normal');
    h.fg.Position = [0 0 szftmp];

    if doui
        h.fg.KeyPressFcn = @(src,evnt)cb_key(src,evnt);

        % h.fgd = figure('Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
        % h.fgd.Position = [h.fg.Position(1)+h.fg.Position(3) 0 0.9-h.fg.Position(3) h.fg.Position(4)];
        % uib = uicontrol('Parent', h.fgd, 'Units', 'Normalized', 'Style', 'popupmenu');
        % uib.Position = [0 0 1 1];
        % uib.Callback = @(src,evnt)cb_dlg(src,evnt,fnuic,fnuis); 
        % uib.String = labsp;
    end

    h.axm = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;

    h.axm.Toolbar.Visible = 'off';

    h.ttl = text( h.axm, 0.5, 0.998, '', 'FontSize', fontsz, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );


end