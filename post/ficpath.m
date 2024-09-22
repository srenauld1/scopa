function [posx, posy] = ficpath(velfor, velside, yaw, t, balldia)

yawAngPos = rad2deg(yaw);
fwdAngVel = rad2deg(velfor / (balldia/2));
slideAngVel = rad2deg(velside / (balldia/2));
mmPerDeg = balldia * pi / 360; % mm per degree of ball
zeroedYawAngPos = yawAngPos - yawAngPos(1);
sampRate = median(diff(t));
xChangePos = (fwdAngVel ./ sampRate) .* sind(zeroedYawAngPos) + (slideAngVel ./ sampRate) .* sind(zeroedYawAngPos + 90);
posx = (cumsum(xChangePos) - xChangePos(1)) .* mmPerDeg;
yChangePos = (fwdAngVel ./ sampRate) .* cosd(zeroedYawAngPos) + (slideAngVel ./ sampRate) .* cosd(zeroedYawAngPos + 90);
posy = (cumsum(yChangePos) - yChangePos(1)) .* mmPerDeg;

end


