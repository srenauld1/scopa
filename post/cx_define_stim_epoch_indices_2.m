

if datenum==20231119 & flynum==1
    arbitrary_crap = 53;
elseif datenum==20231119 & flynum==2
    arbitrary_crap = 57;
elseif datenum==20231119 & flynum==3
    arbitrary_crap = 58;
end

% arbitrary_crap = 59;

closedinds_initial_light = 0:arbitrary_crap;

num_total_epochs = 10;  %not counting initial closed/light epoch 
num_bouts_per_epoch = 6; 
bout_duration_seconds = 20;
boutstarttimes = closedinds_initial_light(end)+1:bout_duration_seconds:round(seconds(md.trialtime(end)));


epoch_ind = {[1 5], [3 7], [9], [2 4 6 8 10]};
for eii = 1:length(epoch_ind)
    boutinds{eii} = epoch_ind{eii}'+num_total_epochs*([1:num_bouts_per_epoch]-1);
    boutinds{eii} = boutinds{eii}(:);
    boutstarttimes_epoch{eii} = boutstarttimes(boutinds{eii});
    boutinds_epoch{eii} = [];
    for bstei = 1:length(boutstarttimes_epoch{eii})
        boutinds_epoch{eii} = cat(2, boutinds_epoch{eii}, boutstarttimes_epoch{eii}(bstei) : boutstarttimes_epoch{eii}(bstei) + bout_duration_seconds - 1);
    end
end

openinds_slow = boutinds_epoch{1};
openinds_fast = boutinds_epoch{2};
openinds_dark = boutinds_epoch{3};
closedinds = boutinds_epoch{4};


if closedinds(end)~=floor(seconds(md.trialtime(end)))
    xtra = setxor(closedinds(end), closedinds(end):floor(seconds(md.trialtime(end))));
    closedinds(end+1:end+length(xtra)) = xtra;
end


stimepochinds_i = zeros(size(md.ti));
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds_initial_light);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_slow);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_fast);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_dark);
stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds);
if all(stimepochinds_i==1)
    stimepochinds_i = zeros(size(md.ti));
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds_initial_light)*1;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_slow)*2;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_fast)*3;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), openinds_dark)*4;
    stimepochinds_i = stimepochinds_i + ismember(fix(md.ti), closedinds)*5;
else
error
end

stimepochinds_b = zeros(size(md.tb));
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds_initial_light);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_slow);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_fast);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_dark);
stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds);
if all(stimepochinds_b==1)
    stimepochinds_b = zeros(size(md.tb));
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds_initial_light)*1;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_slow)*2;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_fast)*3;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), openinds_dark)*4;
    stimepochinds_b = stimepochinds_b + ismember(fix(md.tb), closedinds)*5;
else
error
end