
clear all
close all
clc

%scatterplots_toy

%%

gifvis = 'on';
pth_allrec = '~/~/ambrose/allrec/morphmaskno/';
pth_allrec = '~/~/ambrose/allrec/trans2/';
epochindstmp = {[1 2 3 4 5]; [1 4]; [2 3]; [1]; [2]; [3]; [4]; [5]};
epochindstmp = {[5]; [4]; [3]; [2]; [1]};
% epochindstmp = {[1 4]};
%
% fn_all_bad = rdir([pth_allrec 'bad/*gif']);
% for fi = 1:length(fn_all_bad)
%     spl = strsplit(fn_all_bad(fi).name, '/');
%     recid_bad{fi} = strsplit(spl{end}, '_');
%     recid_bad{fi} = strjoin(recid_bad{fi}(1:3), '_');
% end
recid_bad = {'20230609_3_1' ,   '20230610_3_2' ,   '20230613_1_1'  ,  '20230627_3_1'};

epochstring = regexprep( mat2str(epochindstmp{1}), {'\[', '\]', '\s+'}, {'', '', '-'});
fn_sd_all = rdir([pth_allrec '*_' epochstring '_scatter4*.mat']);
numrecordings = length(fn_sd_all);

for epi = 1:length(epochindstmp)

    epochindstmp2 = epochindstmp{epi};
    epochstring = regexprep( mat2str(epochindstmp2), {'\[', '\]', '\s+'}, {'', '', '-'});

    %fn_sd_all = rdir([pth_allrec '2023*/*' num2str(epochnum{epi}) '_scatter3data.mat']);
    fn_sd_all = rdir([pth_allrec '*_' epochstring '_scatter4*.mat']);
    if length(fn_sd_all)~=numrecordings
        error
    end
    ampmean_all = [];
    amppeak_all = [];
    ampmu_all = [];
    respgal_all = [];
    respgar_all = [];
    respnol_all = [];
    respnor_all = [];
    meang_all = [];
    meann_all = [];
    bumpmu_all = [];
    bumpvel_all = [];
    bumprho_all = [];
    cueang_all = [];
    cuevel_all = [];
    ballang_all = [];
    ballvel_all = [];
    for fi = 1:length(fn_sd_all)
        spl = strsplit(fn_sd_all(fi).name, '/');
        recid = strsplit(spl{end}, '_');
        recid = strjoin(recid(1:3), '_');
        if ismember(recid, recid_bad)
            ["skipping bad recording " recid ]
        else
            load(fn_sd_all(fi).name)

            %%

            difwin = 1;
            nanmu = remove_circular_wrapping_lines(bumpmu, difwin);
            nancue = remove_circular_wrapping_lines(cueang, difwin);
            nanoff = circ_dist_nan(nancue, nanmu);
            nanoff = remove_circular_wrapping_lines(nanoff, 1);
            %
            % figure;
            % numseg = 1;
            % for nmi = 1:numseg
            %     indiest = [1:floor(length(nanmu)/numseg)] + floor(length(nanmu)/numseg)*(nmi-1);
            %     indiest = 1:800;
            %     subplot(numseg,1,nmi)
            %     plot((nanmu(indiest)));
            %     hold on;
            %     plot((nancue(indiest)));
            % end
            %%


            ampmean_all = cat(1, ampmean_all, vec(ampmean));
            amppeak_all = cat(1, amppeak_all, vec(amppeak));
            ampmu_all = cat(1, ampmu_all, vec(ampmu));
            respgal_all = cat(1, respgal_all, vec(respgal));
            respgar_all = cat(1, respgar_all, vec(respgar));
            respnol_all = cat(1, respnol_all, vec(respnol));
            respnor_all = cat(1, respnor_all, vec(respnor));
            meang_all = cat(1, meang_all, vec(meang));
            meann_all = cat(1, meann_all, vec(meann));
            bumpmu_all = cat(1, bumpmu_all, vec(bumpmu));
            bumprho_all = cat(1, bumprho_all, vec(bumprho));
            bumpvel_all = cat(1, bumpvel_all, vec(bumpvel));
            cueang_all = cat(1, cueang_all, vec(cueang));
            cuevel_all = cat(1, cuevel_all, vec(cuevel));
            ballang_all = cat(1, ballang_all, vec(ballang));
            ballvel_all = cat(1, ballvel_all, vec(ballvel));
        end
    end
    fn_prefix = [pth_allrec 'allrec'];
    if ~isdir(fn_prefix)
        mkdir(fn_prefix)
    end
    if epochnum~=epochindstmp2
        error
    end

    colorvars = {'respnol'};
    % colorvars = {''};
    manualvars = {'bumpvel', 'ballvel'};
    % manualvars = {''};

    do3d = 0;
    %%

    difwin = 1;
    nanmu = remove_circular_wrapping_lines(bumpmu_all, difwin);
    nancue = remove_circular_wrapping_lines(cueang_all, difwin);
    nanoff = circ_dist_nan(nancue, nanmu);
    nanoff = remove_circular_wrapping_lines(nanoff, 1);
    %
    %     figure;
    %     numseg = 20;
    %     for nmi = 1:numseg
    %         indiest = [1:floor(length(nanmu)/numseg)] + floor(length(nanmu)/numseg)*(nmi-1);
    %         subplot(numseg,1,nmi)
    %         plot((nanmu(indiest)));
    %         hold on;
    %         plot((nancue(indiest)));
    %         ylim([-2*pi 2*pi])
    %         % subplot(2,1,2)
    %         % plot(nanoff(indiest));
    %         % yline(0)
    %     end
    %     figure; hist(nanoff)
    % close
    %%

    scatterplots_2d(cueang_all, cuevel_all, ballang_all, ballvel_all, ...
        bumpmu_all, bumprho_all, bumpvel_all, ampmean_all, amppeak_all, ampmu_all, ...
        respgar_all, respgal_all, respnor_all, respnol_all, meang_all, meann_all, ...
        do3d, colorvars, manualvars, md, epochnum, epochstring, fn_prefix, gifvis)

end
