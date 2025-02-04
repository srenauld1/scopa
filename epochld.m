function vis = epochld(t, vis, sampper, use_carls_epochs, doplt)

% if it was created/saved during experiment, load 'epochs' (struct containing info about stimulus state during trial, including field epochts, a vector representing stimulus state for each sample of trial)
% if it doesn't exist, create it here with a hack, using derivative of g4panels yaw
% for the ocld protocol, panels derivative defines each open loop condition, and everything else is closed loop
% this algorithm assumes the bout lengths are accurate (they are)
% this algorithm assumes that underflow frames are the same as dark epoch (overflow is when fictrac has ended before the daq ends, since fictrac starts first this can happen if fictrac hasn't been programmed in the socket code to run indefinitely)
% algorithm doesn't deal very well with bouts at the ends i think; or chance matching of sequence for multiple bouts, but that is unlikely
% the reason for using this rather than the timing information written in the socket code controlling the panels
% is the daq record accumulates timing error; so although bouts are all very nearly 20 seconds, over time, the bouts begin later than expected (delay of ~1 second every ~20 minutes)
% using the derivatives aligns epoch indices better than the old approach in epochld_old.m


%THIS ONLY WORKS FOR CARL'S OCLD PROTOCOL, ALTHOUGH MIGHT BE ADAPTED ELSEWHERE

arguments
    t
    vis
    sampper
    use_carls_epochs = []
    doplt = []
end


startepoch = 1; %CAREFUL, IF THIS IS WRONG IT could ALL BE WRONG; which epoch should start the sequence; should always be 1 since closed loop (epoch 6) runs for a full minute first, to account for imaging delay, which has never been more than 50 seconds

boutlensec = 20; %bout length in seconds
closed_initial_len_sec = 60; %length of initial closed loop epoch (used for padding because of imaging delay)
dvnom = [20 80 -20 -80 0]; %nominal derivative for each epoch
has_cl_interleave = 1; %whether open loop bouts are interleaved with closed loop bouts
dark_value = 180; %value given to panels when in dark epoch (unit degrees)

minsepfac = 0.9; %min separation for local min in yaw derivative moving variance is boutlensec*minsepfac; this should a little under 1 to capture all local mins separated by bout length (in case some timing error in daq)
dvlensamp = 3; %window length (unit: samples) for dvord-order polynomial fit to determine slope;
dvord = 2; %order of polynomial fit for extracting local slope;
tol_dv = 1; %tolerance (unit: degrees per second) for dv relative to dvnom (bidirectional)
tol_boutlensec = 1; %tolerance for detecting long bouts
tol_dark = 5; %tolerance determining whether dark_value (unit degrees)
tol_dark_var = 5; %tolerance determining whether variance matches expected variance of dark epoch (unit degrees)

numiter = 2;

numsecseg = 100; %how many seconds in each segment in tsplt plots
xseg = floor(numel(t)/numel(t(t<numsecseg))); %number segments in tsplt plots


if isfield(vis, 'yaw') && use_carls_epochs

    if any(isnan(vis.yaw))
        error("vis.yaw should not have any nans when entering this function (when exiting, it might, if dark epochs exist)")
    end
    if isduration(t)
        t = seconds(t);
    end
    if isrow(t) %why does this matter?
        t = t';
    end

    fprintf("warning, epochs not saved to daq, finding epochs with panels derivatives" + newline)

    ioi = boutlensec*(has_cl_interleave+1); %inter-open loop interval
    boutlensamp = boutlensec/sampper; %bout length in samples
    dvlensec = dvlensamp*sampper; %window length in seconds
    halfboutlensec = boutlensec/2;

    %%% find boutlensec-second windows whose median derivative matches expected %%%

    for iter = 1:numiter
        try

            if iter>1
                %idxbad is not what we want to change
                vis.yaw(idxbad) = rand(sum(idxbad), 1);
            end

            yawdeg = rad2deg(vis.yaw); %convert to degrees because tolerance is in degrees and we like degrees more anyway
            dv = rad2deg(tsdv('circular', deg2rad(yawdeg), dvlensec, dvord, sampper)); %derivative
            mvar = movvar(dv, boutlensamp); %moving variance of derivative should identify epochs for the open-closed-dark protocol (ignoring noise)
            lmin = islocalmin(mvar, MinSeparation=(boutlensec*minsepfac)/sampper); %use islocalmin to get rid of the noise and find where moving variance is minimal ofver boutlen window
            lminfnd = find(lmin);
            lstarts = t(lmin)-halfboutlensec; %start times for all windows
            lstops = t(lmin)+halfboutlensec; %stop times for all windows
            cvar = [];
            cmn = [];
            med = [];
            tmed = [];
            for k = 1:numel(lstarts)
                idx = t>lstarts(k) & t<lstops(k);
                cvar(k) = rad2deg(circ_var(deg2rad(vec(yawdeg(idx)))));
                cmn(k) = rad2deg(circ_mean(deg2rad(vec(yawdeg(idx)))));
                med(k) = median(dv(idx)); %median slope
                tmed(k) = median(t(idx));
            end
            kp = any(abs(med-dvnom')<=tol_dv); %keep windows whose median slope is within tolerance (tol_dv) of any of the expected slopes
            idxbad = t>lstarts(~kp)' & t<lstops(~kp)';

            tmed_notkp1 = tmed(~kp);
            tmed = tmed(kp);
            med = med(kp);
            lstarts = lstarts(kp);
            lstops = lstops(kp);
            medrnd = interp1(dvnom, dvnom, med, 'nearest', 'extrap'); %round medians to nearest dvnom

            % tsplt(vis.yaw, mvar, marks={[], {tmed_notkp1, tmed}}, xall=t, ylimtype='each', xseg=xseg);

            %%% discard any windows whose median doesn't follow periodic open-loop sequence of expected medians (this can be improved, there might be problems if the first median is a match, or if there are more than 2 matches in a row) %%%

            kp2 = epochseq(startepoch, medrnd, dvnom, cmn, cvar, med, dark_value, tol_dark, tol_dark_var);

            tmed_notkp2 = tmed(~kp2);
            tmed = tmed(kp2);
            med = med(kp2);
            medrnd = medrnd(kp2);
            lstarts = lstarts(kp2);
            lstops = lstops(kp2);

            % tsplt(vis.yaw, mvar, marks={[], {tmed_notkp2, tmed}}, xall=t, ylimtype='each', xseg=xseg);

            %%% make sure all bouts are expected length, except for possible long bouts at the end (when fictrac ends before daq and those bouts get classified as dark bouts because their derivative is 0)  %%%

            meds_t_dv = diff(tmed);
            badlenbouts = abs(meds_t_dv-ioi)>=tol_boutlensec;
            first_good_len_bout = find(~badlenbouts, 1);
            last_good_len_bout = find(~badlenbouts, 1, 'last');

            if sum(badlenbouts(first_good_len_bout:last_good_len_bout))~=0
                error("long or short bouts can only be at the ends")
            end

            %%% make sure you have the expected number of bouts, and that the daq_delay is not unusual %%%

            numbouts_ol = numel(tmed);
            maxgoodtime = max(tmed); %centroid of last open loop bout
            numbouts_ol_expected = ceil(maxgoodtime / (ioi)); %ceil, since these are centroids
            daq_delay = closed_initial_len_sec - (tmed(1) - halfboutlensec);

            if numbouts_ol~=numbouts_ol_expected
                error("you did not recover the expected number of bouts")
            end
            if daq_delay>60
                error("warning, daq starts more than a minute after fictrac/panels/socket; this has never happened before, check that it is okay")
            end
            if daq_delay<0
                error("daq starts before fictrac; this has never happened")
            end

            %%% assign epoch labels %%%

            numepoch_ol_expected = numel(dvnom);
            numepoch_ol = numel(unique(medrnd));
            if numepoch_ol~=numepoch_ol_expected
                error("num derived epochs does not match number expected")
            end

            break;

        catch ME
            fprintf("" + ME.message + newline)
            fprintf("trying another iteration" + newline)
            if iter==numiter
                fprintf("could not extract epochs in numiter iterations" + newline)
            end
        end
    end

    numepoch_expected = numepoch_ol_expected + has_cl_interleave;
    epochts = ones(size(t))*numepoch_expected;
    for k = 1:numel(tmed)
        if all(medrnd(k:end)==0) %when fictrac turns off, consider this dark epoch
            idxtmp = find(medrnd(k)==dvnom);
            epochts(idxstop:end) = idxtmp; %this is the previous bout's idxstop
            break
        else
            if k>1 && badlenbouts(k-1) %classify badlenbouts as dark for now
                idxbad = t>lstarts(k-1) & t<lstops(k-1);
                epochts(idxbad) = numepoch_expected-1;
            else
                starttmp = tmed(k) - halfboutlensec;
                [~, idxstart] = min(abs(t-starttmp));
                stoptmp = tmed(k) + halfboutlensec;
                [~, idxstop] = min(abs(t-stoptmp));
                idxtmp = find(medrnd(k)==dvnom);
                epochts(idxstart:idxstop) = idxtmp;
            end
        end
    end

    epochts = epochts(:)'; %make it row vector since time is 2nd dim for all timeseries variables (except stack)

    fprintf("assigned any underflow bouts to dark epoch (is this accurate? are the panels off when fictrac ends?)" + newline)

    epochs = epochidget('ocld2');
    %the old way used ocld (not ocld2) IN EPOCHIDGET [epochs, epochinds_old] = epochset(t, id.recdatenum, daq_delay); %%%%%% DEFINE STIM EPOCH INFO AND EXPECTED INDS IN THIS SCRIPT, WILL BE DEPRECATED WHEN SOCKET CODE SAVES EPOCH INDICES DURING EXPERIMENT   %%%%%%%%%  %%%%%%%%%

    if doplt
        tsplt(vis.yaw, single(epochts), xall=t, ylimtype='each', xseg=xseg);
    end

else

    epochs = [];
    epochts = [];
    fprintf("epochs are empty because there is no g4panels data, or because use_carls_epochs is false" + newline)

end


vis.epochs = epochs;
vis.epochts = epochts;
if ~isempty(epochs)
    if isfield(epochs, 'dark') && any(epochts==epochs.dark)
        naninds = epochts==epochs.dark;
        vis.yaw(naninds) = nan; %put nans where the cue doesn't exist (dark epoch)
        vis.yawvel(naninds) = nan; %put nans where the cue doesn't exist (dark epoch)
        if isfield(epochs, 'closedfinaldark') && any(epochts==epochs.closedfinaldark)
            naninds = epochts==epochs.closedfinaldark; %dark gets nans
            vis.yaw(naninds) = nan; %put nans where the cue doesn't exist (dark epoch)
            vis.yawvel(naninds) = nan; %put nans where the cue doesn't exist (dark epoch)
        end
    end
end


end


function kp = epochseq(startepoch, medrnd, dvnom, cmn, cvar, med, dark_value, tol_dark, tol_dark_var)

%remove (remove means classify as closed loop) windows that don't follow sequence of epochs; works for most cases, but is not very robust; for example, if windows that should be removed follow correct sequence for more than 2 epochs (by chance), then desired windows pick up the pattern (out of cycle with the bad windows), the desired windows will be removed; this is highly unlikely however with the ocld protocol

kp = ones(numel(medrnd), 1, 'logical');
knew = 1;
goodstart = 0;
for k = 1:numel(medrnd)
    idx = find(medrnd(k)==dvnom);
    modidx = mod(knew-1,numel(dvnom))+1;
    moddiffcurr = modidx-idx;
    badind = 0;
    % fnd = strfind(medrnd(medrnd~=0), dvnom(dvnom~=0));
    if ~goodstart %if the sequence hasn't started
        if ~isequal(medrnd(k), dvnom(startepoch))
            badind = 1;
            kp(k) = 0;
        end
        % if medrnd(k)==0 && ( abs(rad2deg(circ_dist(deg2rad(cmn(k)), deg2rad(dark_value))))>tol_dark || cvar(k)>tol_dark_var )   %if rounded median derivative over window is zero, but it doesn't fit dark epoch criteria, discard it; %ugly conversions; throw out windows (this is supposed to find closed loop epochs) that happen to have median derivative of zero but whose mean is not the dark_value and if the variance exceeds expected dark epoch variance (which should just be variance due to noise or resampling error)
        %     badind = 1;
        %     kp(k) = 0;
        % end
    else
        if ~isequal(moddiffcurr, moddiffset)
            if ~( medrnd(k)==0 && all(medrnd(k:end)==0) && cvar(k)<=tol_dark_var) %don't apply cmn criterion here since panels off get different value than dark; if panels are off at the end, consider it a series of dark epochs
                if isequal(medrnd(k), medrnd(k-1))
                    [~, rmdupe] = max(min(abs(med(k-1:k)-dvnom'))); %use the actual median (not rounded median medrnd) to choose which of two bouts in a row that match sequence; median closer to expected wins
                    kp(k-(2-rmdupe)) = 0;
                else
                    kp(k) = 0;
                end
                badind = 1;
            end
        end
    end
    if ~goodstart && ~badind
        goodstart = 1;
        moddiffset = moddiffcurr;
    end
    knew = knew + 1 - badind;
end

end


