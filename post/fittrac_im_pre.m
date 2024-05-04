
function ftData_DAQ = fittrac_im_pre(folder)

%wrapper for fictrac_asssemble_DAQ

fntmp = rdir([folder filesep '*.tif']);
[~, fntmp, ~] = fileparts(fntmp(1).name);
fntmp = strsplit(fntmp, '_'); %first file is fine, they'rew all the same date-fly
expID = [fntmp{1} '-' fntmp{2}];

ftData_DAQ = fictrac_asssemble_DAQ(folder);

ftSave = fullfile(folder, [expID, '_ficTracData_DAQ.mat']);
save(ftSave, 'ftData_DAQ');
disp(['Saved fictrac DAQ data as: ', ftSave])

end





