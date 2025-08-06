function [xypx, xyrat] = screenpx()

% get current screen xy number pixels, also output w/h aspect ratio 

% gr = groot; dms = gr.ScreenSize; %this won't always return usable screen size because of task bars, for example

xypx = glb('xyscreen');

if isempty(xypx)
    hfg = figure( 'Units', 'Normalized', 'innerposition', [0 0 1 1]); %use innerposition so it's stable usable plotting area
    hfg.Units = 'pixels';
    tmp = hfg.Position;
    xypx = tmp;
    while isequal(tmp, xypx)
        pause(0.01) %short pause allows figure to resize to fullscreen
        xypx = hfg.Position; %once its new size is registered in properties, exit while loop and output fullscreen size
    end
    close(hfg)
    xypx = [xypx(3) xypx(4)];
end

xyrat = xypx(1)/xypx(2);

end