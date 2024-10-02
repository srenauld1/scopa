function [respnew, angnew] = resample_compass(resp, yaw, angnew_range, numcluster_new, resample_smoothfac, doplt)

% use gaussian to downsample and uniformly sample compass
% resp should be roi x time, and the rois represent positions on a circle,
% and their sampling is not uniform, so this function resamples to make it
% uniform, so later the PVA can be computed with less bias

angnew_endpoints = [(angnew_range-(angnew_range/2)-angnew_range), (angnew_range-(angnew_range/2))];
new_sample_distance = angnew_range/numcluster_new; %new/uniform sample distance

angnew = linspace(angnew_endpoints(1),angnew_endpoints(2),numcluster_new+1); % new/uniform sample points
angnew = angnew(1:end-1);

wnlen = 1000000; %just make it big (and even) for accuracy
sig = new_sample_distance*resample_smoothfac; %blur_factor should be 1-2; ie to prevent aliasing in downsample, make sigma 1-2 times larger than the new sample distance
gfx = linspace(angnew_endpoints(1),angnew_endpoints(2),wnlen+1); %gaussian filer yaw
gfx = gfx(1:end-1);
gfy = exp(-((gfx.^2)/(2*sig.^2))); %make a gaussian for downsampling, with mean zero and std the desired sampling width (gaussian full width should be 6-12 times goal sampling distance, 12 is safe but blurry, 6 theoretically can have slight aliasing)
gfy = gfy / norm(vec(gfy),1) * 1;  %normalize, should be pointless here though


respnew = zeros(numcluster_new, size(resp, 2));
if doplt
    figure; hold on;
end

for ai = 1:length(angnew)

    shift = interp1([angnew_endpoints(1),angnew_endpoints(2)], [0, wnlen], angnew(ai)); %find location of new center in terms of sample points
    shift = round(shift - wnlen/2); %since the gaussian is centered on zero, shift must be shifted by half sample points
    gfy2 = circshift(gfy, shift); %shift gaussian to new center
    if doplt
        plot(gfx, gfy2)
    end

    upsampfac = 2.25; %greater than 2 to more than double nyquist (for current minimum sampling size)
    ang_diffs = angdiff(yaw); 
    diffs_nonzero = ang_diffs(ang_diffs~=0); %remove diffs that are zero, since this will make num_upsamples == inf
    num_upsamples = angnew_range / (min(abs(diffs_nonzero))/upsampfac); %new sampling of whole circle, based on the current minimum sample size 
    [alphasort, alphasortinds] = sort(yaw);
    alphacat = [alphasort alphasort(1)+angnew_range]; %concatenate [first sample + angnew_range] to end to make a circle (add angnew_range to make sure interpolation goes in right direction
    xup = linspace(1, length(alphacat), num_upsamples+1);
    alphaup = interp1(alphacat, xup);
    alphaup = wrapToPi(alphaup(1:end-1));
    alphatrans = interp1([angnew_endpoints(1),angnew_endpoints(2)], [1, wnlen], alphaup); %interpolate from roi yaw (neural compass) to yaw of filter 
    wts = interp1(gfy2, alphatrans); %find y value of gaussian at each position

    respsort = resp(alphasortinds,:);
    respcat = cat(1, respsort, respsort(1,:)); 
    respup = interp1(respcat, xup);
    respup = respup(1:end-1, :);

    respnew(ai,:) = wts*respup;


end