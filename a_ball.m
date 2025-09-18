function a_ball(daq, t)

arguments
    daq
    t = []
end

t_glb = glb('t');
if isempty(t)
    if isempty(t_glb)
        error("you must pass in t or set glb('t')")
    else
        t = t_glb;
    end
else
    if ~isempty(t_glb)
        if ~isequal(t, t_glb)
            error("you have set both name-value argument t and glb('t'), but they are not equal")
        end
    end
end

idaq = fieldmatch(daq, lev=1);

figure;
plot(t, daq.(idaq).by, '-b');
yyaxis right;
plot(t, daq.(idaq).bfv, '-r');
hold on;
plot(t, rescale(daq.(idaq).epochts, min(daq.(idaq).bfv), max(daq.(idaq).bfv)), '-c');


ie=1;
[~, fvtmp] = epochcrop(daq.(idaq).epochts, ie, daq.(idaq).bfv);
tinds = 10000:numel(fvtmp);
figure; histogram(fvtmp(tinds), 50)


figure;
plot(t, daq.(idaq).vy);
yyaxis right;
plot(t, daq.(idaq).bfv);
hold on;
plot(t, daq.(idaq).epochts, 'c');
title('ball yaw (blue), ball forward vel (red), epochs (cyan)')