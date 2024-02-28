

closedinds_initial_light = 0:59;
closedinds_final_dark = floor(seconds(dark_epoch_time_start)):floor(md.total_t);

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


trialepochinds_i = zeros(size(md.ti));
trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), closedinds_initial_light);
trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), openinds_slow);
trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), openinds_fast);
trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), closedinds);
trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), closedinds_final_dark);
if all(trialepochinds_i==1)
    trialepochinds_i = zeros(size(md.ti));
    trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), closedinds_initial_light)*1;
    trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), openinds_slow)*2;
    trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), openinds_fast)*3;
    trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), closedinds)*4;
    trialepochinds_i = trialepochinds_i + ismember(fix(md.ti), closedinds_final_dark)*5;
else
    error
end

trialepochinds_b = zeros(size(md.tb));
trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), closedinds_initial_light);
trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), openinds_slow);
trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), openinds_fast);
trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), closedinds);
trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), closedinds_final_dark);
if all(trialepochinds_b==1)
    trialepochinds_b = zeros(size(md.tb));
    trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), closedinds_initial_light)*1;
    trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), openinds_slow)*2;
    trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), openinds_fast)*3;
    trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), closedinds)*4;
    trialepochinds_b = trialepochinds_b + ismember(fix(md.tb), closedinds_final_dark)*5;
else
    error
end