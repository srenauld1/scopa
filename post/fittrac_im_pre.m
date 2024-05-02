%% Process Fictrac Data

function [ftData_dat] = fittrac_im_pre(folder)

fntmp = rdir([folder filesep '*.tif']);
[~, fntmp, ~] = fileparts(fntmp(1).name);
fntmp = strsplit(fntmp, '_'); %first file is fine, they'rew all the same date-fly
expID = [fntmp{1} '-' fntmp{2}];

%% PROCESS FicTrac DATA
% Extracts the median luminance from each frame of the raw FicTrac videos and uses it to identify
% the start and end of the trial in both the videos and the FicTrac output data itself (which have
% slightly different frame rates). Also determines the times in seconds relative to the start of the
% video of both the FicTrac data "frames" and the video frames. Then, saves the cropped videos to
% the processed data directory and the raw FicTrac data + frame times in the root experiment
% directory (to await further processing)
%---------------------------------------------------------------------------------------------------

rawFt = fictrac_imaging_preprocess(folder, 0, 0, 0, 0);
ftData_dat = fictrac_asssemble_dat(folder, rawFt);
ftData_DAQ = fictrac_asssemble_DAQ(folder);

ftSave = fullfile(folder, [expID, '_ficTracData_dat.mat']);
save(ftSave, 'ftData_dat');
disp(['Saved fictrac .dat data as: ', ftSave])

ftSave = fullfile(folder, [expID, '_ficTracData_DAQ.mat']);
save(ftSave, 'ftData_DAQ');
disp(['Saved fictrac DAQ data as: ', ftSave])


end





