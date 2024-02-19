%% Process Fictrac Data
%folder = '/Users/abates/Desktop/20210719-3_fly_2/';
%folder = '\\research.files.med.harvard.edu\Neurobio\Wilson Lab\asbates\2p_collect\75815_R60D05_GCaMP7f\20210810-1_fly_7\';

function [ftData_dat] = cx_imaging_fictrac_pipeline(folder, video, interactive, trigger)

%% Default settings
arguments
    folder char
    video logical = 0
    interactive logical = 0
    trigger logical = 0
end
expID = get_expID(folder);

%% PROCESS FicTrac DATA
% Extracts the median luminance from each frame of the raw FicTrac videos and uses it to identify
% the start and end of the trial in both the videos and the FicTrac output data itself (which have
% slightly different frame rates). Also determines the times in seconds relative to the start of the
% video of both the FicTrac data "frames" and the video frames. Then, saves the cropped videos to
% the processed data directory and the raw FicTrac data + frame times in the root experiment
% directory (to await further processing)
%---------------------------------------------------------------------------------------------------

rawFt = fictrac_imaging_preprocess(folder, video, 0, trigger, interactive);
ftData_dat = fictrac_asssemble_dat(folder, rawFt);
ftData_DAQ = fictrac_asssemble_DAQ(folder);

ftSave = fullfile(folder, [expID, '_ficTracData_dat.mat']);
save(ftSave, 'ftData_dat');
disp(['Saved fictrac .dat data as: ', ftSave])

ftSave = fullfile(folder, [expID, '_ficTracData_DAQ.mat']);
save(ftSave, 'ftData_DAQ');
disp(['Saved fictrac DAQ data as: ', ftSave])


end





