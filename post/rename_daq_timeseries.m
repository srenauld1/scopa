
function [ball, vis, ti] = rename_daq_timeseries(daqrs)

ball.yaw = single(daqrs.ficTracYaw{1}');
ball.yawvel = single(daqrs.ficTracYaw_diff{1}');
ball.intfor = single(daqrs.ficTracIntForward{1}');
ball.forvel = single(daqrs.ficTracIntForward_diff{1}');
ball.intside = single(daqrs.ficTracIntSide{1}');
ball.sidevel = single(daqrs.ficTracIntSide_diff{1}');
vis.yaw = single(daqrs.g4panels{1}');
vis.yawvel = single(daqrs.g4panels_diff{1}');
ti = single(daqrs.Time{:}');