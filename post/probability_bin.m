function [out, outmeans, bin_prctiles] = probability_bin(in, numbin_goal, outflag, minsamp)

%%
if ~exist('minsamp', 'var')
    minsamp = 20;
end
if ~exist('outflag', 'var')
    outflag = 0;
end
if ndims(in)>2
    error("must be 2d for now")
end
if mod(log2(numbin_goal) / log2(2), 1)~=0
    error("requested number of bins must be power of 2")
end
if any(isnan(in(:)))
    error("nans in input to probability_bin")
end


out = zeros(size(in), 'uint16');

inds = reshape(1:numel(in), size(in));
in = {in};
inds = {inds};

flag_ties = 0;
[outvals, outinds, flag_ties] = median_split_input(in, inds, numbin_goal, minsamp, flag_ties);

if outflag
    outsz = cellfun(@(x) size(x,2), outvals, 'UniformOutput', false);
    outsz = unique(cell2mat(outsz));
    if numel(outsz)>1
        error("unequal dimensionality across bins")
    end
    outmeanstmp = cellfun(@(x) mean(x,1), outvals, 'UniformOutput', false);
    for omi = 1:outsz
        outmeans(omi,:) = cell2mat(cellfun(@(x) x(omi), outmeanstmp, 'UniformOutput', false));
    end

else
    outmeans = [];
end

% figure; histogram2(outmeans1, outmeans2)

for i = 1:numel(outinds)
    out(outinds{i}) = i;
end

if any(out(:)==0)
    error("should not be any zeros after probability_bin")
end

numsamp = cellfun(@(x) size(x,1), outinds);

if range(numsamp)>1 && ~flag_ties %should differ by 1 at most, for now, with numbin_goal forced to be power of 2
    error("bins should have nearly equal number samples")
end
if any(diff(out, [], 2))
    error("dims must have equal rank")
end


bin_prctiles = tabulate(out(:,1));
bin_prctiles = bin_prctiles(:,3);

end

function [outvals, outinds, flag_ties] = median_split_input(in, inds, numbin_goal, minsamp, flag_ties)

numbin_in = length(in);
numbin_out = numbin_in*2;
splitcount = 0;
outvals = cell(1, numbin_out);
outinds = cell(1, numbin_out);
for i = 1:numbin_in
    splitcount = splitcount+1;
    varin = var(in{i});
    [~, mxi] = max(varin);
    tmp = in{i}(:,mxi);
    mvi = median(tmp);
    mvi_ties = find(tmp==mvi); %equal to median
    if numel(mvi_ties)<=1
        spl = tmp<mvi;
    else
        if ~flag_ties %catch first time ties happen, to record if ties happen at least once
            flag_ties = 1;
            sprintf("warning, multiple ties in probability bin")
        end
        spl = quantileranks(tmp,2)==1; %quantileranks breaks ties, unlike simple median split, but is slower so only use when necessary; there are only many ties when binning pixel indices; since in this case the goal is spatially equal-volume ROIs,
    end
    outvals{splitcount*2-1} = in{i}(~spl,:);
    outvals{splitcount*2} = in{i}(spl,:);
    outinds{splitcount*2-1} = inds{i}(~spl,:);
    outinds{splitcount*2} = inds{i}(spl,:);

end
numsamp = cellfun(@(x) size(x,1), outvals);
nsamp_min = min(numsamp);
nsamp_mean = mean(numsamp);
numbin_curr = length(outvals);

if nsamp_min<minsamp
    error("fewer than " + num2str(minsamp) + " samples per bin, adjust requested number bins or change minimum samples allowed (minsamp)")
end

if numbin_curr<numbin_goal
    [outvals, outinds] = median_split_input(outvals, outinds, numbin_goal, minsamp, flag_ties);
elseif numbin_curr>numbin_goal %this check is pointless bc numbin_goal is forced to be power of 2, but not in future when that restriction gets lifted
    error("overshot number bins")
end

end