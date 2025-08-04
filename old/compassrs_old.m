function [resprs, angrs] = compassrs_old(resp, ang, angrngrs, numangrs, smfac, doplt)

% use gaussian to downsample and uniformly sample compass
% resp should be roi x time, and the rois represent positions on a circle,
% and their sampling is not uniform, so this function resamples to make it
% uniform, so later the PVA can be computed with less bias

arguments
    resp %neural response, (roi,time), each roi represents an angle of a circle
    ang %vector of angles represented by each roi; length must equal size(resp,1)
    angrngrs %scalar, resampled compass angle range (e.g. 2*pi)
    numangrs %number angles in resampled compass
    smfac = 1 %proportional to downsampling gaussian's std
    doplt = 0 %do plots
end
upsampfac = 2.25; %upsample prior to downsample; should be greater than 2 to more than double nyquist for minimum sample angle
wnlen = 1000000; %numsamples for downsampling gaussian; just make it very big (and even) for accuracy
maxf = 200; %max frequency around circle we care to capture in output; we don't actually care about resolving the compass to ths level of detail (>1/200th of a circle); if angles differ by very little, it is because of noise, so just force this max frequency 

angrs_endpoints = [(angrngrs-(angrngrs/2)-angrngrs), (angrngrs-(angrngrs/2))];
new_sample_distance = angrngrs/numangrs; %new/uniform sample distance

angrs = linspace(angrs_endpoints(1),angrs_endpoints(2),numangrs+1); % new/uniform sample points
angrs = angrs(1:end-1);

sig = new_sample_distance*smfac; %blur_factor should be 1-2; to prevent aliasing in downsample, make sigma 1-2 times larger than the new sample distance
gfx = linspace(angrs_endpoints(1),angrs_endpoints(2),wnlen+1); %gaussian filer ang
gfx = gfx(1:end-1);
gfy = exp(-((gfx.^2)/(2*sig.^2))); %make a gaussian for downsampling, with mean zero and std the desired sampling width (gaussian full width should be 6-12 times goal sampling distance, 12 is safe but blurry, 6 theoretically can have slight aliasing)
gfy = gfy / norm(vec(gfy),1) * 1;  %normalize, should be pointless here though


resprs = zeros(numangrs, size(resp, 2));
if doplt
    figure; hold on;
end

for ai = 1:length(angrs)

    shift = interp1([angrs_endpoints(1),angrs_endpoints(2)], [0, wnlen], angrs(ai)); %find location of new center in terms of sample points
    shift = round(shift - wnlen/2); %since the gaussian is centered on zero, shift must be shifted by half sample points
    gfy2 = circshift(gfy, shift); %shift gaussian to new center
    if doplt
        plot(gfx, gfy2)
    end

    ang_diffs = angdiff(ang);
    diffs_nonzero = ang_diffs(ang_diffs~=0); %remove diffs that are zero, since this will make num_upsamples == inf
    % num_upsamples = angrngrs / (mean(abs(diffs_nonzero))/upsampfac); %new sampling of whole circle, based on the current minimum sample size
    num_upsamples = angrngrs / (min(abs(diffs_nonzero))/upsampfac); %new sampling of whole circle, based on the current minimum sample size
    if num_upsamples>maxf 
        num_upsamples = 200;
    end
    [alphasort, alphasortinds] = sort(ang);
    alphacat = [alphasort alphasort(1)+angrngrs]; %concatenate [first sample + angrngrs] to end to make a circle (add angrngrs to make sure interpolation goes in right direction
    xup = linspace(1, length(alphacat), num_upsamples+1);
    alphaup = interp1(alphacat, xup);
    alphaup = wrapToPi(alphaup(1:end-1));
    alphatrans = interp1([angrs_endpoints(1),angrs_endpoints(2)], [1, wnlen], alphaup); %interpolate from roi ang (neural compass) to ang of filter
    wts = interp1(gfy2, alphatrans); %find y value of gaussian at each position

    %figure; plot(wts); yyaxis right; plot(alphatrans) %show the weights and the upsampled alpha
    %tmp = linspace(1,wnlen,1312); tmp(200:end) = tmp(201); figure; plot(interp1(gfy2, tmp)); yyaxis right; plot(interp1(gfy2, linspace(1,numel(gfy2),numel(alphatrans)))); %demonstration of the resampling weights; imagine they were uniform to 200, then the rest are unchanging 201 to the end

    respsort = resp(alphasortinds,:);
    respcat = cat(1, respsort, respsort(1,:));
    respup = interp1(respcat, xup);
    respup = respup(1:end-1, :);

    resprs(ai,:) = wts*respup;

    if ai==16 && doplt

        nfr = 30;
        pthgif = [];
        if isempty(pthgif)
            pthgif = pathauto(suffix='discont_oldrs_.gif', usetime=1);
        end
        hfg = figure;
        hax = axes(Parent=hfg);
        fcnt = 0;
        for k = round(linspace(1,size(resp,2), nfr))
            fcnt = fcnt+1;
            if fcnt==1
                hpl1 = plot(hax, ang(alphasortinds), resp(alphasortinds,k));
                yyaxis right;
                hpl2 = plot(hax, angrs, resprs(:,k));
            else
                hpl1.YData = resp(alphasortinds,k);
                hpl2.YData = resprs(:,k);
            end
            fig2gif(hfg, fcnt, pthgif)
        end

        pthgif = strrep(pthgif, 'discont_oldrs', 'cont');

        hfg = figure;
        hax = axes(Parent=hfg);
        pltinds = round(size(resp,2)/2:(size(resp,2)/2)+nfr);
        pltinds(pltinds>size(resp,2)) = [];
        fcnt = 0;
        for k = pltinds
            fcnt = fcnt+1;
            if fcnt==1
                hpl1 = plot(hax, ang(alphasortinds), resp(alphasortinds,k));
                yyaxis right;
                hpl2 = plot(hax, angrs, resprs(:,k));
            else
                hpl1.YData = resp(alphasortinds,k);
                hpl2.YData = resprs(:,k);
            end
            fig2gif(hfg, fcnt, pthgif)
        end
    end

end



