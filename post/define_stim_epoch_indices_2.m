function epochinds_ts_i = define_stim_epoch_indices_2(ft_misoffset_sec, md)

%hacking the timing problem on berg1, will be fixed in next dataset

% if ~exist('ft_misoffset_sec', 'var')
%     if datenum==20231119 & flynum==1
%         ft_misoffset_sec = 7;
%     elseif datenum==20231119 & flynum==2
%         ft_misoffset_sec = 3;
%     elseif datenum==20231119 & flynum==3
%         ft_misoffset_sec = 2;
%     end
% end

closed_initial_light_duration = 60;
num_total_epochs = 10;  %not counting initial closed/light epoch
num_bouts_per_epoch = 6;
bout_duration_sec = 20;

% closedinds_initial_light = 0:ft_misoffset_sec;
boutendpoints_sec_closedinds_initial_light = [0 closed_initial_light_duration - ft_misoffset_sec];


% boutstarttimes = boutendpoints_sec_closedinds_initial_light(end)+1:bout_duration_sec:round(md.t_ts_i(end));
boutstarttimes(1) = boutendpoints_sec_closedinds_initial_light(end);
for bi = [1:num_total_epochs*num_bouts_per_epoch]+1
    boutstarttimes(bi) = boutstarttimes(bi-1) + bout_duration_sec;
end

%closed initial light does not count toward boutinds_onecycle below, but is counted as bout 1 and epochind 1
boutinds_onecycle.openslow = [1 5];
boutinds_onecycle.openfast = [3 7];
boutinds_onecycle.closed = [2 4 6 8 10];
boutinds_onecycle.opendark = [9];

epochinds.initialclosed = 1;
epochinds.openslow = 2;
epochinds.openfast = 3;
epochinds.closed = 4;
epochinds.dark = 5;

fn = fieldnames(boutinds_onecycle);
for fni = 1:numel(fn)
    epochind_onecycle{fni} = boutinds_onecycle.(fn{fni});
end

%first do the periodic bouts
for eii = 1:numel(epochind_onecycle)
    boutinds{eii} = epochind_onecycle{eii}'+num_total_epochs*([1:num_bouts_per_epoch]-1);
    boutinds{eii} = boutinds{eii}(:);
    boutstarttimes_oneepoch{eii} = boutstarttimes(boutinds{eii});
    boutendpoints_sec_epoch{eii} = [];
    for bstei = 1:numel(boutstarttimes_oneepoch{eii})
        % boutinds_epoch{eii} = cat(2, boutinds_epoch{eii}, boutstarttimes_epoch{eii}(bstei) : boutstarttimes_epoch{eii}(bstei) + bout_duration_sec - 1);
        boutendpoints_sec_epoch{eii} = cat(1, boutendpoints_sec_epoch{eii}, [boutstarttimes_oneepoch{eii}(bstei), boutstarttimes_oneepoch{eii}(bstei) + bout_duration_sec]);
    end
end

%insert initial closed epoch/bout
boutendpoints_sec_epoch{eii+1} = boutendpoints_sec_closedinds_initial_light;
boutendpoints_sec_epoch = circshift(boutendpoints_sec_epoch, 1);

%fill in extra frames at end, caused by clock alignment problem (at least)
[~, finalbout_epochind] = max(cell2mat(cellfun(@(x) max(vec(x)), boutendpoints_sec_epoch, 'UniformOutput', false)));
if boutendpoints_sec_epoch{finalbout_epochind}(end)~=md.t_ts_i(end) %closedinds(end)~=floor(md.t_ts_i(end))
    boutendpoints_sec_epoch{finalbout_epochind}(end)=md.t_ts_i(end);
end


epochinds_ts_i = zeros(1, numel(md.t_ts_i));
for eii = 1:numel(boutendpoints_sec_epoch)
    mtchtmp = md.t_ts_i'>=boutendpoints_sec_epoch{eii}(:,1) & md.t_ts_i'<boutendpoints_sec_epoch{eii}(:,2);
    mtchtmp = sum(mtchtmp, 1);
    if any(mtchtmp>1)
        error("epochinds misaligned")
    end
    if any(ismember(find(epochinds_ts_i), find(mtchtmp)))
        error("epochinds misaligned")
    end
    epochinds_ts_i = epochinds_ts_i + mtchtmp*eii;
end

% epochinds_ts_b = zeros(1, numel(md.t_ts_b));
% for eii = 1:numel(boutendpoints_sec_epoch)
%     mtchtmp = md.t_ts_b'>=boutendpoints_sec_epoch{eii}(:,1) & md.t_ts_b'<boutendpoints_sec_epoch{eii}(:,2);
%     mtchtmp = sum(mtchtmp, 1);
%     if any(mtchtmp>1)
%         error("epochinds misaligned")
%     end
%     if any(ismember(find(epochinds_ts_b), find(mtchtmp)))
%         error("epochinds misaligned")
%     end
%     epochinds_ts_b = epochinds_ts_b + mtchtmp*eii;
% end
