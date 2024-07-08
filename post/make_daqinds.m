function daqinds = make_daqinds(frameinds, timestamps, numvol, numslice_withflyback, pth_daqinds)


%%%%%%%% slice indices %%%%%%%%

if frameinds(1) == 1
    sprintf("warning, first daq sample is during an imaging frame")
end
frameinds = binary2count(frameinds);
numvol_from_frames = max(frameinds)/numslice_withflyback;
if numvol_from_frames~=numvol
    error("number of volumes computed from daq frames does not match number of stack volumes")
end
usi = unique(frameinds(frameinds~=0),'stable'); %index of each frame
sliceinds = nan(size(frameinds));
trialdata_time_tmp = seconds(timestamps);
volume_centroid_ind = zeros(numel(usi), 1);
parfor ii = 1:numel(usi) %loop is much faster than using arrayfun
    volume_centroid = mean(trialdata_time_tmp(frameinds==usi(ii))); %find time centroid for each volume
    [~, volume_centroid_ind(ii)] = min(abs(trialdata_time_tmp - volume_centroid)); %find nearest daq sample to volume centroid
end
sliceinds(volume_centroid_ind) = frameinds(volume_centroid_ind); %put volume index at nearest daq sample to volume centroid
sliceinds = fillmissing(sliceinds, 'nearest');
sliceinds = mod(sliceinds-1, numslice_withflyback)+1; %get one-indexed slice indices

%%%%%%%% volume indices %%%%%%%%

uniquesliceinds = unique(sliceinds(sliceinds~=0));
endvolinds = strfind(sliceinds', [uniquesliceinds(end) uniquesliceinds(1)]);
volinds = sliceinds;
volinds(endvolinds) = 0;
volinds = binary2count(logical(volinds));
volinds(endvolinds) = volinds(endvolinds-1); %all slices (the whole volume)

%%%%%%%% save %%%%%%%%

daqinds.slice = single(sliceinds);
daqinds.vol = single(volinds);

save(pth_daqinds, 'daqinds', '-v7.3', '-mat');

end
