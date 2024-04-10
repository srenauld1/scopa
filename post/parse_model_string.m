function annspec = parse_model_string(modeltype, chopt, num_dim_indv_pre)

%right now order of characters within an underscore doesn't matter, so the code doesn't treat order 

% right now channel parsing "works" but the ann is not optimized for multiple layers, so how channel and layer specification works is not super intuitive 

chopt.lay = cell2mat(chopt.lay);
chopt.chan = cell2mat(chopt.chan);
chopt.hot = cell2mat(chopt.hot);
exprpos = [chopt.lay '\d*[' chopt.chan '\d*]?'];
exprlay = [chopt.lay '\d*'];
exprchan = [chopt.chan '\d*'];
exprnumneuronpss = '%d%*s'; %number at start of substring
exprlin = strjoin(chopt.lin, '|');
expract = strjoin(chopt.act, '|');
exprhotsuf = strjoin(chopt.hotsuf, '|');
exprhot = [chopt.hot '\d*[^' strjoin([chopt.act chopt.lin chopt.hot], '|') ']*']; %h followed by a number followed by one or more optional chars that aren't any of chars in chl, cha, or chh
exprbin = [chopt.hot '%d'];
exprhotx = [chopt.hot '\d*x'];


numchan_total_currlay = num_dim_indv_pre; %total for input layer, wll be updated for each layer
prevlayer = 1;
allchan = [];
spl = strsplit(modeltype, '_');
if strcmp(spl{1}, 'ann')

    tmp = find(~cellfun(@isempty, regexp(spl, exprpos)));

    for si = 1:length(tmp)
        if si==length(tmp)
            specinds{si} = tmp(si):length(spl);
        else
            specinds{si} = tmp(si):tmp(si+1)-1;
        end
    end

    num_specified_positions = length(specinds);
    for si = 1:num_specified_positions
        strposition = spl{specinds{si}(1)};
        num_substrings = length(specinds{si})-1;
        strlay = cell2mat(regexp(strposition, exprlay, 'match'));
        layer = str2double(strlay(2:end));
        layerfield = ['L' num2str(layer)];

        if layer~=prevlayer %new layer
            if layer~=prevlayer+1
                error("layer spec must be sequential")
            end
            prevlayer = layer;
            numchan_total_currlay = max(allchan);
            allchan = [];
        end

        strchan = cell2mat(regexp(strposition, exprchan, 'match'));
        channel = str2double(strchan(2:end));
        if isempty(channel) || isnan(channel)
            channel = 1:numchan_total_currlay;
        end
        allchan = [allchan channel];

        spec_oneposition = [];
        for ni = 1:num_substrings

            nstring = spl{specinds{si}(ni+1)};

            num_neurons_for_this_substring = sscanf(nstring, exprnumneuronpss);

            [strlin,indslin] = regexp(nstring, exprlin, 'match');
            if numel(unique(strlin)) ~= numel(strlin)
                error("there are duplicate linear function chars within a single neuron string")
            end
            [stract_nothot,indsact] = regexp(nstring, expract, 'match');
            if numel(unique(stract_nothot)) ~= numel(stract_nothot)
                error("there are duplicate (not hot) activation function chars within a single neuron string")
            end
            [strhot,indshot] = regexp(nstring, exprhot, 'match');
            if numel(unique(strhot)) ~= numel(strhot)
                error("there are duplicate hot function substrings within a single neuron string")
            end

            if isempty(strlin)
                error("missing linear function specifier")
            end
            if isempty(stract_nothot) && isempty(strhot)
                error("missing activation function specifier")
            end

            hotstrlengths = cellfun(@numel, strhot);
            if length(indshot)>1 % find hot string positions in spec string, don't need this now since order doesn't matter, but in case order ever matters
                cumtmp = 0;
                for hi = 2:length(indshot)
                    cumtmp = cumtmp + hotstrlengths(hi-1)-1;
                    indshot(hi) = indshot(hi)-cumtmp;
                end
            end

            total_num_function_strings = length(strlin) + length(stract_nothot) + length(strhot); %hot strings have multiple chars, all others have one
            stract = [stract_nothot strhot];
            if total_num_function_strings>2
                disp("making all combinations of linear and activation function specifiers")
            end
            spec_onesubstring = combinations(strlin, stract); %you can call this even if total_num_function_strings==2
            nullinds = find(strcmp(spec_onesubstring.strlin, 'l') & strcmp(spec_onesubstring.stract, 'a')); %'la' is not valid since it means no functions at all, so remove it if it appears 
            spec_onesubstring(nullinds,:) = [];

            for ssi = 1:length(spec_onesubstring.stract)
                nhbtmp = sscanf(spec_onesubstring.stract{ssi}, exprbin);
                strhotsuf = regexp(spec_onesubstring.stract{ssi}, exprhotsuf, 'match');
                spec_onesubstring.numbinhot{ssi} = nhbtmp;
                spec_onesubstring.independently_discretized_hot_dims{ssi} = strhotsuf;
            end

            spec_onesubstring = repmat(spec_onesubstring, [num_neurons_for_this_substring 1]);
            spec_oneposition = [spec_oneposition; spec_onesubstring]; %cat spec from each parsed underscore

        end

        for ci = 1:length(channel)
            channelfield = ['C' num2str(channel(ci))];
            annspec.(layerfield).(channelfield) = spec_oneposition;
            if ci<numchan_total_currlay %if hot type 'x', only use on last channel
                removehotinds = ~cellfun(@isempty, regexp(spec_oneposition.stract, exprhotx));
                annspec.(layerfield).(channelfield).stract(removehotinds) = {'y'};
                annspec.(layerfield).(channelfield).numbinhot(removehotinds) = {[]};
                annspec.(layerfield).(channelfield).independently_discretized_hot_dims(removehotinds) = {[]};
            end
        end

    end

end