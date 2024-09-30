function plotvars = pad_timeseries_discontinuities(indv, depv, pred, epochinds_pure_ts_m, sampinds_depvp, ...
    num_dim_indvp, numroi_plot, max_tinds, timeseries_numsegments, numsampnan)



epochinds_pure_ts_m = epochinds_pure_ts_m.';

%%pad discontinuities in depv and predicted depv variables for timeseries plots (not the other plots)

%%%%%% FIRST PAD ANY DISCONTINUITIES WITH NAN (e.g., where bouts have been removed), these have suffix *_cont
tinds_cont = [];
seg_endpoints = [0; vec(find(diff(sampinds_depvp)~=1)); numel(sampinds_depvp)];
for bei = 2:length(seg_endpoints)
    tinds_cont{bei-1} = seg_endpoints(bei-1)+1 : seg_endpoints(bei); %cell of contiguous indices
end

indvnan_cont = [];
depvnan_cont = [];
prednan_cont = [];
pureepochnan_cont = [];
tinds_cont_nan = [];
nanpad_indv = nan(num_dim_indvp, numsampnan);
% nanpad_depv = nan(num_dim_depvp, numsampnan);
nanpad_depv = nan(numroi_plot, numsampnan);
nanpad = nanpad_depv(1,:);
for tbi = 1:length(tinds_cont) %pad any discontinuities with nan
    indvnan_cont = cat(2, indvnan_cont, nanpad_indv, indv( :, tinds_cont{tbi}));
    depvnan_cont = cat(2, depvnan_cont, nanpad_depv, depv(  :, tinds_cont{tbi}));
    prednan_cont = cat(2, prednan_cont, nanpad_depv, pred(  :, tinds_cont{tbi}));
    pureepochnan_cont = cat(2, pureepochnan_cont,  nanpad, epochinds_pure_ts_m( tinds_cont{tbi}));
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
numsamp_depvnan_cont = size(depvnan_cont, 2);
tinds_seg = cell(1, timeseries_numsegments);
if isempty(max_tinds) || max_tinds > numsamp_depvnan_cont  %if too many samples to see, plot only the first max_tinds of them
    tinds_seg{1} = 1:numsamp_depvnan_cont;
    truncstr = '';
else
    if timeseries_numsegments>1
        seglength = floor(max_tinds/timeseries_numsegments);
        segspacing = floor(numsamp_depvnan_cont/timeseries_numsegments);
        for tnsi = 1:timeseries_numsegments
            tinds_seg{tnsi} = [1:seglength]+segspacing*(tnsi-1)+segspacing-seglength;
        end
    else
        tinds_seg{1} = 1:max_tinds;
    end
end
truncstr = ['TRUNC' num2str(timeseries_numsegments) 'SEG'];


depvnan_seg = depvnan_cont( :, tinds_seg{1});
prednan_seg = prednan_cont( :, tinds_seg{1});
pureepochnan_seg = pureepochnan_cont( :, tinds_seg{1});
for tnsi = 2:timeseries_numsegments
    depvnan_seg = cat(2, depvnan_seg, nanpad_depv, depvnan_cont( :, tinds_seg{tnsi}));
    prednan_seg = cat(2, prednan_seg, nanpad_depv, prednan_cont( :, tinds_seg{tnsi}));
    pureepochnan_seg = cat(2, pureepochnan_seg, nanpad, pureepochnan_cont( :, tinds_seg{tnsi}));
end


plotvars.tinds_cont = tinds_cont;
plotvars.tinds_cont_nan = tinds_cont_nan;
plotvars.tinds_cont_nan_nonan = tinds_cont_nan_nonan;

plotvars.nanpad_indv = nanpad_indv;
plotvars.nanpad_depv = nanpad_depv;

plotvars.indvnan_cont = indvnan_cont;
plotvars.depvnan_cont = depvnan_cont;
plotvars.prednan_cont = prednan_cont;
plotvars.pureepochnan_cont = pureepochnan_cont;


plotvars.pureepochnan_seg = pureepochnan_seg;
plotvars.prednan_seg = prednan_seg;
plotvars.depvnan_seg = depvnan_seg;
plotvars.seglength = seglength;
plotvars.truncstr = truncstr;


