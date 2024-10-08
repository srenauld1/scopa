
% params for carl's old project; not set if you're not carl (if you don't have a recording folder with substring 'f91g_syt')

o.mn.oldcarl = 0;
if (~isempty(o.rec) || ~isempty(cell2mat(o.rec))) && all(contains(o.rec, 'f91g_syt')) %~strcmp(fspc_recdate, '*') && startsWith(fspc_recdate{1}, '22') %override some settings for old project
    if numel(o.rec)>1
        error("right now old project is one file at a time")
    end
    o.mn.oldcarl = 1;
    o.mn.oldcarl = 1;
    o.sld.tcropfront = 4; % how many samples to remove from beginning of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
    o.sld.tcropback = 2; % how many samples to remove from end of stack
    o.mfit.mdl_lag_sec = 1; %how many samples indv precedes depv for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
    o.mfit.mdl_length_sec = 1.25;
    o.mn.dodaq = 0; %process daq data
    o.mn.doftv = 0; %temporal resample fictrac video to match imaging (only relevant if you've not set up proper sync to daq)
    o.mn.dopop = 0; %compute population features (o.pop below)
    o.mn.dofit = 0; %model fitting (o.mfit below)
    o.mn.dopltx = 1; %plot experiment (o.pltx below)
    o.mn.regionexs = {'tms'};
    o.mroi.dodraw =  {'tms'};
    o.pltx(1).varnms.ts1{1} = {['vis.CON_51.ind1']};
    o.pltx(1).varnms.ts5{1} = {['resp.tms.mo*.imf_f_f_*']}; %if empty, do will be set to false
    o.carl.stimtype = 'drone';
    o.carl.feat = 'CON_51';
    o.carl.pthparent_feat = '~/ds/data/rec';
    o.carl.pth_template = '~/ds/data/stimuli';
end
