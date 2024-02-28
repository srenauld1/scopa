function organize_epochs(md, data, sampling, tlim_epoch, nanpadlen_min, sorting_target, uniform_numbouts, epochinds)

error("unfinished function")

if strcmp(sampling, 'imaging')
    tfull = md.ti;
    tsamp_ei = md.trialepochinds_i;
elseif strcmp(sampling, 'behavior')
    tfull = md.tb;
    tsamp_ei = md.trialepochinds_b;
end

if ~exist('tlim_epoch', 'var') | isempty(tlim_epoch)
    tlim_epoch = Inf;
end

if numel(tlim_epoch)==1
    tlim_epoch = [0 tlim_epoch];
end

max_requested_epoch_time = tlim_epoch(2) - tlim_epoch(1);


if ~exist('nanpadlen_min', 'var') | isempty(nanpadlen_min)
    nanpadlen_min = 20;
end

if ~exist('sorting_target', 'var') | isempty(sorting_target)
    sorting_target = 'none';
end

if ~exist('uniform_numbouts', 'var') | isempty(uniform_numbouts)
    uniform_numbouts = 1;
end

if ~exist('epochinds', 'var') | isempty(epochinds)
    epochinds = num2cell(unique(md.trialepochinds_i));
end

%determine time axis for each epoch and bout
for epi = 1:length(epochinds)

    tind = find(ismember(tsamp_ei, epochinds{epi}));

    tsub = tfull(tind);
    % [~,idd1] = min(abs(xf-startsec));
    % [~,idd2] = min(abs(xf-stopsec));
    % indz_tmp = idd1:idd2;
    % xf = xf(indz_tmp);

    %now shorten according to numfram

    tlim = tlim_epoch + tsub(1);
    if tlim(2)==Inf
        tlim(2) = tsub(end);
    end

    % tkeepinds = tsub>=tlim(1) & tsub<=tlim(2);
    % tind = tind(tkeepinds);
    % t_in_stack{epi} = tsub(tkeepinds); %time in each epoch, relative to whole experiment
    % if any(~ismember(unique(diff(tsub)), unique(diff(tfull))))
    %     t_in_stack{epi} = tsub(1:length(tkeepinds)); %t is artificial bc it's discontiguous
    % end

    bout_endpoints = [0; find(diff(tind)~=1); length(tind)];
    t_in_epoch_elapsed = [];
    tind_in_stack{epi} = [];
    for bei = 2:length(bout_endpoints)

        tind_in_epoch{epi}{bei-1} = bout_endpoints(bei-1)+1 : bout_endpoints(bei); %time indices of each bout relative to epoch

        first_sample_bout = tind(tind_in_epoch{epi}{bei-1}(1));
        if first_sample_bout==1 %have to subtract preceding sample, since samples represent end time (except first sample)
            t_first_sample_bout = tfull(first_sample_bout);
        else
            t_first_sample_bout = tfull(first_sample_bout) - tfull(first_sample_bout-1);
        end

        t_in_stack_bouts{epi}{bei-1} = tsub(tind_in_epoch{epi}{bei-1}); %time in each bout, relative to whole stack
        t_in_bout = t_in_stack_bouts{epi}{bei-1} - t_in_stack_bouts{epi}{bei-1}(1) + t_first_sample_bout; %add elapsed of first sample, otherwise it's zero which is wrong (since sample time is end of sample)
        if isempty(t_in_epoch_elapsed)
            t_in_epoch_elapsed = t_in_bout;
            keep_bout_inds = t_in_epoch_elapsed<max_requested_epoch_time;
        else
            keep_bout_inds = t_in_bout + t_in_epoch_elapsed(end) < max_requested_epoch_time;
            t_in_epoch_elapsed = cat(1, t_in_epoch_elapsed, t_in_epoch_elapsed(end) + t_in_bout(keep_bout_inds));
        end
        tind_in_epoch{epi}{bei-1} = tind_in_epoch{epi}{bei-1}(keep_bout_inds);
        tind_in_stack{epi} = cat(1, tind_in_stack{epi}, tind(tind_in_epoch{epi}{bei-1})); %time indices of each epoch relative to whole stack/experiment
        if any(keep_bout_inds==0)
            break
        end
    end

end

%prepare nan padding between bouts, for each epoch
max_num_bouts = max(cellfun(@length, tind_in_epoch));
plotlen_total_withnanpad = 0;
for bni = 1:max_num_bouts
    bouts_exist_inds = cellfun(@length, tind_in_epoch)>=bni;
    bout_lengths = cellfun(@(x) length(x{bni}), tind_in_epoch(bouts_exist_inds));
    max_bout_len = max(bout_lengths);
    nanpadlen_all{bni} = nanpadlen_min + (max_bout_len - bout_lengths);
    plotlen_total_withnanpad = plotlen_total_withnanpad + max_bout_len + nanpadlen_min;
end


%prepare plot quantities, by inserting nan padding between bouts
% and for unwrapped cueang, bumpang, and ballang, across discontiguous bouts, shift values within each bout to start where the last bout left off, and normalize whole epoch to common scale



fn = all_struct_names(data, 'data');
for fni = 1:length(fn)

    for epi = 1:length(epochinds)

        datatmp = eval([fn{fni}]);
        if isvector(datatmp) & iscolumn(datatmp)
            datatmp = datatmp(:)';
        end
        datatmp = datatmp(:,tind_in_stack{epi});

        datanew{epi} = zeros(plotlen_total_withnanpad, 1);

        %unwrap some
        datatmp2utmp1 = unwrap(cueang2_tmp);
        prevend_cueang = 0;

        %x-pad (and for the unwrapped quantities, also y-shift)
        for bei = 1:max_num_bouts

            nanpad = nan(nanpadlen_all(epi,bei),1);

            boutlen = length(tind_in_epoch{epi}{bei});
            nanshift = sum(nanpadlen_all(epi,1:bei-1), 2); %shift bc of previous bout's nan padding
            newboutindzstart = tind_in_epoch{epi}{bei}(1)+nanshift;
            newboutindzstop = (newboutindzstart-1)+boutlen+nanpadlen_all(epi,bei);

            if ~unwrapped
                tmptmp = datatmp(:,tind_in_epoch{epi}{bei});
                datanew{epi}(:,newboutindzstart:newboutindzstop) = [tmptmp repmat(nanpad', [size(datatmp, 1) 1])];
            else
                %y shift and pad unwrapped quantities
                datatmp2utmp2 = datatmp2utmp1(tind_in_epoch{epi}{bei});
                datatmp2utmp2 = datatmp2utmp2 - (datatmp2utmp2(1) - prevend_cueang);
                datanew{epi}(newboutindzstart:newboutindzstop) = [datatmp2utmp2; nanpad];

                prevend_cueang = datatmp2utmp2(end); %align cueang bumpang and ballang to the cueang position at the end of previous bout
            end

        end

        plot_samples{epi} = 1:length(cueang2u{epi});

    end

    eval([fn{fni} '_epochs = datanew{epi}'])


end

%convert nans to zeros for rpr (which is assigned to plot color and cant have nans)
for epi = 1:numr/2
    for pii=1:length(pltindz)
        tmptmp = rpr{epi, pltindz(pii)};
        tmptmp(isnan(tmptmp)) = 0;
        rpr{epi, pltindz(pii)} = tmptmp;
    end
end

%replace diffs greater than pi with nan in the wrapped bumpang plot because the
%lines make it difficult to read
diff_rep_thresh = pi;
diff_spacing1 = 1;
difffilt1 = [zeros(1,diff_spacing1-1) 1 zeros(1,diff_spacing1-1) -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)
diff_spacing2 = 2;
difffilt2 = [zeros(1,diff_spacing2-1) 1 zeros(1,diff_spacing2-1) -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)
for epi = 1:numr/2
    for pii=1:length(pltindz)

        %bump angle
        mp_rep{epi, pltindz(pii)} = mp{epi, pltindz(pii)};

        diffsignal = conv(mp{epi, pltindz(pii)}, difffilt1, 'full');
        diffsignal = diffsignal((length(difffilt1) - 1)+1:end-(length(difffilt1) - (1 + (diff_spacing1-1))));
        diffsignal1 = [zeros((diff_spacing1-1)+1, 1); diffsignal];

        diffsignal = conv(mp{epi, pltindz(pii)}, difffilt2, 'full');
        diffsignal = diffsignal((length(difffilt2) - 1)+1:end-(length(difffilt2) - (1 + (diff_spacing2-1))));
        diffsignal2 = [zeros((diff_spacing2-1)+1, 1); diffsignal];

        excludeinds = abs(diffsignal1)>diff_rep_thresh | abs(diffsignal2)>diff_rep_thresh;
        mp_rep{epi, pltindz(pii)}(excludeinds) = nan; %get index right by appending 0 to front of diff

        %cue angle
        ca2_rep{epi, pltindz(pii)} = cueang2{epi};

        diffsignal = conv(cueang2{epi}, difffilt1, 'full');
        diffsignal = diffsignal((length(difffilt1) - 1)+1:end-(length(difffilt1) - (1 + (diff_spacing1-1))));
        diffsignal1 = [zeros((diff_spacing1-1)+1, 1); diffsignal];

        diffsignal = conv(cueang2{epi}, difffilt2, 'full');
        diffsignal = diffsignal((length(difffilt2) - 1)+1:end-(length(difffilt2) - (1 + (diff_spacing2-1))));
        diffsignal2 = [zeros((diff_spacing2-1)+1, 1); diffsignal];

        excludeinds = abs(diffsignal1)>diff_rep_thresh | abs(diffsignal2)>diff_rep_thresh;
        ca2_rep{epi, pltindz(pii)}(excludeinds) = nan; %get index right by appending 0 to front of diff


        %ball angle
        ba2_rep{epi, pltindz(pii)} = ballang2{epi};

        diffsignal = conv(ballang2{epi}, difffilt1, 'full');
        diffsignal = diffsignal((length(difffilt1) - 1)+1:end-(length(difffilt1) - (1 + (diff_spacing1-1))));
        diffsignal1 = [zeros((diff_spacing1-1)+1, 1); diffsignal];

        diffsignal = conv(ballang2{epi}, difffilt2, 'full');
        diffsignal = diffsignal((length(difffilt2) - 1)+1:end-(length(difffilt2) - (1 + (diff_spacing2-1))));
        diffsignal2 = [zeros((diff_spacing2-1)+1, 1); diffsignal];

        excludeinds = abs(diffsignal1)>diff_rep_thresh | abs(diffsignal2)>diff_rep_thresh;
        ba2_rep{epi, pltindz(pii)}(excludeinds) = nan; %get index right by appending 0 to front of diff


        %previous approach to just take diff: (left some jumps though) mp_rep{rind, pltindz(pii)}([0; diff(mp_rep{rind, pltindz(pii)})]>diff_rep_thresh) = nan; %get index right by appending 0 to front of diff

    end
end



switch sorting_target
    case 'bumpang'
        [~, indz_sort] = sort(bumpang(tind,pltindz(bump_method_index)));
end
