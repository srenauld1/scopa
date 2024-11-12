
% params for carl's old project; not set if you're not carl (if you don't have a recording folder with substring 'f91g_syt')

o = odf(o, {'carl', 'hires.sld.sp'}, files=2); %files=2 to not change anything in subfield id

if 0%dofindfiles && all(contains(getfieldns([o.id],'pth'), 'f91g_syt')) %override some options for carl's old project (files contain substring f91g_syt)
    if numel(o)>1
        error("right now old project is one file at a time")
    end
    o.mn.oldcarl = 1;
    o.sld.tcrop = [4, 2]; % how many samples to remove from [start, end] of stack; similar to cropdata in rec6 (also applied in metrics2 without variable name cropdata), crop first 4 and last 2 imaging frames (stimulus features, and deprecated responses, have been extracted with this cropping in rec6)
    o.mfit.mdl_lag_sec = 1; %how many samples indv precedes depv for model fit . . . for now, only nonnegative integers (0 to lenfit_samp - 1)
    o.mfit.mdl_length_sec = 1.25;
    o.mn.dodaq = 0; %process daq data
    o.mn.doftv = 0; %temporal resample fictrac video to match imaging (only relevant if you've not set up proper sync to daq)
    o.mn.dopop = 0; %compute population features (o.pop below)
    o.mn.dofit = 0; %model fitting (o.mfit below)
    o.mn.dopltx = 1; %plot experiment (o.pltx below)
    o.mn.regionex = {'tms'};
    o.roi.dodraw =  {'tms'};
    o.pltx(1).vnm.ts1{1} = {['vis.CON_51.ind1']};
    o.pltx(1).vnm.ts5{1} = {['resp.tms.mo*.imf_f_f_*']}; %if empty, do will be set to false
    o.carl.stimtype = 'drone';
    o.carl.feat = 'CON_51';
end
