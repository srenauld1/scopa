function [dofit, pth_fitdata_epoch, ft, depvp, gof, depv_good_inds] = load_fitdata(pth_fitdata_prefix, epochinds_str, omit_time_from_savemodel_datestr, use_saved_model)

pth_fitdata_epoch_pattern = [pth_fitdata_prefix '_' strrep(epochinds_str, '_', ',') '_*_fitdata_.mat'];
fitdata_saved_files = rdir(pth_fitdata_epoch_pattern);
timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
if omit_time_from_savemodel_datestr
    timestr = timestr(1:8);
end
pth_fitdata_epoch = strrep(pth_fitdata_epoch_pattern, '*', timestr);

if use_saved_model && ~isempty(fitdata_saved_files)
    fitdata_saved_files = natsortfiles(fitdata_saved_files);
    load(fitdata_saved_files(end).name) %load most recent, based on timestamp in filename
    dofit = 0;
else
    dofit = 1;
    ft = [];
    depvp = [];
    gof = [];
    depv_good_inds = [];
end