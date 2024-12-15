function h = initfig(opt)

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


if ~isfield(h, 'hfg') %if no figure has been initialized yet, initialize the axes that won't change

    szftmp = figsz(szf);
    hfg = figure( 'Units', 'Pixels', 'Color', 'white', 'visible', gifvis, 'WindowStyle', 'normal');
    hfg.Position = [0 0 szftmp];

    if doui
        hfg.KeyPressFcn = @(src,evnt)uikeypress(src,evnt);

        % hfgd = figure('Units', 'Normalized', 'Color', 'white', 'visible', gifvis);
        % hfgd.Position = [hfg.Position(1)+hfg.Position(3) 0 0.9-hfg.Position(3) hfg.Position(4)];
        % uib = uicontrol('Parent', hfgd, 'Units', 'Normalized', 'Style', 'popupmenu');
        % uib.Position = [0 0 1 1];
        % uib.Callback = @(src,evnt)pltexp_dlgcb_fcn(src,evnt,fnuic,fnuis); 
        % uib.String = labsp;
    end

    haxmain = axes( 'Position', [0, 0, 1, 1], 'XColor', 'none', 'YColor', 'none', 'XLim', [0, 1], 'YLim', [0, 1] ) ;

    haxmain.Toolbar.Visible = 'off';

    httl = text( haxmain, 0.5, 0.998, '', 'FontSize', fontsz, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold' );

    h.hfg = hfg;
    h.haxmain = haxmain;
    h.httl = httl;

end