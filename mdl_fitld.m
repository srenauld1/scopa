function [dofit, pth_fitdata, ft, pred, gof, gof_val, depv_good_inds] = mdl_fitld(pthpre, ld, valnum, vfi)

omit_time_from_savemodel_datestr = 0;

if valnum==0
    pthpat = [pthpre '_0_*_fitdata_.mat'];
else
    pthpat = [pthpre '_' num2str(vfi) '_*_fitdata_.mat'];
end

pthfitdat = rdir(pthpat);
timestr = char(datetime('now','TimeZone','local','Format','yyyyMMddHHmmssSS'));
if omit_time_from_savemodel_datestr
    timestr = timestr(1:8);
end
pth_fitdata = strrep(pthpat, '*', timestr);

if ld && ~isempty(pthfitdat)
    pthfitdat = natsortfiles(pthfitdat);
    if numel(pthfitdat)>1
        fprintf("there are multiple fitata files, loading most recent, based on timestamp in filename" + newline)
    end
    load(pthfitdat(end).name, 'ft', 'pred', 'gof', 'gof_val', 'depv_good_inds') 
    dofit = 0;
else
    dofit = 1;
    ft = [];
    pred = [];
    gof = [];
    gof_val = [];
    depv_good_inds = [];
end