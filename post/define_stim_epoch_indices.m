

closedinds_initial_light = 0:59;
closedinds_final_dark = floor(seconds(md.dark_epoch_time_start)):floor(md.total_t);

cueinc = 20;
cuesplits = 60:cueinc:520;
splits2 = [cuesplits(1:2:end-1); cuesplits(2:2:end)]'; %epoch boundaries
splits3 = [splits2(1:2:end-1,1) splits2(2:2:end,1)]; %epoch boundaries
openinds = [];
for si = 1:size(splits2,1)
    openinds = [openinds splits2(si,1):splits2(si,2)-1];
end
closedinds = openinds+cueinc;

openinds_slow = [];
openinds_fast = [];
for si = 1:size(splits3,1)
    openinds_slow = [openinds_slow splits3(si,1):splits3(si,1)+cueinc-1];
    openinds_fast = [openinds_fast splits3(si,2):splits3(si,2)+cueinc-1];
end


stimepochinds_i = zeros(size(md.ti));
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds_initial_light);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_slow);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_fast);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds_final_dark);
if all(stimepochinds_i==1)
    stimepochinds_i = zeros(size(md.ti));
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds_initial_light)*1;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_slow)*2;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_fast)*3;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds)*4;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds_final_dark)*5;
else
    error
end

stimepochinds_b = zeros(size(md.tb));
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds_initial_light);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_slow);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_fast);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds_final_dark);
if all(stimepochinds_b==1)
    stimepochinds_b = zeros(size(md.tb));
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds_initial_light)*1;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_slow)*2;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_fast)*3;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds)*4;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds_final_dark)*5;
else
    error
end