
function [ts, ti] = assign_a2p_timeseries(daqdata_resamp)

ts.ball.yaw = daqdata_resamp.ficTracYaw{1};
ts.ball.yawvel = daqdata_resamp.ficTracYaw_diff{1};
ts.ball.intfor = daqdata_resamp.ficTracIntForward{1};
ts.ball.forvel = daqdata_resamp.ficTracIntForward_diff{1};
ts.ball.intside = daqdata_resamp.ficTracIntSide{1};
ts.ball.sidevel = daqdata_resamp.ficTracIntSide_diff{1};
ts.vis.ang = daqdata_resamp.g4panels{1};
ts.vis.angvel = daqdata_resamp.g4panels_diff{1};
ti = daqdata_resamp.Time{:};