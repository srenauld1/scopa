
function [visyaw, visyawvel, epochts, vepochs] = epochld2(recdate, t, visyaw, visyawvel, sper, doplt)

dvlensec = 0.5;
dvord = 2;

tol_dv = 1;
dv = rad2deg(tsdv('radians', visyaw, dvlensec, dvord, sper)); %derivative
dv2 = rad2deg(tsdv('normal', dv2, dvlensec, dvord, sper)); %derivative

fuk = movmedian(dv, 1/sper);
halfwin = 3;
kp = zeros(size(fuk), 'logical');
for k = halfwin+1:numel(fuk)-halfwin
    winn(k) = mean(fuk(k-halfwin:k+halfwin));
    if any(abs(winn(k)-dvnom(1:end-1)')<=tol_dv)
        kp(k) = 1;
    else
        kp(k) = 0;
    end
end
dv2 = dv;
dv2(~kp) = nan;
tsplt(visyaw, dv2, xall=t, ylimtype='each')