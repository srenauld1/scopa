clear all
close all
clc

dopp = [7];
iz = 5;

fnraw = '/Users/wienecke/stacks/20241008-3_MBON09_no_jump/20241008-3_no_jump_155345_trial_001_00001.tif';
[expDir, cfn] = fileparts(fnraw);
fnrawnofb = fullfile(expDir, 'oldrawnofb.mat');
fnreg_pre = fullfile(expDir, 'oldreg.mat');
fnroidat_pre = fullfile(expDir, 'roidat.mat');
fnroi = fullfile(expDir, 'roidefs.mat');
blfrac = 0.05; %roi baseline

fnregscopa = fullfile(expDir, '20241008_3_1_cmrg_.mat');
fndn = fullfile(expDir, '20241008_3_1_cmrg_dcdn_.mat');

expID = cfn(1:10);
trialNum = get_trialNum(fnraw);

glb(dirstack = [expDir '/'])


%%  RUN JF PIPELINE (WITH AND WITHOUT CLIPPING/SMOOTHING, ie dopp)


for m = 1:numel(dopp)
    dopptmp = dopp(m);
    fnreg = insertBefore(fnreg_pre, '.mat', num2str(dopptmp));
    fnroidat = insertBefore(fnroidat_pre, '.mat', num2str(dopptmp));

    try
        load(fnroidat, 'roiData');
    catch


        try
            load(fnreg, 'imgData');
        catch

            try
                load(fnrawnofb, 'imgData');
            catch
                [imgData, siMetadata] = read_tif(fnraw, 0); % --> [y, x, planes, volumes]
                siMetadata = parse_scanimage_metadata(siMetadata);
                nFlybackFrames = siMetadata.SI.hFastZ.numDiscardFlybackFrames;
                imgData(:, :, (end - (nFlybackFrames - 1)):end, :) = []; % --> [y, x, plane, volume]
                save(fnrawnofb, 'imgData','-v7.3'); % JF changes
            end

            imgDataReg = zeros(size(imgData));
            regTemplates = [];
            for k = 1:size(imgDataReg, 3)

                currData = squeeze(imgData(:,:, k, :)); % --> [y, x, volume]

                if dopptmp==1
                    srt = sort(imgData(:));
                    capVal = srt(numel(srt) - round(numel(srt)/1000));
                    currData(currData > capVal) = capVal;
                    for iVol = 1:size(currData, 3)
                        currData(:, :, iVol) = imgaussfilt(currData(:, :, iVol), 0.5);
                    end
                end

                options_rigid = NoRMCorreSetParms( ...
                    'd1', size(currData, 1), ...
                    'd2', size(currData, 2), ...
                    'grid_size', [], ... %empty is 2d rigid registration, where grid size is automatically set to [d1 d2 1]
                    'max_shift', [25, 25], ... %max rigid shift yx
                    'init_batch', 100, ... %length of initial batch
                    'upd_template', true, ... %default true,
                    'us_fac', 50, ... %default 50,
                    'phase_flag', 0, ... %default false,...
                    'shifts_method', 'FFT', ... %default fft,...
                    'correct_bidir', true ... %default true,...
                    );

                [planeData, ~, regTemplate, ~] = normcorre_batch(currData, options_rigid);

                imgDataReg(:, :, k, :) = planeData;    % --> [y, x, plane, volume]
                regTemplates(:, :, k) = regTemplate;   % --> [y, x, plane]

            end

            imgData = imgDataReg;
            imgDataReg = [];
            imgData = int16(imgData);
            save(fnreg, 'imgData','-v7.3'); % JF changes

        end


        sz = size(imgData);

        load(fnroi, 'roiDefs');

        % Reshape imaging data into 1D frames
        imgData = reshape(permute(imgData, [3 4 1 2]), sz(3), sz(4), []); % --> [plane, volume, pixel]

        % Create table for current trial's ROI data
        roiData = [];
        for iRoi = 1:numel(roiDefs)
            newRow = table({expID}, trialNum, {roiDefs(iRoi).name}, {roiDefs(iRoi).subROIs}, {[]}, ...
                'VariableNames', {'expID', 'trialNum', 'roiName', 'subROIs', 'rawFl'});
            roiData = [roiData; newRow];
        end

        % Loop through and extract data for each subROI
        trialBaselines = [];
        for iRoi = 1:numel(roiDefs)
            currRoi = roiDefs(iRoi);
            rawData = [];
            for iSubRoi = 1:numel(currRoi.subROIs)
                currSubRoi = currRoi.subROIs(iSubRoi);
                currImgData = squeeze(imgData(currSubRoi.plane, :, :));	% --> [volume, pixel]
                mask = currSubRoi.mask(:);                                  % --> [pixel]
                currImgData = currImgData(:, mask)';                        % --> [pixel, volume]
                rawData = [rawData; currImgData];                           % --> [pixel, volume]
            end

            % Average data across pixels and subROIs
            roiDataAvg = mean(rawData, 1)'; % --> [volume]
            roiData.rawFl{iRoi} = roiDataAvg;

            % Calculate trial baseline using bottom 5th percentile of whole trial's Fl data
            currDataSorted = sort(roiDataAvg);
            trialBaselines(iRoi, 1) = currDataSorted(round(numel(currDataSorted) * blfrac));

        end

        % Add trial baselines to table
        roiData.trialBaseline = trialBaselines;

        % Subtract minimum value across entire experiment from all ROI data if it is < 0
        expMinVal = min(cell2mat(roiData.rawFl));
        if expMinVal < 0
            disp(['Subtracting minimum value of ', num2str(expMinVal) ' from all ROI data'])
            for iRow = 1:size(roiData, 1)
                roiData.rawFl{iRow} = (roiData.rawFl{iRow} - expMinVal) + 1; % Add one to allow division
                roiData.trialBaseline(iRow) = roiData.trialBaseline(iRow) - expMinVal + 1;
            end
        end

        % Calculate expBaseline for each ROI and add to table
        roiList = unique(roiData(:, 'roiName'));
        baselineVals = [];
        for iRoi = 1:size(roiList, 1)
            roiData = innerjoin(roiList(iRoi, :), roiData);
            roiDataSort = sort(cell2mat(roiData.rawFl));
            baselineVals(iRoi) = roiDataSort(round(numel(roiDataSort)*blfrac));
        end
        baselineTable = [roiList, table(baselineVals', 'variableNames', {'expBaseline'})];
        roiData = innerjoin(roiData, baselineTable);

        % Save processed ROI data
        save(fnroidat, 'roiData');

    end

end


%%  JF CW STACK COMPARISON

stackraw = struct2cell(load(fnrawnofb, 'imgData'));
stackraw = stackraw{1};
stackraw = stackraw - min(stackraw(:));
stackraw = uint16(stackraw);

dopptmp = 0;
fntmp = insertBefore(fnreg_pre, '.mat', num2str(dopptmp));
stackreg_nopp = struct2cell(load(fntmp, 'imgData'));
stackreg_nopp = stackreg_nopp{1};
stackreg_nopp = stackreg_nopp - min(stackreg_nopp(:));
stackreg_nopp = uint16(stackreg_nopp);

dopptmp = dopp;
fntmp = insertBefore(fnreg_pre, '.mat', num2str(dopptmp));
stackreg_alt = struct2cell(load(fntmp, 'imgData'));
stackreg_alt = stackreg_alt{1};
stackreg_alt = stackreg_alt - min(stackreg_alt(:));
stackreg_alt = uint16(stackreg_alt);

% dopptmp = 1;
% fntmp = insertBefore(fnreg_pre, '.mat', num2str(dopptmp));
% stackreg_pp = struct2cell(load(fntmp, 'imgData'));
% stackreg_pp = stackreg_pp{1};
% stackreg_pp = stackreg_pp - min(stackreg_pp(:));
% stackreg_pp = uint16(stackreg_pp);

stackreg_sc = struct2cell(load(fnregscopa, 'stack'));
stackreg_sc = stackreg_sc{1};

stackreg_dn = struct2cell(load(fndn, 'stack'));
stackreg_dn = stackreg_dn{1};


it = [500:550]; %frames to plot in stackplt

% plot all stacks, all planes, each stack normalized independent of the other stacks 

% stackplt({stackraw, stackreg_alt, stackreg_sc}, it=it, fdimnum=3)

% stackplt({stackraw, stackreg_nopp, stackreg_sc, stackreg_dn}, it=it, fdimnum=3)

%same as above but just plane iz
% stackplt({stackraw, stackreg_nopp, stackreg_sc, stackreg_dn}, it=it, iz=iz)

% plot plane iz of all stacks, normalize all stacks as a group, by making a new stack from all stacks (note this will make plot title incorrect)
stack = zeros(size(stackreg_dn,1), size(stackreg_dn,2), 5, size(stackreg_dn,4), class(stackreg_dn));
stack(:,:,1,:) = stackraw(:,:,iz,:);
stack(:,:,2,:) = stackreg_nopp(:,:,iz,:);
stack(:,:,3,:) = stackreg_alt(:,:,iz,:);
stack(:,:,4,:) = stackreg_sc(:,:,iz,:);
stack(:,:,5,:) = stackreg_dn(:,:,iz,:);


% showing all stacks at once for each frame
stackplt(stack(:,:,[1 3 4],:), it=it, fdimnum=3)

% showing single frames (just a few), alternating between stacks
it = [500 1500 2500 3000]; %frames to plot in stackplt; for this just do a few so the gif isn't too long
stackplt(stack, it=it)

%histograms of iz
figure; 
subplot(311); 
title("jf reg with smoothing")
hist(single(vec(stackreg_nopp(:,:,iz,:))), 1000);
subplot(312); 
title("scopa reg")
hist(single(vec(stackreg_alt(:,:,iz,:))), 1000);
subplot(313); 
title("denoised")
hist(single(vec(stackreg_sc(:,:,iz,:))), 1000);

% %histograms of whole stack
% figure; 
% subplot(311); 
% title("jf reg without smoothing")
% hist(single(stackreg_nopp(:)), 1000);
% subplot(312); 
% title("scopa reg")
% hist(single(stackreg_sc(:)), 1000);
% subplot(313); 
% title("denoised")
% hist(single(stackreg_dn(:)), 1000);

%%  JF CW roi timeseries extract

load(fnroi, 'roiDefs');
mask = zeros(size(stackraw,1), size(stackraw,2), size(stackraw,3), 'logical');
for k = 1:numel(roiDefs.subROIs)
    currSubRoi = roiDefs.subROIs(k);
    mask(:,:,currSubRoi.plane) = currSubRoi.mask;                
end
stackplt(mask)

roiwt = mask(:)';

resp_raw_raw = roiresp(single(stackraw), roiwt=roiwt); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
% resp_raw_dff = roiresp(single(stackraw), roiwt=roiwt, normpost = 'dff005000'); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel

resp_regnopp_raw = roiresp(single(stackreg_nopp), roiwt=roiwt); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
% resp_regnopp_dff = roiresp(single(stackreg_nopp), roiwt=roiwt, normpost = 'dff005000'); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel

% resp_regpp_raw = roiresp(single(stackreg_pp), roiwt=roiwt); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
% resp_regpp_dff = roiresp(single(stackreg_pp), roiwt=roiwt, normpost = 'dff005000'); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel

resp_regalt_raw = roiresp(single(stackreg_alt), roiwt=roiwt); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
% resp_regalt_dff = roiresp(single(stackreg_alt), roiwt=roiwt, normpost = 'dff005000'); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel

resp_regsc_raw = roiresp(single(stackreg_sc), roiwt=roiwt); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
% resp_regsc_dff = roiresp(single(stackreg_sc), roiwt=roiwt, normpost = 'dff005000'); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel

% resp_dn_raw = roiresp(single(stackreg_dn), roiwt=roiwt); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel
% resp_dn_dff = roiresp(single(stackreg_dn), roiwt=roiwt, normpost = 'dff005000'); %if two channel, input resp for 2nd channel gets appended to resp that was output for first channel, with fieldnames identifying channel

%% raw f comparisons

% tsplt(resp_raw_raw.imf_f_f_n, y2=resp_regnopp_raw.imf_f_f_n, xseg=10, titlein='raw v jf reg no smooth')
% tsplt(resp_regnopp_raw.imf_f_f_n, y2=resp_regpp_raw.imf_f_f_n, xseg=10, titlein='jf reg no smooth vs jf reg with smooth')
tsplt(resp_regnopp_raw.imf_f_f_n, y2=resp_regsc_raw.imf_f_f_n, xseg=10, titlein='jf reg without smooth v scopa reg')
tsplt(resp_regalt_raw.imf_f_f_n, y2=resp_regsc_raw.imf_f_f_n, xseg=10, titlein='jf reg alt v scopa reg')
% tsplt(resp_regpp_raw.imf_f_f_n, y2=resp_dn_raw.imf_f_f_n, xseg=10, titlein='jf reg with smooth v denoised')
% 
% %% dff comparisons
% 
% tsplt(resp_regpp_dff.imf_f_dff005000_n, y2=resp_regsc_dff.imf_f_dff005000_n, xseg=10, titlein='jf reg with smooth dff vs scopa reg dff')
% tsplt(resp_regpp_dff.imf_f_dff005000_n, y2=resp_dn_dff.imf_f_dff005000_n, xseg=10, titlein='jf reg with smooth dff vs denoised dff')
% 
