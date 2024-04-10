

%%

%purpose of this script is to adjust these params:
%       num_slurm_tasks_on_one_gpu
%       train_datasets_size
%       patch_x
%       patch_y
%       patch_t,
% to meet these requirements/recommendations:
%       overlap_x, y, and t at least 90 (comment in deepcad code says patch overlap should be at least 90 pixels in xyt)
%       total_vram_for_one_slurm_job under 80 GB (assuming simplest paralellization is to use ONE GPU, and assume we use the best/biggest, a100 with 80 GB VRAM)
% for running a single slurm job for denoising


clear all
close all
clc

%do_volume = 1 trains on entire volume at once,
% do_volume = 0 trains on some subset of z slices (which for this script, assumes just one slice at a time, but my code can operate on multiple)
old_project = 0;
do_volume = 1;

single_GPU_VRAM = 80; %using a100

if old_project %not volumetric

    stack_size_x = 256;
    stack_size_y = 128;
    stack_size_t = 4447;
    if do_volume
        stack_size_z = 1;
    else
        stack_size_z = 1;
    end
    volume_rate = 20; %hz

else

    stack_size_x = 140;
    stack_size_y = 256;
    stack_size_t = 4447;
    stack_size_z = 15;
    volume_rate = 5.08; %hz

end

bytes_per_element = 2;  %2 for uint16, which is what i use, but deepcad can operate on float32 and float64 too

if do_volume
    num_slurm_tasks_on_one_gpu = 1; %assuming using 1 GPU with max 80 GB (like the a100), and assuming 15 total stacks running as many in parallel as possible
    numstacks_trained_simultaneously = stack_size_z;
else
    if old_project
        num_slurm_tasks_on_one_gpu = 1; %assuming using 1 GPU with max 80 GB (like the a100), and assuming 15 total stacks, around 5 is the most i can run in parallel while satisfying above
        numstacks_trained_simultaneously = 1; %if do_volume==0
    else
        num_slurm_tasks_on_one_gpu = 1; %assuming using 1 GPU with max 80 GB (like the a100), and assuming 15 total stacks, around 5 is the most i can run in parallel while satisfying above
        numstacks_trained_simultaneously = 1; %if do_volume==0
    end
end

if do_volume %to train on whole volume (not bothering calculating this for numstacks_trained_simultaneously =1)

    if old_project
        train_datasets_size = 13000;
        patch_t_sec = 10; %my personal fairly uneducated guess is that this should be at least 20 sec
        patch_x = 120;
        patch_y = 120;
        patch_t = ceil(patch_t_sec*volume_rate);
        overlap_factor = 0.8; %smaller means more temporal overlap, less spatial (balance point depends on other params)

    else
        train_datasets_size = 26000%26000;
        patch_t_sec = 25; %my personal fairly uneducated guess is that this should be at least 20 sec
        patch_x = 120;
        patch_y = 120;
        patch_t = ceil(patch_t_sec*volume_rate);
        overlap_factor = 0.8; %smaller means more temporal overlap, less spatial (balance point depends on other params)
    end

else


    if old_project
        train_datasets_size = 13000;
        patch_t_sec = 10; %my personal fairly uneducated guess is that this should be at least 20 sec
        patch_x = 120;
        patch_y = 120;
        patch_t = ceil(patch_t_sec*volume_rate);
        overlap_factor = 0.8; %smaller means more temporal overlap, less spatial (balance point depends on other params)

    else
        train_datasets_size = 6000;
        patch_x = 120;
        patch_y = 45;
        patch_t_sec = 20; %my personal fairly uneducated guess is that this should be at least 20 sec
        patch_t = ceil(patch_t_sec*volume_rate);
        overlap_factor = 0.8; %smaller means more temporal overlap, less spatial (balance point depends on other params)
    end

end


gap_x = floor(patch_x * (1 - overlap_factor)) ;
gap_y = floor(patch_y * (1 - overlap_factor)) ;
xnum = floor((stack_size_x - patch_x) / gap_x) + 1;
ynum = floor((stack_size_y - patch_y) / gap_y) + 1;
tnum = ceil(train_datasets_size / xnum / ynum / numstacks_trained_simultaneously);
gap_t = floor((stack_size_t - patch_t * 2) / (tnum - 1));
overlap_x = patch_x*overlap_factor; %should be at least 90
overlap_y = patch_y*overlap_factor; %should be at least 90
overlap_t = patch_t - gap_t; %should be at least 90

total_vram_for_one_slurm_job = patch_x * patch_y * patch_t * bytes_per_element * train_datasets_size * num_slurm_tasks_on_one_gpu / 1e9 ;% should be under 80 for using one a100 in slurm job

["patch overlap should be greater than 90 in each dimension; " + ...
    "patch overlap in x, y, t is : " num2str([overlap_x overlap_y overlap_t])]

["for one slurm job, " + ...
    "on one GPU, " + ...
    "total VRAM should be " + ...
    "a few (?) GB less than " num2str(single_GPU_VRAM)
    " and total VRAM is : " num2str(total_vram_for_one_slurm_job)]

% gap_t
% 
% overlap_t

%%
