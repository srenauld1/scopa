
function [ball, vis, ti] = assign_a2p_timeseries(daqrs)

ball.yaw = daqrs.ficTracYaw{1};
ball.yawvel = daqrs.ficTracYaw_diff{1};
ball.intfor = daqrs.ficTracIntForward{1};
ball.forvel = daqrs.ficTracIntForward_diff{1};
ball.intside = daqrs.ficTracIntSide{1};
ball.sidevel = daqrs.ficTracIntSide_diff{1};
vis.ang = daqrs.g4panels{1};
vis.angvel = daqrs.g4panels_diff{1};
ti = daqrs.Time{:};