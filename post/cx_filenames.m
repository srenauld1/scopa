function [pth_fldr, pth_use_mat, pth_stacks_prefix, ...
    pth_hires_prefix, pth_hires_mat_matreg, pth_caimanrois_hires, ...
    pth_metadata, pth_roi_morph, pth_roi_func_all, pth_roi_allmethods, ...
    pth_fictrac, pth_savedata_oneregion, ...
    cropdims_all, roiparsm, roiparsf, ...
    plot_stack_order, plot_stack_gif, datenum, flynum, trialnum, recid_underscore] = ...
    cx_filenames(pth_input, suffixes_plot, suffix_analysis, use_hires, numroi_morph, numroi_func, ...
    use_caiman_on_hires, caiman_lr_str, caiman_hr_str, ...
    regionex_all)


[pth_fldr, fn_input, ~] = fileparts(pth_input);
pth_fldr = [pth_fldr filesep];
spl = strjoin(strsplit(fn_input, '-'), '_'); %if there's a hyphen, separate and then join all with underscore
spl = strsplit(spl, '_'); %then separate by underscore

datenum = str2double(spl{1});
flynum = str2double(spl{2});
trialnum = str2double(spl{3});    % trialnum = str2double(spl(find(strcmp(spl, 'trial'))+1));

recid_hyphen = [num2str(datenum) '-' num2str(flynum)];
recid_underscore = [num2str(datenum) '_' num2str(flynum) '_' num2str(trialnum)];

pth_use_mat = [pth_fldr recid_underscore '_' suffix_analysis '_.mat'];

pth_metadata = [pth_fldr recid_underscore '_metadatanew_.mat'];

pth_fictrac = [pth_fldr recid_hyphen '_ficTracData_DAQ.mat'];


for i = 1:length(regionex_all)

    spl = strsplit(regionex_all{i}, '_'); %if there's an underscore, separate
    regionex_original = spl{1};

    pthcroplimall = rdir([pth_fldr recid_underscore '_' regionex_original '*_croplim_.*']);
    try
        [~, fncr, ~] = fileparts(pthcroplimall.name);
        spl = strsplit(fncr, '_');
        cropdims_all{i} = [str2double(spl(9)), str2double(spl(10)), str2double(spl(7)), str2double(spl(8)), str2double(spl(11)), str2double(spl(12)), str2double(spl(5)), str2double(spl(6))];
        cropdims_str = [spl{5} '_' spl{6} '_' spl{7} '_' spl{8} '_' spl{9} '_' spl{10} '_' spl{11} '_' spl{12}];
    catch
        cropdims_all{i} = [];
        cropdims_str = 'nocropdims';
    end

    paramstr = ['moex_' num2str(use_hires(i)) '_' num2str(numroi_morph(i))];
    roiparsm{i} = paramstr;

    pth_roi_morph{i} = [pth_use_mat(1:end-4) regionex_all{i} '_' cropdims_str '_' paramstr '_rois_.mat'];
    pth_roi_allmethods{i}{1} = pth_roi_morph{i};

    pth_caimanfails{i} = [pth_fldr recid_underscore '_*_' regionex_all{i} '_*_cmex_*_FAILURE_.mat'];
    pth_caimanfails2{i} = [pth_fldr recid_underscore '_*_' regionex_all{i} '_*_cmex_*_NOROIS_.mat'];

    pth_roi_func_pat = [pth_fldr recid_underscore '_' suffix_analysis '_' regionex_original '_*_cmex_' caiman_lr_str '_rois_.mat'];
    pthfncrall = rdir(pth_roi_func_pat);
    roiparsf{i} = cell(length(pthfncrall),1);
    pth_roi_func_all{i} = cell(length(pthfncrall),1);
    if ~isempty(pthfncrall) %if caiman file(s) do exist . . .

        pthfncrall = natsortfiles(pthfncrall);

        for ci = 1:length(pthfncrall)
            [~, fncr, ~] = fileparts(pthfncrall(ci).name);
            spl = strsplit(fncr, '_');
            insloc = find(strcmp(spl, regionex_original));
            cropdimstr_check = strjoin(spl(insloc+1:insloc+8), '_');
            if ci>1 & ~strcmp(cropdimstr_check, cropdimstr_prev)
                error("a regionex has different FOV sizes across extraction runs, should be same across runs")
            end
            cropdimstr_prev = cropdimstr_check;
            cpatmp = strjoin(spl(find(strcmp(spl, 'cmex')):end-2), '_');
            roiparsf{i}{ci,1} = strrep(cpatmp, '.', 'p');
            pth_roi_func_all{i}{ci,1} = pthfncrall(ci).name;

        end
        pth_roi_allmethods{i} = cat(1, pth_roi_allmethods{i}, pth_roi_func_all{i});
        paramstr = [paramstr '_cmex_' caiman_lr_str];


    end

    
    paramstr = [paramstr '_' num2str(numroi_func(i))];

    % if use_hires(i)
    %     paramstr = [paramstr '_hr_moex_paramtbd_'];
    %     roiparsm{i} = [roiparsm{i} '_hr_moex_paramtbd'];
    %     if use_caiman_on_hires(i)
    %         paramstr = [paramstr '_hr_cmex_' caiman_hr_str];
    %     end
    % end

    pth_savedata_oneregion{i} = [pth_fldr recid_underscore '_' suffix_analysis '_' paramstr '_' regionex_all{i} '_savedata_.mat'];


end


uhrstr = sprintf('%.0f,' , use_hires);
uhrstr = uhrstr(1:end-1);
nrmstr = sprintf('%.0f,' , numroi_morph);
nrmstr = nrmstr(1:end-1);
nrfstr = sprintf('%.0f,' , numroi_func);
nrfstr = nrfstr(1:end-1);

if ~isempty(regionex_all)
    pth_savedata_allregions = [pth_fldr recid_underscore '_' suffix_analysis '_' paramstr '_' uhrstr '_' nrmstr '_' nrfstr '_' strjoin(regionex_all, ',') '_savedata_.mat'];
    cx_delete_caiman_fails(pth_caimanfails, pth_fldr, regionex_all)
    cx_delete_caiman_fails(pth_caimanfails2, pth_fldr, regionex_all)
else
    pth_savedata_allregions = [pth_fldr recid_underscore '_' suffix_analysis '_FIXTHISFILENAME_savedata_.mat'];
    pth_savedata_oneregion = [pth_fldr recid_underscore '_' suffix_analysis '_FIXTHISFILENAME_savedata_.mat'];
    pth_roi_morph = '';
    pth_roi_func_all = '';
    pth_roi_allmethods = '';
    cropdims_all = [];
    roiparsm = {};
    roiparsf = {};
end


if isempty(suffixes_plot)
    plot_stack_gif = 0;
else
    plot_stack_gif = 1;
end

if ~ismember(suffix_analysis, suffixes_plot)
    "suffixes_plot DOES NOT CONTAIN suffix_analysis, ADDING IT TO suffixes_plot NOW"
    suffixes_plot{end+1} = suffix_analysis;
end
suffixes_plot = unique(suffixes_plot, 'stable'); %make sure there aren't accidental repeats
suffixes_plot = cat(2, setxor(suffix_analysis, suffixes_plot), suffix_analysis); %make suffix_analysis the last one so it can be output from cx_vis_tif with minimal memory

[~, plot_stack_order] = sort(cellfun(@length, suffixes_plot)); %default plot order is shortest to longest suffix (least to most processed, since additional suffixes are added at each stage)


pth_stacks_prefix = cell(length(suffixes_plot), 1);
for spi = 1:length(suffixes_plot)

    pthpat = [pth_fldr recid_underscore '_' suffixes_plot{spi} '_.tif'];
    pth_tmp = rdir(pthpat);
    if isempty(pth_tmp)
        pthpat = [pthpat(1:end-4) '.mat'];
        pth_tmp = rdir(pthpat);
    end

    if ~isempty(pth_tmp)
        pth_stacks_prefix{spi} = pth_tmp.name(1:end-4);
    else

        sprintf(['WARNING, NEITHER TIF NOR MAT FOUND FOR' newline pthpat(1:end-4) newline 'SKIPPING IT FOR PLOT'])

    end


end


pthpat = [pth_fldr recid_underscore  '_hires_.tif'];
pth_tmp = rdir(pthpat);
if isempty(pth_tmp)
    pthpat = [pthpat(1:end-4) '.mat'];
    pth_tmp = rdir(pthpat);
    if isempty(pth_tmp)
        pthpat = [pth_fldr num2str(datenum) '_' num2str(flynum) '_hires_.tif']; %sometimes hires has no trial in filename (one hires for all trials)
        pth_tmp = rdir(pthpat);
        if isempty(pth_tmp)
            pthpat = [pthpat(1:end-4) '.mat'];
            pth_tmp = rdir(pthpat);
        end
    end
end
if ~isempty(pth_tmp)
    pth_hires_prefix = pth_tmp.name(1:end-4);
    pth_hires_mat_matreg = [pth_hires_prefix 'hires_matreg_.mat'];
    pth_caimanrois_hires = [pth_hires_prefix 'caiman' caiman_hr_str '_roishires_.mat'];
else
    pth_hires_prefix = [];
    pth_hires_mat_matreg = [];
    pth_caimanrois_hires = [];
end

