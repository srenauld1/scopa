function [md, stim] = load_stim(md, ids, no_stim_epochs, doplots)

datenum = ids.datenum;
flynum = ids.flynum;
trialnum = ids.trialnum;

recid = [num2str(datenum) num2str(flynum)];

plot_stim = 0;

pth_fldr_stim = '~/Documents/DS_Final/lib/data/stimuli/';
fldr_stim = [recid ',20221128T132937_1,n72,0,1,1,0,1,s_rois53'];

stimtype = 'drone';
stimfeat_primary = 51;
stimfeat_secondary = 51;
fn_stim_pattern = [stimtype '_' num2str(trialnum) '_1_CON_' num2str(stimfeat_primary) '_336_6000_.mat'];

pth_fldr_template = '~/Documents/ambrose/motionDetector/stimuli/';
fn_template = 'TwoNoise_2048_4096_1_8_20221019T060004_.bin';
fn_template_inds = [fn_template(1:end-4) '*_hexind2_.mat'];

ncol = 256; %number colors in image
screen_size = 's';
phimx = 0.769961614088224; %image max phi
fn_vertices = 'vertices_8000_0.txt';

fnall_fldr_stim = rdir([pth_fldr_stim fldr_stim '/' fn_stim_pattern]);
fnall_fldr_stim = natsortfiles(fnall_fldr_stim);

for dfni = 1:length(fnall_fldr_stim)

    pth_tmp = fnall_fldr_stim(dfni).name;
    [pth_fldr_tmp, fn_tmp, ext_tmp] = fileparts(pth_tmp);

    %swap feat index in primary feat file to get secondary feat file
    spl = strsplit(fn_tmp, '_');
    spl{5} = num2str(stimfeat_secondary);
    fn_synth_feat_secondary = strjoin(spl, '_');
    pth_feat_secondary = [pth_fldr_tmp '/' fn_synth_feat_secondary ext_tmp];

    load(pth_tmp, 'stimulus')
    %load(pth_feat_secondary, 'stimulus')

    if plot_stim

        if size(stimulus, 2)>50
            tindz = round(linspace(1, size(stimulus, 2), 50));
        else
            tindz = 1:size(stimulus, 2);
        end

        fn_gif_teststim = ['~/Documents/ambrose/filtergifs/' datestr(now,30) '_stim_.gif'];

        dogmodel_plot(stimulus(:,tindz), fn_gif_teststim, phimx, ncol)

    end
end

vis.raw = stimulus;
ball = [];

md.t_ts_b = [];

md.dtmni = 1/md.volrate;
md.t_ts_i = md.dtmni * [1:size(vis.raw, 2)];
md.total_t = max(md.t_ts_i);
md.smoothwindow_i = md.smoothwindow_sec/mean(diff(md.t_ts_i));

if no_stim_epochs
    md.epochinds_ts_i = ones(length(md.t_ts_i), 1);
    md.epochinds_ts_b = [];
end

stim.vis = vis;
stim.ball = ball;
