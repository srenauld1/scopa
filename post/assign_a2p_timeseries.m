
function [ball, vis, ti] = assign_a2p_timeseries(daqdata_resamp)

ball.yaw = daqdata_resamp.ficTracYaw{1};
ball.yawvel = daqdata_resamp.ficTracYaw_diff{1};
ball.intfor = daqdata_resamp.ficTracIntForward{1};
ball.forvel = daqdata_resamp.ficTracIntForward_diff{1};
ball.intside = daqdata_resamp.ficTracIntSide{1};
ball.sidevel = daqdata_resamp.ficTracIntSide_diff{1};
vis.ang = daqdata_resamp.g4panels{1};
vis.angvel = daqdata_resamp.g4panels_diff{1};
ti = daqdata_resamp.Time{:};