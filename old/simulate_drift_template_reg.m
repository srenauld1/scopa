
%this demo does not accurately recreate normcorre templates;  

clear all
close all
clc

dopp = [7];
iz = 5;

fnstack = '/Users/wienecke/stacks/20241008-3_MBON09_no_jump/oldrawnofb.mat';
[expDir, cfn] = fileparts(fnstack);

glb(pthstackdir = [expDir '/'])

iz = 5; %z index

load(fnstack, 'imgData');

currData = squeeze(imgData(:,:, iz, :)); % --> [y, x, volume]

options_rigid = NoRMCorreSetParms( ...
    'd1', size(currData, 1), ...
    'd2', size(currData, 2), ...
    'grid_size', [], ... %empty is 2d rigid registration, where grid size is automatically set to [d1 d2 1]
    'max_shift', [25, 25], ... %max rigid shift yx
    'init_batch', 100, ... %length of initial batch
    'upd_template', true, ... %default true,
    'us_fac', 50, ... %default 50,
    'phase_flag', 0, ... %default false,...
    'shifts_method', 'FFT', ... %default fft,...
    'correct_bidir', true ... %default true,...
    );

d1=size(currData, 1);
d2=size(currData, 2);
numpixdrift = 70;
shiftfac = size(currData,3)/numpixdrift;
numbatch = 10;
bidishift = 0; %whether to force a bidi shift
% bgprctile = .001; %percentile estimate of background
srt = sort(currData(:));
bglb = 0; %single(min(currData(:)));
bgub = 5; %single(srt(10)); %single(prctile(single(currData(:)), bgprctile));
batchwid = floor(size(currData,3)/numbatch);
stackshifted = zeros(size(currData), class(currData));
shf = zeros(size(currData,3),1);
for h = 1:size(currData,3)
    shf(h) = ceil(h/shiftfac);
    tmp = circshift(currData(:,:,h), shf(h), 1); %shift y
    if bidishift %also simulate bidi shift for fun
        for w = 1:2:d1
            tmp(w,:) = circshift(tmp(w,:), bidishift, 2);
            rndpad = randi(bgub-bglb,1,bidishift)+bglb; %simulate a background to insert in the wraparound where bidiphase has been artificially introduced with circshift
            stackshifted(w,:,h) = [rndpad tmp(w,bidishift+1:end)];
        end
    else
        stackshifted(:,:,h) = tmp;
    end
end
buffer_med = []; %don't preallocate, it needs to grow in loop
tempall = zeros(size(currData,1),size(currData,2),numbatch);
for w = 1:numbatch %this loop simulates when upd_template==true in normcorre_batch
    grp = [1:batchwid]+330*(w-1);
    buffer = mat2cell_ov(single(stackshifted(:,:,grp)),1,d1,1,d2,1,1,options_rigid.overlap_pre,[d1 d2]); %mat2cell_ov and cell2mat_ov do nothing when grid_size is default/empty (ie rigid registration)
    new_temp = cellfun(@(x) nanmean(x,ndims(stackshifted)), buffer, 'UniformOutput',false);
    buffer_med(:,:,w) = cell2mat_ov(new_temp, 1, d1, 1, d2, 1, 1, options_rigid.overlap_pre, [d1 d2]); %mat2cell_ov and cell2mat_ov do nothing when grid_size is default/empty (ie rigid registration)
    template = mat2cell_ov(nanmedian(buffer_med,ndims(stackshifted)),1,d1,1,d2,1,1,options_rigid.overlap_pre,[d1 d2]); %mat2cell_ov and cell2mat_ov do nothing when grid_size is default/empty (ie rigid registration)
    temp_mat = cell2mat_ov(template,1,d1,1,d2,1,1,options_rigid.overlap_pre,[d1 d2]); %mat2cell_ov and cell2mat_ov do nothing when grid_size is default/empty (ie rigid registration)
    tempall(:,:,w) = temp_mat;
end
stackplt(tempall, title_prefix='template for drifting brain')

