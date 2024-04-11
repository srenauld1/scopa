

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


epochinds_ts_i = zeros(size(md.t_ts_i));
epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), closedinds_initial_light);
epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), openinds_slow);
epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), openinds_fast);
epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), closedinds);
epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), closedinds_final_dark);
if all(epochinds_ts_i==1)
    epochinds_ts_i = zeros(size(md.t_ts_i));
    epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), closedinds_initial_light)*1;
    epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), openinds_slow)*2;
    epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), openinds_fast)*3;
    epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), closedinds)*4;
    epochinds_ts_i = epochinds_ts_i + ismember_single(fix(md.t_ts_i), closedinds_final_dark)*5;
else
    error
end

epochinds_ts_b = zeros(size(md.t_ts_b));
epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), closedinds_initial_light);
epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), openinds_slow);
epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), openinds_fast);
epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), closedinds);
epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), closedinds_final_dark);
if all(epochinds_ts_b==1)
    epochinds_ts_b = zeros(size(md.t_ts_b));
    epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), closedinds_initial_light)*1;
    epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), openinds_slow)*2;
    epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), openinds_fast)*3;
    epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), closedinds)*4;
    epochinds_ts_b = epochinds_ts_b + ismember_single(fix(md.t_ts_b), closedinds_final_dark)*5;
else
    error
end