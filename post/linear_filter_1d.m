function filt = linear_filter_1d(tau1, tau2, shift, tc, filtnorm, numsamp, doplots)

if ~exist('doplots', 'var')
    doplots = 0;
end

x = 0:numsamp-1;

b1 = x./tau1^2.*exp(-x./tau1);
b1 = b1 / norm(vec(b1(:)),1);
b2 = x./tau2^2.*exp(-x./tau2);
b2 = b2 / norm(vec(b2(:)),1) * tc;

filt = b1-1*b2;

if doplots
    filtplot = filt / norm(vec(filt(:)),1) * filtnorm; %normalize by L1
    figure; plot(filtplot); hold on;
end

filt = fraccircshift(filt,shift);

filt = filt / norm(vec(filt(:)),1) * filtnorm; %normalize by L1

if doplots
    plot(filt);
end

end