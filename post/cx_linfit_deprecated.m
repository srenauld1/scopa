function [lfit, lfitcn]  = cx_linfit_deprecated(md, stim, resp, fitlen, ...
    pvar, respnorm, epochinds, resample_target, linfit_method, ...
    smooth_tau, diff_tau, fit_to_sphere, doplots)


numfilters = 0;
numframes_total = 0;

stim_is_centered = 1;
numcheck = 32;
checkinds = round(linspace(1, size(resp, 1), numcheck));

"REMOVING G4 FRAME 193 REMOVING G4 FRAME 193 REMOVING G4 FRAME 193 REMOVING G4 FRAME 193 REMOVING G4 FRAME 193 REMOVING G4 FRAME 193 REMOVING G4 FRAME 193 "
%frame 193 is darkness at end of trial, just replace with 192 for now as dummy (to not affect unwrapping), then fix later 
% (do not replace with nan because sometimes intended 192 is assigned 193 presumably because of electrical noise, ie 193 doesn't just occur during the dark period at the end, even though it's supposed to)

stim(stim==193) = 192; 
stim = stim / (md.num_panel_frames + 1) * 2*pi - pi; %put in range -pi to pi

%in transitioning from max to min (eg 192 to 0), or vice versa, there is sometimes an intermediate value,
% presumably a sample taken as the voltage makes the large transition,
% so smooth those out with tiny window in the unwrapped stim, otherwise there are spikes
%stimo = wrapToPi(filloutliers(unwrap(stimo), "linear", "movmedian", [1 1]));
%stim = wrapToPi(movmedian(unwrap(stim), [2 2], 'omitnan'));

stimx = cos(stim);
stimy = sin(stim);

if strcmp(resample_target, 'resp')

    fitlen_samples = round(fitlen/mean(diff(md.tb)));

    for ri = 1:size(resp, 1)
        resptmp = resp(ri,:);
        resptmp = interp1(md.ti,resptmp,md.tb)'; %upsample resp rather than downsample stim
        respnew(ri,:) = resptmp';
    end

elseif strcmp(resample_target, 'stim')

    dsfac = (length(md.ti)/max(md.ti)) / (length(md.tb)/max(md.tb));
    [dsnr, dsdr] = rat(dsfac);
    stimx = resample(stimx, dsnr, dsdr+1);
    stimy = resample(stimy, dsnr, dsdr+1);

    if size(stimx)~=size(resp,2)
        error
    end

end

%% smooth the stim 

if smooth_tau %smooth stim with monophasic decay (simulate applying neuron "impulse response" before correlating with response)
    % 
    % nframfilt = 100;
    % xfilt = 0:nframfilt-1;
    % tau1 = smooth_tau;
    % tf1 = (xfilt./(tau1^2)).*exp(-xfilt./tau1);
    % tf1 = tf1 / norm(vec(tf1),1) * 1; %normalize by L1 norm
    % figure; plot(tf1)
    % 
    % stimx = conv(stimx, tf1, 'full');
    % stimx = stimx((length(tf1) - 1)+1:end-(length(tf1) - 1)); %crop beginning and end of full conv
    % stimy = conv(stimy, tf1, 'full');
    % stimy = stimy((length(tf1) - 1)+1:end-(length(tf1) - 1)); %crop beginning and end of full conv
    % numfilters = numfilters + 1;
    % numframes_total = numframes_total + nframfilt;

    stimx = smoothdata(stimx, 'gaussian', 40, 'omitnan');
    stimy = smoothdata(stimy, 'gaussian', 40, 'omitnan');
    stimsmooth = atan2(stimy, stimx);
    figure; plot(unwrap((stimsmooth(:))));



end

%% find stim velocity

if diff_tau %smoothed estimate of stim velocity

    nframfilt = 25;
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

    stimxd = conv(stimx, tf2, 'full');
    stimxd = stimxd((length(tf2) - 1)+1:end-(length(tf2) - 1)); %crop beginning and end of full conv
    stimyd = conv(stimy, tf2, 'full');
    stimyd = stimyd((length(tf2) - 1)+1:end-(length(tf2) - 1)); %crop beginning and end of full conv

    stimx = stimx((length(tf2) - 1)+1:end);
    stimy = stimy((length(tf2) - 1)+1:end);

    denom = stimx.^2 + stimy.^2;
    stimvel = (-stimy ./ denom).*stimxd + (stimx ./ denom).*stimyd;

    numfilters = numfilters + 1;
    numframes_total = numframes_total + nframfilt;

    % stimvel = conv(unwrap(stim_reconst), tf2, 'full');
    % stimvel = stimvel((length(tf2) - 1)+1:end-(length(tf2) - 1)); %crop beginning and end of full conv

else %else it is instantaneous (noisier)

    stimvel = [diff(unwrap(stim_reconst)) ; 0] / mean(diff(md.tb));

end
% 
% %crop these so it matches the filtered stim
% stimx = stimx((length(tf2) - 1)+1:end); %crop beginning and end of full conv
% stimy = stimy((length(tf2) - 1)+1:end); %crop beginning and end of full conv
% stim_reconst = stim_reconst((length(tf2) - 1)+1:end); %crop beginning and end of full conv
respnew = respnew(:,(length(tf2) - 1)+1:end); %crop beginning but not end of response to match cropped smoothed stim
%stimvel = stimvel((numframes_total - numfilters)+1:end-(numframes_total - numfilters));
stim_reconst = atan2(stimy, stimx);

if fit_to_sphere
    vel_rescale_mag = pi/2;
else
    vel_rescale_mag = 1;
end

%rescale velocity independently for each direction
stimvel(stimvel<=0) = rescale(stimvel(stimvel<=0), -vel_rescale_mag, 0);
stimvel(stimvel>=0) = rescale(stimvel(stimvel>=0), 0, vel_rescale_mag);

%% stim-response model

keepinds = find(ismember(md.stimepochinds, epochinds)); %md.ti<seconds(md.dark_epoch_time_start);
tnew = md.ti(:, keepinds);

stimx = cos(stim_reconst);
stimy = sin(stim_reconst);
stimnew = [stimx stimy stimvel]';

if ~strcmp(linfit_method, 'svd') &  ~strcmp(linfit_method, 'inverse')
    fitlen_samples = 1;
end
lfit = zeros(size(respnew, 1), 2, fitlen_samples);
lfitcn = zeros(size(respnew, 1), 2, fitlen_samples);

countz = 0;
for ri = 1:size(respnew, 1)

    respnew2 = respnew(ri,:);

    switch linfit_method

        case 'svd'

            lfittmp = cx_linfitsvd( stimnew, respnew2, fitlen_samples, pvar, stim_is_centered, respnorm);

        case 'inverse' %are increases valued the same as decreases?

            respnew2 = rescale(1 - respnew2);
            lfittmp = cx_linfitsvd( stimnew, respnew2, fitlen_samples, pvar, stim_is_centered, respnorm);

        case 'vec' %vector average

            lfittmp = nanmean(stimnew.*respnew2, 2);

        case {'max', 'min'}

            if strcmp(linfit_method, 'max') %stim value at max response index

                [~, ind] = max(respnew2);
                lfittmp = stimnew(ind);

            elseif strcmp(linfit_method, 'min') %stim value pi away from the min response index

                [~, ind] = min(respnew2);
                lfittmp = wrapToPi(stimnew(ind) + pi);

            end

    end



    if doplots

        if ri == size(respnew, 1)
            figure; subplot(2,1,1); imagesc(squeeze(lfit(:,1,:)))
            subplot(2,1,2); imagesc(squeeze(lfit(:,2,:)))
        end  

        if ismember(ri, checkinds)
            countz = countz + 1;
            [stimcheck{countz}, stimsortinds] = sort(atan2(stimnew(2,:), stimnew(1,:)));
            respcheck{countz} = respnew2(stimsortinds);
        end

    end


    if size(lfittmp, 1)==2
        lfit(ri,1,:) = cart2pol(lfittmp(1,:), lfittmp(2,:)); %cart2pol(x,y) same as atan2(y,x)
    elseif size(lfittmp, 1)==3
        %should the 3 components of the stim (x, y, vel) be considered
        %components of a single quantity (embedded in a sphere)?
        %the results look more orderly, but is that just artifact?
        if fit_to_sphere
            [lfit(ri,1,:), lfit(ri,2,:)] = cart2sph(lfittmp(1,:), lfittmp(2,:), lfittmp(3,:));
        else
            lfit(ri,1,:) = atan2(lfittmp(2,:), lfittmp(1,:));
            lfit(ri,2,:) = lfittmp(3,:);
        end
    end


end


if doplots

    colord = distinguishable_colors(numcheck);

    figure;
    for rci = 1:length(respcheck)
        subplot(numcheck/4, 4, rci)
        plot(stimcheck{rci}, respcheck{rci}) %'color',  colord(1,:))
    end

    figure; scatter(mean(lfit(:,1,:), 3), mean(lfit(:,2,:), 3))

    figure; plot(mean(lfit(:,1,:), 3))


    % figure;
    % mxv = max(vec(lfittmp(:,2,:)));
    % mnv = min(vec(lfittmp(:,2,:)));
    % zci = @(v) find(diff(sign(v)));
    % countz = 0;
    % for imi = round(linspace(1, size(lfittmp,1), size(lfittmp,1)))
    %     countz = countz+1;
    %     pvone = squeeze(lfittmp(imi,2,:));
    %     plot(pvone)
    %     ylim([mnv mxv])
    %     %pause(0.2)
    %     if any(zci(pvone))
    %         markit(countz) = 1;
    %     end
    % end


    %3d plot
    % x = double(atan2(stimnew(2,:), stimnew(1,:)))';
    % y = double(stimnew(3,:))';
    % z = double(respnew2)';
    % figure;
    % plot3(x, y, z, '.');
    % grid on


    % 2d scatter with color
    % % cmap = jet(256);
    % % v = rescale(respnew2, 1, 256); % Nifty trick!
    % % numValues = length(respnew2);
    % % mkc = zeros(numValues, 3);
    % % for k = 1 : numValues
    % %     row = round(v(k));
    % %     mkc(k, :) = cmap(row, :);
    % % end
    % % figure;
    % % scatter(atan2(stimnew(2,:), stimnew(1,:)),  stimnew(3,:), 5, mkc, 'filled');
    % % grid on;



    % plots to test stim or response resampling
    % xlimb = [50 100];
    % if strcmp(resample_target, 'resp') %make sure resampled resp looks like the original
    %
    %     figure; hold on
    %     plot(md.ti, resp);
    %     plot(tnew, respnew);
    %     xlim(xlimb)
    %     title("response resampling check")
    %
    % elseif strcmp(resample_target, 'stim') %make sure resampled stim looks like the original (comparing two methods)
    %
    %     figure; hold on;
    %     plot(tnew, atan2(stimnew(2,:), stimnew(1,:)));
    %     plot(tnew, stimnew_alt);
    %     plot(md.tb(keepinds), stimo(keepinds));
    %     xlim(xlimb)
    %     title("stim resampling check")
    %
    %
    % end

end

