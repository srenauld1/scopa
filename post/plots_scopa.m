
function plots_scopa(filename_sd)

error("plots_scopa is deprecated")

%% set params

%define cue epoch boundaries
splits = 60:20:500;
splits2 = [splits(1:2:end); splits(1:2:end)+20]'; %epoch boundaries
openinds = [];
for si = 1:size(splits2,1)
    openinds = [openinds splits2(si,1):splits2(si,2)];
end
closedinds = openinds+20;

alp = [0.7 0.7 0.7]; %epoch shading color

[pth_save_prefix, fn_save, ~] = fileparts(filename_sd{1});
spl = strsplit(fn_save, '_');
pth_save = [pth_save_prefix '/' strjoin(spl(1:end-3), '_') '_.mat']; %remove the region ID since multiple regions are in same plot

%% load each region's savedata


%normalization params are separated by underscores:
% in_input normlization_pc_precluster normalization_cl_cluster normalization_w_weighting

%put pb last for now
region_choose = {'gar', 'gal', 'no_r', 'no_l', 'pb'};
region_choose = {'pb'};

for rci = 1:length(region_choose)

    region_choose{rci} 

    regionidx = find(~cellfun(@isempty, (regexp(filename_sd, ['_' region_choose{rci} '_'])))); %pb savedata will organize the rest
    load(filename_sd{regionidx})

    if ~strcmp(region_choose{rci}, 'pb')

        if strcmp(region_choose{rci}, 'pb')
            ex_manual = {'3_*_*_*_*_*_*_*_1000_graph_3dex'};
            norm_manual = {'in_*_pc_*_cl_*_w_*'};
        else
            ex_manual = {'3_1_0.7_*_*_1_1_10_1000_graph_3dex'};
            norm_manual = {'in_cmc_pc_null_cl_null_w_yes'};
        end


        [resp_tmp, params_all_tmp, params_all_tmp_bad] = index_into_extraction_and_normalization_params(pars_all, resp, ex_manual, norm_manual);

        resp_tmp = squeeze(resp_tmp);
        % exparams_unique_tmp = unique(params_all_tmp(:,1), 'stable');
        % normparams_unique_tmp = unique(params_all_tmp(:,3), 'stable');

        % filenameGIF = [filename_sd{regionidx}(1:end-4) 'respsynshort4_.gif'];
        % plot_data(squeeze(resp_tmp(:,1,1:500)), 'resp', params_all_tmp, filenameGIF, [], [], 0, 0)
        %
        % clear resp_tmp_new
        % idx = find(strcmp(params_all_tmp(:,1), '3_1_0.7_15_None_1_1_10_1000_graph_3dex') & strcmp(params_all_tmp(:,3), 'in_cmc_pc_null_cl_null_w_yes'));
        % resp_tmp_new(1,:) = resp_tmp(idx,:);
        % idx = find(strcmp(params_all_tmp(:,1), '3_1_0.7_15_None_1_1_10_1000_graph_3dex') & strcmp(params_all_tmp(:,3), 'in_cmdff_pc_null_cl_null_w_yes'));
        % resp_tmp_new(end+1,:) = resp_tmp(idx,:);
        % idx = find(strcmp(params_all_tmp(:,1), 'morphological') & strcmp(params_all_tmp(:,3), 'in_rawf_pc_null_cl_null_w_no'));
        % resp_tmp_new(end+1,:) = resp_tmp(idx,:);
        % figure; hold on;indies = 1:500; plot(resp_tmp_new(1, indies));
        % yyaxis right; plot(resp_tmp_new(2, indies));
        % figure; hold on;indies = 1:500; plot(resp_tmp_new(1, indies));
        % yyaxis right; plot(resp_tmp_new(3, indies));
        %
        % filenameGIF = [filename_sd{regionidx}(1:end-4) 'respsynshort4_.gif'];
        % plot_data(resp_tmp(1:50,1:500), 'resp', params_all_tmp, filenameGIF)

        if strcmp(region_choose{rci}, 'gar')
            resp_gar = resp_tmp;
            params_all_gar = params_all_tmp;
        elseif strcmp(region_choose{rci}, 'gal')
            resp_gal = resp_tmp;
            params_all_gal = params_all_tmp;
        elseif strcmp(region_choose{rci}, 'no_r')
            resp_nor = resp_tmp;
            params_all_nor = params_all_tmp;
        elseif strcmp(region_choose{rci}, 'no_l')
            resp_nol = resp_tmp;
            params_all_nol = params_all_tmp;
        end


    end
end


%% define ball and metadata params (same for all region_extraction)

f_vel = ball.f_vel;
r_vel = ball.r_vel;
f_speed = ball.f_speed;
r_speed = ball.r_speed;
ti = md.ti;
tb = md.tb;
smooth_iter = md.smooth_iter;
smoothfac_i = md.smoothfac_i;
smoothfac_b = md.smoothfac_b;
num_panel_frames = md.num_panel_frames;


%% find subset indices using mu-cue offset

[~, err_std] = compute_bump_error(offset);
%[~, err_cum_sorted] = sort(err_cum);
[~, err_std_sorted] = sort(err_std);

%% 

totalnumruns = size(pars_all, 1);
numeachseg = 100;
%subsetinds = [1:numeachseg, round(totalnumruns/2):round(totalnumruns/2)+numeachseg, totalnumruns-numeachseg:totalnumruns]; top, middle, bottom
subsetinds = 1:numeachseg;
if length(subsetinds)>totalnumruns
    subsetinds = 1:totalnumruns;
end

extra_smooth_fac = 1;

err_sorting_method = 'manual';

switch err_sorting_method
    case 'manual'
        ex_manual = {'*'};
        norm_manual = {'in_*_pc_null_cl_null_w_*'};

        [resp_tmp, params_all_tmp, params_all_tmp_bad, idx_manual] = index_into_extraction_and_normalization_params(pars_all, resp, ex_manual, norm_manual);

        subsetinds = idx_manual;
        err_sorting = 1:length(err_std_sorted); %undo sorting for manual
    case 'cum'
        err_sorting = err_cum_sorted;
    case 'std'
        err_sorting = err_std_sorted;
end

err_sorting = err_sorting(subsetinds);

%%loop through all analysis methods in order defined above, and plot

offset_new = zeros(length(err_sorting), length(cue));
offset_err_cum_new = zeros(length(err_sorting), length(cue));
offset_err_cum_end_new = zeros(length(err_sorting));
countz = 0;
for ci = 1:length(err_sorting)

    countz = countz+1;

    caiman_params_selected = pars_all{err_sorting(ci), 1};
    caiman_ind_selected = pars_all{err_sorting(ci), 2};
    norm_params_selected = pars_all{err_sorting(ci), 3};
    norm_ind_selected = pars_all{err_sorting(ci), 4};

    dff_pb = resp{caiman_ind_selected}.(norm_params_selected);
    mu = bump{caiman_ind_selected}.([norm_params_selected '_mu']);
    rho = bump{caiman_ind_selected}.([norm_params_selected '_rho']);
    amp_pb = bump{caiman_ind_selected}.([norm_params_selected '_amppb']);
    amp_mu = bump{caiman_ind_selected}.([norm_params_selected '_ampmu']);
    amp_peak = bump{caiman_ind_selected}.([norm_params_selected '_amppeak']);
    domain = bump{caiman_ind_selected}.domain;


    if ~exist('resp_gar', 'var')
        dff_gall = zeros(size(amp_pb));
        dff_no = zeros(size(amp_pb));
    else
        % dff_gall = mean([resp_gar resp_gal], 2);
        % dff_no = mean([resp_nor resp_nor], 2);
        dff_gall = resp_gar;
        dff_no = resp_nor;
    end

    %%%%%%%%%%%%%%%%%%smooth imaging and fictrac data, and interp imaging onto fictrac%%%%%%%%%%%%%%%

    mu = unwrap(mu); %unwrap to perform circular smoothing. keeps radians continuous, so that smoothing 0 and 2pi doesnt go to 1pi
    intHD = unwrap(ball.intHD);
    cue_new = unwrap(cue / num_panel_frames * 2*pi - pi);

    for i = 1:smooth_iter*extra_smooth_fac %smooth fictrac data n times, since fictrac is super noisy.
        mu = smoothdata(mu,'gaussian',smoothfac_i); %smooth all bump parameters.
        rho = smoothdata(rho,'gaussian',smoothfac_i);
        dff_no = smoothdata(dff_no,'gaussian',smoothfac_i);
        dff_gall = smoothdata(dff_gall,'gaussian',smoothfac_i);
        amp_pb = smoothdata(amp_pb,'gaussian',smoothfac_i);
        amp_mu = smoothdata(amp_mu,'gaussian',smoothfac_i);
        amp_peak = smoothdata(amp_peak,'gaussian',smoothfac_i);
        f_vel = smoothdata(f_vel,'gaussian',smoothfac_b);
        f_speed = smoothdata(f_speed,'gaussian',smoothfac_b);
        r_vel = smoothdata(r_vel,'gaussian',smoothfac_b);
        r_speed = smoothdata(r_speed,'gaussian',smoothfac_b);
        intHD = smoothdata(intHD,'gaussian',smoothfac_b);
        cue_new = smoothdata(cue_new,'gaussian',smoothfac_b);
    end

    mu = interp1(ti,mu,tb)';
    rho = interp1(ti,rho,tb)';
    amp_pb = interp1(ti,amp_pb,tb)';
    amp_mu = interp1(ti,amp_mu,tb)';
    amp_peak = interp1(ti,amp_peak,tb)';
    dff_no = interp1(ti,dff_no,tb)';
    dff_gall = interp1(ti,dff_gall,tb)';

    "I THINK THE RE WRAPPIUNG IS OFF BY ONE - 2PI APPEARS TWICE AS ZERO AND 2PI"
    mu = mod(mu,2*pi); %rewrap heading data, and put between -pi and pi.
    mu(mu > pi) = mu(mu > pi) - 2*pi;
    intHD = mod(intHD,2*pi);
    intHD(intHD > pi) = intHD(intHD > pi) - 2*pi;
    cue_new = mod(cue_new,2*pi);
    cue_new(cue_new > pi) = cue_new(cue_new > pi) - 2*pi;

    %%%%%%%%%%%%%%plot each amplitude type%%%%%%%%%%%%%%

    stradd2 = {'ampMU', 'ampPB', 'ampPEAK'}; %amplitude types
    stradd2 = {'ampPB'};
    dff_gall = rescale(dff_gall);
    dff_no = rescale(dff_no);
    amp_mu = rescale(amp_mu);

    for sai = 1:length(stradd2)
        stradd = ['ind' num2str(err_sorting(ci)) '_' caiman_params_selected '_norm_' norm_params_selected '_' stradd2{sai} '_'];
        plot_full_experiment(cue_new, mu, intHD, ...
            amp_mu, dff_gall, dff_no, tb, splits2, openinds, closedinds, alp, stradd, pth_save)
        %close all
    end


end

%
% filenameGIF_offset = [filename_sd_full(1:end-4) 'respsyn_.gif'];
%
% plot_data(offset, 'resp', fieldsall, filenameGIF_offset)
%
% rho_idx = rho>0;
%
% % % % for ti = 1:size(offset, 1)
% % % %     a = plot(tb(rho_idx),offset{ti}(rho_idx),'k','linewidth',0.5);
% % % %     a.YData(abs(diff(a.YData))>pi) = nan; %get rid of lines that connect top and bottom
% % % %     ylabel('Offset')
% % % %     yticks([-pi,0,pi]); yticklabels({'-\pi','0','\pi'})
% end


end