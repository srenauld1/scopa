function a_ball(dq, t)

arguments
    dq
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

idaq = fieldmatch(dq, lev=1);

figure;
plot(t, dq.(idaq).bh, '-b');
yyaxis right;
plot(t, dq.(idaq).bvf, '-r');
hold on;
plot(t, rescale(dq.(idaq).epochts, min(dq.(idaq).bvf), max(dq.(idaq).bvf)), '-c');


ie=1;
[~, fvtmp] = epochcrop(dq.(idaq).epochts, ie, dq.(idaq).bvf);
tinds = 10000:numel(fvtmp);
figure; histogram(fvtmp(tinds), 50)


figure;
plot(t, dq.(idaq).vh);
yyaxis right;
plot(t, dq.(idaq).bvf);
hold on;
plot(t, dq.(idaq).epochts, 'c');
title('ball yaw (blue), ball forward vel (red), epochs (cyan)')