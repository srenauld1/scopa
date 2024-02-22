function [resp_new, alpha_new] = resample_compass(resp, domain, numcluster_new, resample_smoothfac, doplots)

% use gaussian to downsample and uniformly sample compass
% resp should be roi x time, and the rois represent positions on a circle,
% and their sampling is not uniform, so this function resamples to make it
% uniform, so later the PVA can be computed with less bias

new_sample_distance = 2*pi/numcluster_new; %new/uniform sample distance

alpha_new = linspace(-pi,pi,numcluster_new+1); % new/uniform sample points
alpha_new = alpha_new(1:end-1);

wnlen = 1000000; %just make it big (and even) for accuracy
sig = new_sample_distance*resample_smoothfac; %blur_factor should be 1-2; ie to prevent aliasing in downsample, make sigma 1-2 times larger than the new sample distance
gfx = linspace(-pi,pi,wnlen+1); %gaussian filer domain
gfx = gfx(1:end-1);
gfy = exp(-((gfx.^2)/(2*sig.^2))); %make a gaussian for downsampling, with mean zero and std the desired sampling width (gaussian full width should be 6-12 times goal sampling distance, 12 is safe but blurry, 6 theoretically can have slight aliasing)
gfy = gfy / norm(vec(gfy),1) * 1;  %normalize, should be pointless here though


resp_new = zeros(numcluster_new, size(resp, 2));
if doplots
    figure; hold on;
end
for ai = 1:length(alpha_new)

    shift = interp1([-pi, pi], [0, wnlen], alpha_new(ai)); %find location of new center in terms of sample points
    shift = round(shift - wnlen/2); %since the gaussian is centered on zero, shift must be shifted by half sample points
    gfy2 = circshift(gfy, shift); %shift gaussian to new center
    if doplots
        plot(gfx, gfy2)
    end

    upsampfac = 2.25; %greater than 2 to more than double nyquist 
    num_upsamples = 2*pi / (min(abs(angdiff(domain)))/upsampfac); %new sampling of whole circle

    [alphasort, alphasortinds] = sort(domain);
    alphacat = [alphasort alphasort(1)+2*pi]; %concatenate [first sample + 2pi] to end to make a circle (add 2pi to make sure interpolation goes in right direction
    xup = linspace(1, length(alphacat), num_upsamples+1);
    alphaup = interp1(alphacat, xup);
    alphaup = wrapToPi(alphaup(1:end-1));
    alphatrans = interp1([-pi pi], [1, wnlen], alphaup); %interpolate from roi domain (neural compass) to domain of filter 
    wts = interp1(gfy2, alphatrans); %find y value of gaussian at each position

    respsort = resp(alphasortinds,:);
    respcat = cat(1, respsort, respsort(1,:)); 
    respup = interp1(respcat, xup);
    respup = respup(1:end-1, :);

    resp_new(ai,:) = wts*respup;
end