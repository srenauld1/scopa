function epochs = define_stim_epoch_indices(ft_misoffset_sec, ti, datenum)



if datenum<20231119

    num_cycles = 3;
    closed_final_dark_duration = 60; %final seconds
    bout_duration_sec = 20;
    closed_initial_light_duration = 60;

    %boutinds_onecycle only holds bout indices for periodic epochs, non-periodic are handled separately
    boutinds_onecycle.closedinitiallight = [];
    boutinds_onecycle.openslow = [1 5];
    boutinds_onecycle.openfast = [3 7];
    boutinds_onecycle.closed = [2 4 6 8];
    boutinds_onecycle.dark = [];
    boutinds_onecycle.closedfinaldark = [];

elseif datenum>=20231119 && datenum<20231231

    num_cycles = 6;
    closed_final_dark_duration = 0; %final seconds
    bout_duration_sec = 20;
    closed_initial_light_duration = 60;

    %closed initial light does not count toward boutinds_onecycle below, but is counted as bout 1 and epochind 1
    boutinds_onecycle.closedinitiallight = [];
    boutinds_onecycle.openslow = [1 5];
    boutinds_onecycle.openfast = [3 7];
    boutinds_onecycle.closed = [2 4 6 8 10];
    boutinds_onecycle.dark = [9];
    boutinds_onecycle.closedfinaldark = [];

else

    num_cycles = 0;
    closed_final_dark_duration = 0; %final seconds
    bout_duration_sec = 0;
    closed_initial_light_duration = 60000;

    %closed initial light does not count toward boutinds_onecycle below, but is counted as bout 1 and epochind 1
    boutinds_onecycle.closedinitiallight = [];
    boutinds_onecycle.openslow = [];
    boutinds_onecycle.openfast = [];
    boutinds_onecycle.closed = [];
    boutinds_onecycle.dark = [];
    boutinds_onecycle.closedfinaldark = [];

end


epochs.closedinitiallight = 1;
epochs.openslow = 2;
epochs.openfast = 3;
epochs.closed = 4;
epochs.dark = 5;
epochs.closedfinaldark = 6;

boutinds_onecycle_cell = struct2cell(boutinds_onecycle);
boutinds_onecycle_cell = boutinds_onecycle_cell(~cellfun(@isempty, boutinds_onecycle_cell));
boutinds_onecycle_vec = cat(2, boutinds_onecycle_cell{:});


if ~isempty(boutinds_onecycle_vec)
    if min(boutinds_onecycle_vec)~=1 || ~isequal(unique(cat(2, boutinds_onecycle_vec)), sort(cat(2, boutinds_onecycle_vec)), min(boutinds_onecycle_vec):max(boutinds_onecycle_vec))
        error("epoch indices that are part of a 'cycle', when sorted, must be a contiguous list of non-repeating integers, with minimum of 1")
    end
end
num_bouts_per_cycle = max(boutinds_onecycle_vec); %cycle doesn't including non-repeating bouts, like initial and final

boutendpoints_sec_epoch.closedinitiallight = [0 closed_initial_light_duration + ft_misoffset_sec];

boutstarttimes(1) =  boutendpoints_sec_epoch.closedinitiallight(end);
for bi = [1:num_bouts_per_cycle*num_cycles]+1
    boutstarttimes(bi) = boutstarttimes(bi-1) + bout_duration_sec;
end

%then do the periodic bouts
fn = fieldnames(boutinds_onecycle);
for fni = 1:numel(fn)
    if ~isempty(boutinds_onecycle.(fn{fni}))
        epochind_onecycle.(fn{fni}) = boutinds_onecycle.(fn{fni});
        boutinds.(fn{fni}) = epochind_onecycle.(fn{fni})'+num_bouts_per_cycle*([1:num_cycles]-1);
        boutinds.(fn{fni}) = boutinds.(fn{fni})(:);
        boutstarttimes_oneepoch.(fn{fni}) = boutstarttimes(boutinds.(fn{fni}));
        boutendpoints_sec_epoch.(fn{fni}) = [];
        for bstei = 1:numel(boutstarttimes_oneepoch.(fn{fni}))
            boutendpoints_sec_epoch.(fn{fni}) = cat(1, boutendpoints_sec_epoch.(fn{fni}), [boutstarttimes_oneepoch.(fn{fni})(bstei), boutstarttimes_oneepoch.(fn{fni})(bstei) + bout_duration_sec]);
        end
    end
end


%fill in extra frames at end, caused by socket-daq lag
[~, finalbout_epochind] = max(cell2mat(struct2cell(structfun(@(x) max(vec(x)), boutendpoints_sec_epoch, 'UniformOutput', false))));
boutendpoints_sec_epoch_cell = struct2cell(boutendpoints_sec_epoch);
if closed_final_dark_duration==0
    if boutendpoints_sec_epoch_cell{finalbout_epochind}(end)~=ti(end) %closedinds(end)~=floor(ti(end))
        boutendpoints_sec_epoch_cell{finalbout_epochind}(end)=ti(end);
    end
else
    tmpendpoint = boutendpoints_sec_epoch_cell{finalbout_epochind}(end);
end
boutendpoints_sec_epoch = cell2struct(boutendpoints_sec_epoch_cell, fieldnames(boutendpoints_sec_epoch));
if closed_final_dark_duration>0
    boutendpoints_sec_epoch.closedfinaldark = [tmpendpoint ti(end)];
end

fn = fieldnames(boutendpoints_sec_epoch);
epochinds_ts_i = zeros(1, numel(ti));
for fni = 1:numel(fn)
    if size(boutendpoints_sec_epoch.(fn{fni}), 2)==2
        mtchtmp = ti'>=boutendpoints_sec_epoch.(fn{fni})(:,1) & ti'<boutendpoints_sec_epoch.(fn{fni})(:,2);
        mtchtmp = sum(mtchtmp, 1);
        if any(mtchtmp>1)
            error("epochs misaligned")
        end
        if any(ismember(find(epochinds_ts_i), find(mtchtmp)))
            error("epochs misaligned")
        end
        epochinds_ts_i = epochinds_ts_i + mtchtmp*fni;
    end
end

epochs.epochinds_ts_i = epochinds_ts_i;
