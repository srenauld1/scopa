function [opt, pth, croplim_all, roiparsm, roiparsf, datenum, flynum, trialnum, recid_underscore] = ...
    filenames_scopa(opt, pth_usetmp)

suffix_analysis = opt.main.suffix_analysis;
regionex_all = opt.main.regionex_all;
use_caiman_on_hires = opt.hires.use_caiman_on_hires;
suffixes_plot = opt.vistif.suffixes_plot;
use_hires = opt.mroi.use_hires;
use_drawn_rois = opt.mroi.use_drawn_rois;
numroi_morph_auto = opt.mroi.numroi_morph_auto;
caiman_lr_str = opt.froi.caiman_lr_str;
numcluster_for_bump_domain_resample = opt.bump.numcluster_for_bump_domain_resample;
caiman_hr_str = opt.hires.caiman_hr_str;

[pth_fldr, fn_input, ~] = fileparts(pth_usetmp);
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

    spl = strsplit(regionex_all{i}, '_'); 
    regionex_nohyphen{i} = spl{1}; %anything after an underscore defines a region within the prefix regionex cuboid from python preprocessing 

    pthcroplimall = rdir([pth_fldr recid_underscore '_' regionex_nohyphen{i} '_*_croplim_.*']);

    if isempty(pthcroplimall)
        sprintf("NO CROPLIM FILE FOR REGIONEX: " + regionex_nohyphen{i} + ", YOU WILL BE PROMPTED TO DEFINE CROPLIM ")
        croplim_all{i} = [];
        croplimstr = 'nocroplim';
    elseif length(pthcroplimall)>1
        error(sprintf("ERROR, MULTIPLE CROPLIM FILES FOR REGIONEX: " + regionex_nohyphen{i} + ", CHOOSE THE ONE THAT MATCHES SIZE OF *roi2d_.mat"))
    elseif length(pthcroplimall)==1
        sprintf("FOUND ONE CROPLIM FILE FOR REGIONEX: " + regionex_nohyphen{i})
        [~, fncr, ~] = fileparts(pthcroplimall.name);
        spl = strsplit(fncr, '_');
        insloc = find(strcmp(spl, regionex_nohyphen{i}));
        croplimstr = strjoin(spl(insloc+1:insloc+8), '_');
        croplimtmp = str2double(strsplit(croplimstr, '_'));

        croplim_all{i} = croplimtmp(vec([1:2]'+2*([3 2 4 1]-1)));
    end


    tmpnum = 0;
    if any(strcmp(regionex_all{i}, use_hires))
        tmpnum = 1;
    end
    flag_hires = num2str(tmpnum);
    use_hires_new.(regionex_all{i}) = tmpnum;

    tmpnum = 0;
    if any(strcmp(regionex_all{i}, use_drawn_rois))
        tmpnum = 1;
    end
    flag_use_drawn_rois = num2str(tmpnum);
    use_drawn_rois_new.(regionex_all{i}) = tmpnum;

    tmpnum = 0;
    tmpind = find(~cellfun(@isempty, regexp(numroi_morph_auto, [regionex_all{i} '-\d*'])));
    if tmpind
        tmpnum = sscanf(numroi_morph_auto{tmpind},[regionex_all{i} '-%d']);
    end
    flag_numroi_morph_auto = num2str(tmpnum);
    numroi_morph_auto_new.(regionex_all{i}) = tmpnum;

    paramstr = ['moex_' flag_hires '_' flag_use_drawn_rois '_' flag_numroi_morph_auto];
    roiparsm{i} = paramstr;

    pth_roi_morph{i} = [pth_use_mat(1:end-4) regionex_all{i} '_' croplimstr '_' paramstr '_rois_.mat'];
    pth_roi_allmethods{i}{1} = pth_roi_morph{i};

    pth_caimanfails{i} = [pth_fldr recid_underscore '_*_' regionex_nohyphen{i} '_*_cmex_*_FAILURE_.mat'];
    pth_caimanfails2{i} = [pth_fldr recid_underscore '_*_' regionex_nohyphen{i} '_*_cmex_*_NOROIS_.mat'];

    pth_roi_func_pat = [pth_fldr recid_underscore '_' suffix_analysis '_' regionex_nohyphen{i} '_*_cmex_' caiman_lr_str '_rois_.mat'];
    pthfncrall = rdir(pth_roi_func_pat);
    roiparsf{i} = cell(length(pthfncrall),1);
    pth_roi_func_all{i} = cell(length(pthfncrall),1);
    if ~isempty(pthfncrall) %if caiman file(s) do exist . . .

        pthfncrall = natsortfiles(pthfncrall);

        for ci = 1:length(pthfncrall)
            [~, fncr, ~] = fileparts(pthfncrall(ci).name);
            spl = strsplit(fncr, '_');
            insloc = find(strcmp(spl, regionex_nohyphen{i}));
            croplimstr_check = strjoin(spl(insloc+1:insloc+8), '_');
            if ci>1 & ~strcmp(croplimstr_check, croplimstr_prev)
                error("a regionex has different FOV sizes across extraction runs, should be same across runs")
            end
            croplimstr_prev = croplimstr_check;
            cpatmp = strjoin(spl(find(strcmp(spl, 'cmex')):end-2), '_');
            roiparsf{i}{ci,1} = strrep(cpatmp, '.', 'p');
            pth_roi_func_all{i}{ci,1} = pthfncrall(ci).name;

        end
        pth_roi_allmethods{i} = cat(1, pth_roi_allmethods{i}, pth_roi_func_all{i});
        paramstr = [paramstr '_cmex_' caiman_lr_str];


    end


    tmpnum = 0;
    tmpind = find(~cellfun(@isempty, regexp(numcluster_for_bump_domain_resample, [regionex_all{i} '-\d*'])));
    if tmpind
        tmpnum = sscanf(numcluster_for_bump_domain_resample{tmpind},[regionex_all{i} '-%d']);
    end
    flag_numcluster_for_bump_domain_resample = num2str(tmpnum);
    numcluster_for_bump_domain_resample_new.(regionex_all{i}) = tmpnum;


    paramstr = [paramstr '_' flag_numcluster_for_bump_domain_resample];

    % if use_hires(i)
    %     paramstr = [paramstr '_hr_moex_paramtbd_'];
    %     roiparsm{i} = [roiparsm{i} '_hr_moex_paramtbd'];
    %     if use_caiman_on_hires(i)
    %         paramstr = [paramstr '_hr_cmex_' caiman_hr_str];
    %     end
    % end

    pth_savedata_oneregion{i} = [pth_fldr recid_underscore '_' suffix_analysis '_' paramstr '_' regionex_all{i} '_savedata_.mat'];

end

if ~isempty(regionex_all)
    delete_caiman_fails(pth_caimanfails, pth_fldr, regionex_nohyphen)
    delete_caiman_fails(pth_caimanfails2, pth_fldr, regionex_nohyphen)
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
suffixes_plot = cat(2, setxor(suffix_analysis, suffixes_plot), suffix_analysis); %make suffix_analysis the last one so it can be output from load_stack with minimal memory

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
    pth_roi_func_hires = [pth_hires_prefix 'caiman' caiman_hr_str '_roishires_.mat'];
else
    pth_hires_prefix = [];
    pth_hires_mat_matreg = [];
    pth_roi_func_hires = [];
end

%assign to struct
pth.fldr = pth_fldr;
pth.use_mat = pth_use_mat;
pth.stacks_prefix = pth_stacks_prefix;         
pth.hires_prefix = pth_hires_prefix;
pth.hires_mat_matreg = pth_hires_mat_matreg;
pth.roi_func_hires = pth_roi_func_hires;
pth.metadata = pth_metadata;
pth.roi_morph = pth_roi_morph;
pth.roi_func_all = pth_roi_func_all;
pth.roi_allmethods = pth_roi_allmethods;         
pth.fictrac = pth_fictrac;
pth.savedata_oneregion = pth_savedata_oneregion;

opt.bump.flag_numcluster_for_bump_domain_resample = numcluster_for_bump_domain_resample_new; %update field

opt.mroi.use_drawn_rois = use_drawn_rois_new; %update field
opt.mroi.numroi_morph_auto = numroi_morph_auto_new; %update field
opt.mroi.use_hires = use_hires_new; %update field

opt.vistif.plot_stack_order = plot_stack_order;
opt.vistif.plot_stack_gif = plot_stack_gif;

