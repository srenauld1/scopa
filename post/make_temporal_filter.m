function tf = make_temporal_filter(nframfilt, tau1, tau2, tc)

xfilt = 0:nframfilt-1;
tftmp1 = (xfilt./(tau1^2)).*exp(-xfilt./tau1);
tftmp1 = tftmp1 / norm(vec(tftmp1),1) * 1; %normalize each phase by L1 before taking diff so filt sums to zero
tftmp2 = (xfilt./(tau2^2)).*exp(-xfilt./tau2);
tftmp2 = tftmp2 / norm(vec(tftmp2),1) * 1;  %normalize each phase by L1 before taking diff so filt sums to zero
tf = tftmp1 - tc*tftmp2; %not bothering with envelope subtraction because above hack works to make it sum to zero

end