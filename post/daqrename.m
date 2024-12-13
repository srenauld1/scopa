
function [ball, vis, ti] = daqrename(daqrs)

%make sure they're all row vectors

nms = daqrs.Properties.VariableNames;

if any(strcmp('Time',nms))
    ti = single(daqrs.Time{1}(:)');
else
    ti = [];
end
if any(strcmp('g4panels',nms))
    vis.yaw = single(daqrs.g4panels{1}(:)');
    vis.yawvel = single(daqrs.g4panels_dv{1}(:)');
else
    vis.yaw = [];
    vis.yawvel = [];
end
if any(strcmp('ficTracIntForward',nms))
    ball.intfor = single(daqrs.ficTracIntForward{1}(:)');
    ball.forvel = single(daqrs.ficTracIntForward_dv{1}(:)');
else
    ball.intfor = [];
    ball.forvel = [];
end
if any(strcmp('ficTracIntSide',nms))
    ball.intside = single(daqrs.ficTracIntSide{1}(:)');
    ball.sidevel = single(daqrs.ficTracIntSide_dv{1}(:)');
else
    ball.intside = [];
    ball.sidevel = [];
end
if any(strcmp('ficTracYaw',nms))
    ball.yaw = single(daqrs.ficTracYaw{1}(:)');
    ball.yawvel = single(daqrs.ficTracYaw_dv{1}(:)');
elseif any(strcmp('ficTracHeading',nms))
    ball.yaw = single(daqrs.ficTracHeading{1}(:)');
    ball.yawvel = single(daqrs.ficTracHeading_dv{1}(:)');
else
    ball.yaw = [];
    ball.yawvel = [];
end


