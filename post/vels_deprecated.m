function [respgartmp2, respgaltmp2, respnortmp2, ...
    respnoltmp2, meangtmp2, meanntmp2] = ...
    vels_deprecated(md, cue, ball, mu, ...
    amptmp, amp_peaktmp, amp_mutmp, resp2, ...
    epochinds, smooth_tau, diff_tau, fnprefix)


cue(cue==193) = 192; %frame 193 is darkness at end of trial, just replace with 192 for now as dummy (to not affect unwrapping), then fix later
cue = cue / (md.num_panel_frames + 1) * 2*pi - pi;

%in transitioning from max to min (eg 192 to 0), there is sometimes an intermediate value,
% presumably a sample taken as the voltage makes the large transition,
% so smooth those out with tiny window in the unwrapped stim, otherwise there are spikes
%stimo = wrapToPi(filloutliers(unwrap(stimo), "linear", "movmedian", [1 1]));
cue = wrapToPi(movmean(unwrap(cue), [4 4], 'omitmissing'));

respgartmp2 = rescale(resp2{end}.gar);
respgaltmp2 = rescale(resp2{end}.gal);
respnortmp2 = rescale(resp2{end}.nor);
respnoltmp2 = rescale(resp2{end}.nol);
meangtmp2 = rescale(mean([respgartmp2; respgaltmp2], 1));
meanntmp2 = rescale(mean([respnortmp2; respnoltmp2], 1));


respgartmp = interp1(md.ti,respgartmp2,md.tb)'; %upsample resp rather than downsample stim
respgaltmp = interp1(md.ti,respgaltmp2,md.tb)'; %upsample resp rather than downsample stim
respnortmp = interp1(md.ti,respnortmp2,md.tb)'; %upsample resp rather than downsample stim
respnoltmp = interp1(md.ti,respnoltmp2,md.tb)'; %upsample resp rather than downsample stim
meangtmp = interp1(md.ti,meangtmp2,md.tb)'; %upsample resp rather than downsample stim
meanntmp = interp1(md.ti,meanntmp2,md.tb)'; %upsample resp rather than downsample stim


amptmp = interp1(md.ti,amptmp,md.tb)'; %upsample resp rather than downsample stim
amp_peaktmp = interp1(md.ti,amp_peaktmp,md.tb)'; %upsample resp rather than downsample stim
amp_mutmp = interp1(md.ti,amp_mutmp,md.tb)'; %upsample resp rather than downsample stim

mu = interp1(md.ti,mu,md.tb)'; %upsample resp rather than downsample stim



%% find velocities


if diff_tau %smoothed estimate of stim velocity
    %%

    if diff_tau==0.5
        nframfilt = 8;
    elseif diff_tau==3
        nframfilt = 40;
    end
    xfilt = 0:nframfilt-1;
    tc = 1;
    tau1 = diff_tau;
    tau2 = tau1+1e-2;
    tftmp1 = (xfilt./(tau1^2)).*exp(-xfilt./tau1);
    tftmp1 = tftmp1 / norm(vec(tftmp1),1) * 1; %normalize each phase by L1 before taking diff so filt sums to zero
    tftmp2 = (xfilt./(tau2^2)).*exp(-xfilt./tau2);
    tftmp2 = tftmp2 / norm(vec(tftmp2),1) * 1;  %normalize each phase by L1 before taking diff so filt sums to zero
    tf2 = tftmp1 - tc*tftmp2; %not bothering with envelope subtraction because above hack works to make it sum to zero
    figure; plot(tf2)
%% 

    cueveltmp = conv(unwrap(cue), tf2, 'full');
    cueveltmp = cueveltmp((length(tf2) - 1)+1:end-(length(tf2) - 1)); %crop beginning and end of full conv

    bumpveltmp = conv(unwrap(mu), tf2, 'full');
    bumpveltmp = bumpveltmp((length(tf2) - 1)+1:end-(length(tf2) - 1)); %crop beginning and end of full conv

    ballveltmp = conv(unwrap(ball), tf2, 'full');
    ballveltmp = ballveltmp((length(tf2) - 1)+1:end-(length(tf2) - 1)); %crop beginning and end of full conv

    amptmp = amptmp((length(tf2) - 1)+1:end); %crop beginning 
    amp_peaktmp = amp_peaktmp((length(tf2) - 1)+1:end); %crop beginning 
    amp_mutmp = amp_mutmp((length(tf2) - 1)+1:end); %crop beginning
    respgartmp = respgartmp((length(tf2) - 1)+1:end); %crop beginning 
    respgaltmp = respgaltmp((length(tf2) - 1)+1:end); %crop beginning 
    respnortmp = respnortmp((length(tf2) - 1)+1:end); %crop beginning 
    respnoltmp = respnoltmp((length(tf2) - 1)+1:end); %crop beginning 
    meangtmp = meangtmp((length(tf2) - 1)+1:end); %crop beginning and 
    meanntmp = meanntmp((length(tf2) - 1)+1:end); %crop beginning and 

else %else it is instantaneous (noisier)

    cueveltmp = [diff(unwrap(stim_reconst)) ; 0] / mean(diff(md.tb));

end


for rind = 1:length(epochinds)

    epochindstmp = epochinds{rind};
    indz1 = find(md.stimepochinds_b==epochinds{rind}');
    indz1(indz1>length(cueveltmp)) = []; %there may be some beyond modeling indices since we cropped for full convolution 
    tnew = md.tb(indz1);

    amp = amptmp(indz1);
    amp_peak = amp_peaktmp(indz1);
    amp_mu = amp_mutmp(indz1);
    respgal = respgaltmp(indz1);
    respgar = respgartmp(indz1);
    respnol = respnoltmp(indz1);
    respnor = respnortmp(indz1);
    meang = meangtmp(indz1);
    meann = meanntmp(indz1);
    bumpvel = bumpveltmp(indz1);
    cuevel = cueveltmp(indz1);
    ballvel = ballveltmp(indz1);

    %% 

    % noise_scalefac = 0;
    % noiseadd = noise_scalefac*std(ballvel)*(rand(size(ballvel)));
    % noiseaddpos = noise_scalefac*std(ballvel)*(rand(size(ballvel)));
    % ballvelnoise = ballvel + noiseadd;
    % ballvelnoisepos = 6*ballvel.^3 + 2*ballvel.^2 + noiseaddpos + 0;
    % ballvelnoisepos = ballvel + noiseaddpos + 0;
    % indiest = 100:400; figure; 
    % subplot(2,1,1); plot(ballvel(indiest)); yyaxis right; plot(ballvelnoise(indiest))
    % subplot(2,1,2); plot(ballvel(indiest)); yyaxis right; plot(ballvelnoisepos(indiest))
    % bigx = cat(2, meann, ballvel, ballvelnoise, ballvelnoisepos, bumpvel);
    % bigx = double(bigx);
    % [sValue,condIdx,VarDecomp] = collintest(bigx);
    
    %% 
    
    %adftest(Y)
    
    
    %% 

    % scatterplots_3d(amp, amp_peak, amp_mu, respgal, respgar, respnol, ...
    %     respnor, meang, meann, bumpvel, cuevel, ballvel, epochindstmp, fnprefix)

    close all

    save([fnprefix '_' num2str(epochindstmp) '_scatter3data.mat'], 'cue', 'ball', 'mu', 'bumpvel', 'cuevel', 'ballvel', 'meang', 'meann', 'respgar', 'respgal', 'respnor', 'respnol', 'amp', 'amp_mu', 'amp_peak', 'md', '-v7.3', '-mat')


end







