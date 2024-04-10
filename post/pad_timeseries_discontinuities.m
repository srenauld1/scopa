% function pad_timeseries_discontinuities

numsampnan = 10;


%%pad discontinuities in depv and predicted depv variables for timeseries plots (not the other plots)

%%%%%% FIRST PAD ANY DISCONTINUITIES WITH NAN (e.g., where bouts have been removed), these have suffix *_cont
tinds_cont = [];
seg_endpoints = [0 find(diff(fitdata.keepinds_depv)~=1) length(fitdata.keepinds_depv)];
for bei = 2:length(seg_endpoints)
    tinds_cont{bei-1} = seg_endpoints(bei-1)+1 : seg_endpoints(bei); %cell of contiguous indices
end

indvnan_cont = [];
depvnan_cont = [];
depvpnan_cont = [];
pureepochnan_cont = [];
tinds_cont_nan = [];
nanpad_indv = nan(numsampnan, fitin.num_dim_indv_pre);
nanpad_depv = nan(numsampnan, fitin.num_dim_depv_pre);
nanpadvec = nanpad_depv(:,1);
for tbi = 1:length(tinds_cont) %pad any discontinuities with nan
    indvnan_cont = cat(1, indvnan_cont,  nanpad_indv, indv( tinds_cont{tbi}, :));
    depvnan_cont = cat(1, depvnan_cont,  nanpad_depv, depv_all( tinds_cont{tbi}, :));
    depvpnan_cont = cat(1, depvpnan_cont,  nanpad_depv, fitdata.depvp( tinds_cont{tbi}, :));
    pureepochnan_cont = cat(1, pureepochnan_cont,  nanpadvec, fitdata.pureepoch_keepinds( tinds_cont{tbi}));
    if tbi==1
        tmpstart = 1;
    else
        tmpstart = tinds_cont_nan{tbi-1}(end)+1;
    end
    tinds_cont_nan{tbi} = [ tmpstart : tmpstart+(numsampnan-1)+length(tinds_cont{tbi}) ]; %indices into nan padded array with the nans
    tinds_cont_nan_nonan{tbi} = [ tmpstart+numsampnan : tmpstart+(numsampnan-1)+length(tinds_cont{tbi}) ]; %indices into nan padded array without the nans
end
if ~isempty(find(diff(cell2mat(tinds_cont_nan(:)'))~=1))
    error("tinds_cont_nan must be contiguous")
end

%%%%%% NEXT SELECT SEGMENTS TO TRUNCATE THE PLOT (IN CASE TIMESERIES IS TOO LONG TO SEE EASILY) AND PAD THOSE DISCONTINUITIES WITH NAN ALSO, these have suffix *_seg
tinds_seg = cell(1, timeseries_numsegments);
if isempty(max_tinds) || max_tinds > size(depvnan_cont, 2)  %if too many samples to see, plot only the first max_tinds of them
    tinds_seg{1} = 1:size(depvnan_cont, 2);
    truncstr{epi} = '';
else
    if timeseries_numsegments>1
        seglength{epi} = floor(max_tinds/timeseries_numsegments);
        segspacing = floor(size(depvnan_cont, 2)/timeseries_numsegments);
        for tnsi = 1:timeseries_numsegments
            tinds_seg{tnsi} = [1:seglength{epi}]+segspacing*(tnsi-1)+segspacing-seglength{epi};
        end
    else
        tinds_seg{1} = 1:max_tinds;
    end
end
truncstr{epi} = ['TRUNC' num2str(timeseries_numsegments) 'SEG'];


depvnan_seg{epi} = depvnan_cont( :, tinds_seg{1});
depvpnan_seg{epi} = depvpnan_cont( :, tinds_seg{1});
pureepochnan_seg{epi} = pureepochnan_cont( :, tinds_seg{1});
for tnsi = 2:timeseries_numsegments
    depvnan_seg{epi} = cat(2, depvnan_seg{epi}, nanpad_depv, depvnan_cont( :, tinds_seg{tnsi}));
    depvpnan_seg{epi} = cat(2, depvpnan_seg{epi}, nanpad_depv, depvpnan_cont( :, tinds_seg{tnsi}));
    pureepochnan_seg{epi} = cat(2, pureepochnan_seg{epi}, nanpadvec, pureepochnan_cont( :, tinds_seg{tnsi}));
end



minis =  min(cell2mat(cellfun(@(x) min(x(:)),  depv,  'UniformOutput',  false))); %min depv across all epochs
maxis =  max(cell2mat(cellfun(@(x) max(x(:)),  depv,  'UniformOutput',  false))); %max depv across all epochs

epochinds_str_all = strjoin(epochinds_str, ',,');


for epi = 1:length(epochinds)
    [indvsort{epi}, indvsortidx] = sort(indv{epi}(:,hackindvdim));
    depvp_sort{epi} = depvp(:, indvsortidx);
end
