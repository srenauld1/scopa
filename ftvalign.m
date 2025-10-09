function ftvdsrs = ftvalign(opt)

%{

NOTE: THIS IS ONLY USEFUL IF YOU DO NOT YET HAVE A RECORD OF FICTRAC DATA ON THE SAME DAQ AS IMAGING DATA, WHICH IS THE BEST WAY TO ALIGN THE TWO

align fictrac video to imaging data using oscillations of the laser on fictrac video
save and output the aligned, temporally resampled video

algorithm:
    --finds brightest 'numpx' pixels in mean-t fictrac video (pixels where the imaging laser is brightest, ie under objective)
    --extracts timeseries from their spatial average
    --smooths timeseries with small gaussian window
    --finds peaks using findpeaks
    --removes peaks at the beginning and end of laser_ts (laser timeseries) if distance to next period is not ceil(ftrate/imrate) or floor(ftrate/imrate) . . . ie crops laser_ts to actual laser oscillation portion only
    --includes half-period before the first peak and after the last (half-period is the average half distance between peaks remaining after cropping)
    --assigns each sample in laser_ts (laser timeseries) the index of its nearest intensity peak using nearest neighbor interpolation, these are putative volume indices in the fictrac video
    --averages fictrac video during each putative volume index
    --saves temporally resampled video

this function only uses fictrac .dat file to estimate approximate fictrac rate
this function does not use the fictrac .txt file, or .log file,
but if user passes pth_vidlog and pth_log, loads/parses .txt and .log file, respectively, in case they can help in the future (but they all have independent problems of their own)
currently, this function aligns with precision of +/- one-half imaging sample (if it aligns without error)

todo:
    since, arbitrarily, the centroid of the imaging sample is considered the peak of the laser intensity,
    the trough/anti-peak would probably align more precisely (since it is the laser-blanked volume flyback period, which is typically shorter than the laser on period),
    this would require little change to this code except applying findpeaks to the inverse laser timeseries,
    precision of half-imaging sample period seems sufficient though since the scopa pipeline downsamples behavior data to match imaging data, rather upsampling imaging data to match behavior data,
    and because the fictrac video is currently only used for visualization, not for analysis

%}

arguments
    opt.rsinds = [] %resampling indices (e.g. if they were on the daq)
    opt.numvol = [] %number of imaging volumes
    opt.imrate = [] %imaging rate, volrate if volumetric, framerate if not (average,approximate can work too)
    opt.numpkthr = 10; %in laser oscillation timeseries, number of contiguous peaks with periodic distance to be considered the start of the imaging trial, and also the end when applied in the reverse direction; this could just be same as numvol, but in case there are missing peaks, making this number smaller . . . max would be  round(numvol*0.8)
    opt.topkp = 0.5; % fraction of vertical top of fictrac video frames to consider when finding brightest numpx pixels (pedestal at bottom can sometimes be brightest part of image, so this can exclude that); if empty, user is prompted to choose roi
    opt.smlenpx = 2 %window length for gaussian smoothing filter applied to average frame of fictrac video, prior to finding the brightest pixels (to locate laser)
    opt.numpx = 10  %after spatial smoothing, number of pixels to average on each frame of fictrac video; these are the brightest 'numpx' pixels in the mean frame of fictrac video
    opt.smlensec = 1 %window length for gaussian smoothing filter applied to laser timeseries, to help denoise timeseries prior to findpeaks (to help find the true laser oscillation peaks)
    opt.ftrate = [] %fictrac sample rate; if empty, derived from sample times in pth_dat
    opt.pthstack = [] %can pass in path to stack and derive defaults for all the other paths
    opt.pth_vid char = [] %path to load 'ftvds', which is spatially downsampled, grayscale fictrac video, which was saved in ftvdownsample.py, as part of registration pipeline
    opt.pth_vidrs char = [] %path to save 'ftvdsrs', output of this function, which is version of ftvds that has been temporally downsampled and aligned with imaging data
    opt.pth_dat char = [] %fictrac .dat file; used to derive ftrate; can pass in ftrate instead
    opt.pth_vidlog char = [] %path to fictrac 'vidLogFrames' .txt file; file not used in this function, but may be useful sometime
    opt.pth_log char = [] %path to fictrac .log file; file not used in this function, but may be useful sometime
    opt.doplt = 0; %0 skips plots, 1 plots and saves, 2 saves but does not display
end
rsinds = opt.rsinds;
numvol = opt.numvol;
imrate = opt.imrate;
numpkthr = opt.numpkthr;
topkp = opt.topkp;
smlenpx = opt.smlenpx;
numpx = opt.numpx;
smlensec = opt.smlensec;
ftrate = opt.ftrate;
pthstack = opt.pthstack;
pth_vid = opt.pth_vid;
pth_vidrs = opt.pth_vidrs;
pth_dat = opt.pth_dat;
pth_vidlog = opt.pth_vidlog;
pth_log = opt.pth_log;
doplt = opt.doplt;

if ~ismember(isempty(topkp) + isempty(numpx), [0,2])
    error("numpx and topkp must both be empty or nonempty")
end
if isempty(pthstack)
    if isempty(pth_vid)
        error("if pth_vid is empty, pthstack must be nonempty")
    end
else
    id = idmake(pthstack);
end
id = idmake(pthstack);



%%%% GET PATHS, IN CASE THEY WEREN'T PASSED IN %%%%

if isempty(pth_dat)
    pth_ftdat_pat = [id.pthstackdir 'FicTracData' filesep 'fictrac-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.dat'];
    pth_dat = rdir(pth_ftdat_pat);
    if isempty(pth_dat)
        pth_dat = [];
    else
        pth_dat = pth_dat.name;
    end
end

if isempty(pth_log)
    pth_ftlog_pat = [id.pthstackdir 'FicTracData' filesep 'fictrac-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.log']; %
    pth_log = rdir(pth_ftlog_pat);
    if isempty(pth_log)
        pth_log = [];
    else
        pth_log = pth_log.name;
    end
end

if isempty(pth_vidlog)
    pth_ftvidlog_pat = [id.pthstackdir 'FicTracData' filesep 'fictrac-vidLogFrames-' num2str(id.recdatenum) '*_trial_' sprintf( '%03d', id.trialnum ) '.txt']; %
    pth_vidlog = rdir(pth_ftvidlog_pat);
    if isempty(pth_vidlog)
        pth_vidlog = [];
    else
        pth_vidlog = pth_vidlog.name;
    end
end

if isempty(pth_vid)
    pth_ftvid_pat = [id.pthstackdir id.recid '_ftvds_.mat']; %downsampled ft video (downsampled in register.py)
    pth_vid = rdir(pth_ftvid_pat);
    if isempty(pth_vid)
        error("cannot find fictrac video (pth_vid) using default pattern derived from pthstack")
    else
        pth_vid = pth_vid.name;
    end
end


if isempty(pth_vidrs)
    pth_vidrs = [pth_vid(1:end-4) 'RS_.mat'];
end



%%%% CHECK IF RESAMPLED VIDEO ALREADY EXISTS %%%%

try

    load(pth_vidrs, 'ftvdsrs')

catch



    %%%% LOAD SUPPLEMENTAL FILES, WHICH MAY OR MAY NOT GET USED %%%%

    if pth_vidlog
        ftvl = parse_fictrac_vidlog(pth_vidlog);
    end

    if pth_log
        try
            [pthtmp, fnlog, ~] = fileparts(pth_log);
            pth_log_parsed = [pthtmp filesep fnlog '_parsed_.mat'];
            load(pth_log_parsed, 'log_timestamps', 'log_framecounts')
        catch
            [log_timestamps, log_framecounts] = parse_fictrac_log(pth_log, pth_log_parsed, ftvl(end)); %outputs: vlts (vid log
        end
    end



    %%%% LOAD VIDEO, EXTRACT LASER TIMESERIES %%%%

    ftvds = struct2cell(load(pth_vid)); %make sure loaded variable is named 'ftvds'; %ftvds is spatially downsampled, grayscale fictrac video, which was saved in ftvdownsample.py, as part of registration pipeline
    ftvds = ftvds{1};
    ftvds = permute(ftvds, [2 3 1]);

    if isempty(rsinds)

        if isempty(ftrate)
            if isempty(pth_dat)
                error("must pass in ftrate or pth_dat or pthstack to derive ftrate (if you got this error, pthstack or pth_dat may not exist)")
            end
            ftdat = read_fictrac_dat(pth_dat);
            ftrate = 1e9/median(ftdat.deltaTimestamp);
        end

        goodper = ftrate/imrate;

        if imrate > ftrate / 2
            error("imaging rate is approximately " + num2str(imrate) + " hz, while fictrac rate is approximately " + num2str(ftrate) + " hz; this algorithm will not work well if imaging rate is high, relative to fictrac rate; threshold set at half fictrac rate")
        end

        szvd = size(ftvds);
        ftvds = reshape(ftvds, [], size(ftvds, 3));

        if isempty(topkp)
            ftvid_cntr_t = reshape(mean(ftvds,2), szvd(1), szvd(2));
            if ~isempty(smlenpx)
                ftvid_cntr_t = imgaussfilt(ftvid_cntr_t,smlenpx);
            end
            figure;
            imagesc(ftvid_cntr_t)
            title("draw freestyle roi where the laser oscillation is likely to be strongest")
            cntr_roi = drawfreehand('Color','r');
            roimsk = createMask(cntr_roi);
            mxi = find(roimsk);
            numpx = numel(mxi);
        else
            cntr_method = 'mean'; %mean or var
            switch cntr_method
                case 'mean'
                    ftvid_cntr_t = reshape(mean(ftvds,2), szvd(1), szvd(2));
                    if ~isempty(smlenpx)
                        ftvid_cntr_t = imgaussfilt(ftvid_cntr_t,smlenpx);
                    end
                    ftvid_cntr_t(round(size(ftvid_cntr_t,1)*(1-topkp)):end,:) = 0; %hack, zero out bottom (1-topkp) fraction of frame
                    [~,mxi] = sort(ftvid_cntr_t(:), 'descend');
                case 'var'
                    ftvid_cntr_t = reshape(var(single(ftvds),[],2), szvd(1), szvd(2));
                    if ~isempty(smlenpx)
                        ftvid_cntr_t = imgaussfilt(ftvid_cntr_t,smlenpx);
                    end
                    ftvid_cntr_t(round(size(ftvid_cntr_t,1)*(1-topkp)):end,:) = 0; %hack, zero out bottom (1-topkp) fraction of frame
                    [~,mxi] = sort(ftvid_cntr_t(:), 'descend');
            end
        end
        laser_ts = mean(ftvds(mxi,:)); %laser_ts shows, purportedly, laser timeseries of oscillations in the brightest numbrightpix pixels in the spatially smoothed, mean-t image
        % laser_ts = laser_ts - mean(laser_ts);
        % laser_ts = rescale(laser_ts);

        num_vidframes = numel(laser_ts);
        ftvds = reshape(ftvds, szvd);

        if doplt
            hfg = figure( 'Units', 'Normalized', 'Color', 'white');
            hax = axes('Parent', hfg);
            imagesc(hax, ftvid_cntr_t); hold on;
            [mxr, mxc] = ind2sub(szvd(1:2), mxi(1:numpx)); %plot with image to confirm these are good pixels for extracting laser timeseries
            scatter(mxc,mxr,5,'red','filled')
            pth_gif = [pth_vid '_mean_t_im_.gif'];
            fig2gif(hfg, 1, pth_gif);
        end



        %%%% FIND PEAKS IN THE LASER TIMESERIES %%%%

        laser_ts_smoothed = laser_ts;
        if smlensec
            smlen = smlensec*imrate;
            laser_ts_smoothed = smoothdata(laser_ts_smoothed, 'gaussian', smlen);
        end
        [pk,lk,pw,pp] = findpeaks(laser_ts_smoothed);
        pkdist = diff(lk);

        [~, f, v] = ordernrank(pkdist);
        % goodper = v(isoutlier(f));
        goodpers = [floor(goodper) ceil(goodper)];

        pkdistdiff = [pkdist(1)-1 diff(pkdist)];



        %%%% FIND LASER OSCILLATION PERIOD BY FINDING DELAY BETWEEN SIGNAL AND ITS INVERSE %%%%

        pkhalfper = find_oscillation_halfperiod(laser_ts_smoothed);
        pkhalfper = ceil(mean(goodpers));



        %%%% CROP BEFORE/AFTER TRIAL PERIOD BY FINDING/CROPPING APERIODIC PEAKS IN THE LASER TIMESERIES (THIS WORKED BETTER THAN RUNNING RMOUTLIERS ON PEAK PROMINENCES) %%%%

        [badpeaks_front] = crop_wrong_periods(pkdist, goodpers, numpkthr);
        if badpeaks_front==0
            badpeaks_front_msg = "there are no initial bad peaks to remove, the fictrac video may begin after imaging begins";
        else
            badpeaks_front_msg = 'there were bad peaks to remove at the front, so the imaging does seem to begin during the video, at least';
        end

        [badpeaks_back] = crop_wrong_periods(flip(pkdist), goodpers, numpkthr);
        if badpeaks_back==0
            badpeaks_back_msg = "there are no bad peaks at the end to remove, the fictrac video may end before imaging";
        else
            badpeaks_back_msg = 'there were bad peaks to remove at the end, so the imaging does seem to end during the video, at least';
        end
        keeppeakinds = badpeaks_front+1:numel(lk)-badpeaks_back;
        % keeppeakinds = keeppeakinds(2:end);
        peakperiods_good = unique(pkdist(keeppeakinds));
        % if range(peakperiods_good)>max_peak_distance_change_defining_periodic
        %     error("range of peakperiods_good should not exceed cycle_period_tiolerance")
        % end

        pkg = pk(keeppeakinds);
        lkg = lk(keeppeakinds);
        pwg = pw(keeppeakinds);
        ppg = pp(keeppeakinds);
        pkdistdiffg = pkdistdiff(keeppeakinds);

        possible_frame_drops = find(abs(pkdistdiffg)>1);

        % numgoodpeaks_to_plot = 3;
        %peakinds_to_plot = 10; figure; plot(1:lk(peakinds_to_plot), laser_ts_smoothed(1:lk(peakinds_to_plot)), lk(1:peakinds_to_plot), pk(1:peakinds_to_plot), 'o')
        % peakinds_to_plot = 185:badpeaks_front+numgoodpeaks_to_plot; figure; plot(1:numel(lk(peakinds_to_plot(1)):lk(peakinds_to_plot(end))), laser_ts_smoothed(lk(peakinds_to_plot(1)):lk(peakinds_to_plot(end))), lk(peakinds_to_plot)-lk(peakinds_to_plot(1))+1, pk(peakinds_to_plot), 'o')
        % peakinds_to_plot = numel(lk)-badpeaks_back-(numgoodpeaks_to_plot-1):numel(lk); figure; plot(1:numel(lk(peakinds_to_plot(1)):lk(peakinds_to_plot(end))), laser_ts_smoothed(lk(peakinds_to_plot(1)):lk(peakinds_to_plot(end))), lk(peakinds_to_plot)-lk(peakinds_to_plot(1))+1, pk(peakinds_to_plot), 'o')



        %%%% FIND SLOPE (OVER PEAK HALF PERIOD) OF LASER TIMESERIES (CURRENTLY NOT USED, BUT PREVIOUSLY CONSIDERED USING SLOPES TO DEFINE THE OSCILLATIONS AGAINST THE NON-OSCILLATIONS, SINCE LASER OSCILLATIONS HAVE MUCH BIGGER SLOPES) %%%%

        dfmnt = differentiate_laser_timeseries(laser_ts_smoothed, pkhalfper);



        %%%% PLOT LASER INTENSITY TIMESERIES WITH PEAKS MARKED %%%%

        if doplt
            peaks_timeseries = nan(size(laser_ts_smoothed));
            peaks_timeseries(lkg) = pkg;
            segx = 50;
            pth_gif = [pth_vid(1:end-4) 'peaks_.gif'];
            titlein = 'laser oscillation with peaks (ideally imaging volumes) marked in red';
            yconst = 1;
            mkr2 = 'o';
            ylimtype = 'each';
            tsplt(laser_ts_smoothed, y2=peaks_timeseries, pthgif=pth_gif, segx=segx, titlein=titlein, yconst=yconst, ymatch=ymatch, mkr2=mkr2)
        end



        %%%% FIND DOWNSAMPLING INDICES %%%%

        numpk = numel(pkg);
        fprintf("num peaks: " + num2str(numpk) + " numvol: " + num2str(numvol) + newline)

        if numpk~=numvol
            error("numpeaks does not equal numvol \n" + badpeaks_front_msg + "\n" + badpeaks_back_msg)
        end

        keepinds_vid = lkg(1)-pkhalfper:lkg(end)+pkhalfper;

        lkgzeroed = lkg - keepinds_vid(1) + 1;

        rsinds = zeros(size(keepinds_vid));
        rsinds(lkgzeroed) = 1;
        rsinds = bin2ind(logical(rsinds));
        rsinds(rsinds==0) = nan;
        rsinds = fillmissing(rsinds, 'nearest');



        %%%% REMOVE FRAMES BEFORE AND AFTER IMAGING %%%%

        ftvds = ftvds(:,:,keepinds_vid);


    end


    %%%% DOWNSAMPLE VIDEO %%%%

    rsu = unique(rsinds(rsinds~=0),'stable'); %index of each volume, according to light flashes
    ftvdsrs = zeros(size(ftvds, 1), size(ftvds, 2), numvol, 'uint8');
    for ri = 1:numel(rsu)
        ftvdsrs(:,:,ri) = mean(ftvds(:,:,rsinds==rsu(ri)),3);
    end

    fprintf("final resampled fictrac video size is: " + mat2str(size(ftvdsrs)) + newline)



    %%%% PLOT VIDEO BEFORE AND AFTER RESAMPLING %%%%

    if doplt
        title_prefix = 'pre resample';
        pthgif = [pth_vid(1:end-4) '.gif'];
        stackplt(reshape(ftvds, size(ftvds,1), size(ftvds,2), 1, size(ftvds,3)), it=3i+50, pthgif=pthgif, title_prefix=title_prefix)

        title_prefix = 'post resample';
        pthgif = [pth_vid(1:end-4) 'RS_.gif'];
        stackplt(reshape(ftvdsrs, size(ftvdsrs,1), size(ftvdsrs,2), 1, size(ftvdsrs,3)), it=3i+50, pthgif=pthgif, title_prefix=title_prefix)
    end

    save(pth_vidrs, 'ftvdsrs', '-v7.3', '-mat')
    fprintf("exiting downsample_fictrac_video" + newline)



end

end


function [j] = crop_wrong_periods(pkdiff, pkper_good, stopsearch_thresh)

try
    jrel = 0;
    j = 0;
    periodic_peak_count = 0;
    while 1
        j = j+1;
        jrel = jrel+1;
        if ~ismember(pkdiff(jrel), pkper_good) %if peak period abs difference is greater than pkperdiff_thresh, crop everything before
            pkdiff = pkdiff(jrel+1:end);
            jrel = 0; %reset
            periodic_peak_count = 0; %reset
        else
            periodic_peak_count = periodic_peak_count+1;
        end
        if periodic_peak_count==stopsearch_thresh %if there have been stopsearch_thresh periodic peaks, stop
            break
        end
    end

    j = j-stopsearch_thresh;

catch
    error("you're defined the laser timeseries to have " + num2str(stopsearch_thresh) + " periodic peaks in a row, but the number of peaks has maxed out; you may have dropped frames, or many peaks in the non-trial period, or you may have chosen an inappropriately high value; it should be less than or equal to the known number of imaging volumes")
end

end


function [j] = crop_aperiodic_peaks(pkperdiff, pkperdiff_thresh, stopsearch_thresh)

try
    jrel = 0;
    j = 0;
    periodic_peak_count = 0;
    while 1
        j = j+1;
        jrel = jrel+1;
        if abs(pkperdiff(jrel))>pkperdiff_thresh %if peak period abs difference is greater than pkperdiff_thresh, crop everything before
            pkperdiff = pkperdiff(jrel+1:end);
            jrel = 0; %reset
            periodic_peak_count = 0; %reset
        else
            periodic_peak_count = periodic_peak_count+1;
        end
        if periodic_peak_count==stopsearch_thresh %if there have been stopsearch_thresh periodic peaks, stop
            break
        end
    end

    j = j-stopsearch_thresh;

catch
    error("you're defined the laser timeseries to have " + num2str(stopsearch_thresh) + " periodic peaks in a row, but the number of peaks has maxed out; you may have dropped frames, or many peaks in the non-trial period, or you may have chosen an inappropriately high value; it should be less than or equal to the known number of imaging volumes")
end

end


function ftvl = parse_fictrac_vidlog(pth_vidlog)


ftvl = table2array(readtable(pth_vidlog));
vlend = ftvl(end);
vlnumel = numel(ftvl(:));
vl_num_missing = vlend-vlnumel;
if vlend<vlnumel
    error("vlend should not be less than vlnumel")
end

ftvldiff = [0; diff(ftvl)];
dropinds = find(ftvldiff(2:end)~=1)+1;
if ftvl(1)>0
    dropinds = [1; dropinds];
end

drops_numfr = ftvldiff(dropinds);
num_drop_occurrences = numel(drops_numfr);
drop_numfr_unique = unique(drops_numfr);

fprintf("found " + num2str(num_drop_occurrences) + " frame drop events in vidLogFrames txt file, with unique drop lengths of " + mat2str(drop_numfr_unique) + " frames" + newline)



end


function [log_timestamps, log_framecounts] = parse_fictrac_log(pth_log, pth_log_parsed, vlend)

if ~exist('vlend', 'var') || isempty(vlend)
    vlend = nan; %optional expected number logged frames
end

fid = fopen(pth_log, 'r');
linesubstr = 'Trackball::process [';
linesubstr2 = 'Frame';
log_timestamps = {};
log_framecounts = {};
count = 0;
fprintf("starting to extract frame times and indices from this fictrac log file: \n" + pth_log + newline)
while ~feof(fid)
    str = fgetl(fid);
    if contains(str, linesubstr) && contains(str, linesubstr2)
        count = count+1;
        if count>vlend+1
            fprintf("log file and vidlog file don't match; apparently not unusual" + newline)
        end
        log_timestamps(count) = textscan(str, '%f');
        log_framecounts(count) = textscan(str(strfind(str, 'Frame'):end), 'Frame %f');
    end
end
fclose(fid);

log_timestamps = cell2mat(log_timestamps);
log_framecounts = cell2mat(log_framecounts);

if ~isequal(unique(log_framecounts), 0:max(log_framecounts))
    error("fictrac log file has missing frames")
end

save(pth_log_parsed, 'log_timestamps', 'log_framecounts', '-v7.3', '-mat')

fprintf("saved fictrac frame times and indices to this file: \n" + pth_log_parsed + newline)

end


function pkhalfper = find_oscillation_halfperiod(mnt2, doplt)

if ~exist('doplt', 'var')
    doplt = 0;
end

mnt2f = max(mnt2)-mnt2;
[pkf,lkf,pwf,ppf] = findpeaks(mnt2f);
pkperf = diff(lkf);
pkprmnf = mean(pkperf);
mnt2f = mnt2f+min(mnt2);

[mnt2d, mnt2fd, pkhalfper] = alignsignals(mnt2, mnt2f, 'Method', 'risetime');

if doplt
    tinds = 1601:1800;
    figure;
    subplot(3,1,1); hold on;
    plot(mnt2(tinds)); plot(mnt2f(tinds))
    subplot(3,1,2); hold on;
    plot(mnt2d(tinds)); plot(mnt2fd(tinds))
end


end


function dfmnt = differentiate_laser_timeseries(lsts, per, doplt)

if ~exist('doplt', 'var')
    doplt = 0;
end

flt = [zeros(1,per-1) 1 zeros(1,per-1) -1]; %find diffs across dfdt num samples

dfmnt = conv(lsts, flt, 'full');
dfmnt = dfmnt((length(flt) - 1)+1:end-(length(flt) - (1 + (per-1))));
dfmnt = [zeros(1, (per-1)+1) dfmnt];

if doplt

    figure;
    subplot(3,1,1);
    title([ num2str(per) '-sample laser derivatives']);
    hist(dfmnt)
    dfmnt_neg = dfmnt(dfmnt<0);
    dfthneg = mean(dfmnt_neg);
    dfmnt_pos = dfmnt(dfmnt>0);
    dfthpos = mean(dfmnt_pos);

    subplot(3,1,2);
    title([ 'negative derivatives only']);
    hist(dfmnt_neg)
    keepindsneg = find(dfmnt<dfthneg);
    keepindspos = find(dfmnt>dfthpos);

end


end
