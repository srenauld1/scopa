

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

% as of 240610, default approach is to adjust automatically reduce train_dataset_size if necessary (if stack is too small), and run epochs until the std of "unlabeled" brain starts to increase relative to last epoch (model starts to overfit)

clear all
close all
clc

%do_volume = 1 trains on entire volume at once,
% do_volume = 0 trains on some subset of z slices (which for this script, assumes just one slice at a time, but my code can operate on multiple)

%data params
stack_size_x = 256;
stack_size_y = 126;
stack_size_t = 3000;
stack_size_z = 6; %set to 1 if not volumetric
volume_rate = 10; %hz

%deepcad paramsc (adjust if you don't like default)
do_volume = 1; %probably should not adjust
patch_t_sec = 20; %adjust this first; 20 sec is a fairly arbitrary guess
default_patch_xy = 120; %will be reduced to whole fov if fov is smaller than this
train_datasets_size = 3000; %probably don't need to adjust
overlap_factor = 0.8; %probably don't need to adjust; smaller means more temporal overlap, less spatial (balance point depends on other params)
padinc = 5; %pointless i think; could probably be zero

%memory params (recommend to not adjust)
bytes_per_element = 2;  %2 for uint16, which is what i use, but deepcad can operate on float32 and float64 too
num_slurm_tasks_on_one_gpu = 1; %assuming using 1 GPU with max 80 GB (like the a100), and assuming 15 total stacks running as many in parallel as possible
single_GPU_VRAM = 80; %assumes using a100


if do_volume %to train on whole volume (not bothering calculating this for numstacks_trained_simultaneously =1)
    numstacks_trained_simultaneously = stack_size_z;
else
    numstacks_trained_simultaneously = 1; %if do_volume==0
end

if stack_size_x>default_patch_xy+padinc
    patch_x = default_patch_xy;
else
    patch_x = stack_size_x-padinc;
end
if stack_size_y>default_patch_xy+padinc
    patch_y = default_patch_xy;
else
    patch_y = stack_size_y-padinc;
end
patch_t = ceil(patch_t_sec*volume_rate);
patch_t2 = patch_t*2; %use patch_t2 since alternating frames are sent to either end of the Unet, so you actually need double patch size in t)


gap_x = floor(patch_x * (1 - overlap_factor)) ;
gap_y = floor(patch_y * (1 - overlap_factor)) ;
xnum = floor((stack_size_x - patch_x) / gap_x) + 1;
ynum = floor((stack_size_y - patch_y) / gap_y) + 1;

train_datasets_size_adjust = train_datasets_size+1;
gap_t = 0;
while gap_t==0

    train_datasets_size_adjust = train_datasets_size_adjust - 1;

    tnum = ceil(train_datasets_size_adjust / xnum / ynum / numstacks_trained_simultaneously);
    gap_t = floor((stack_size_t - patch_t2) / (tnum - 1)); %patch_t times 2 since input and target are interleaved and both patch_t length in t; THE FLOOR IN THIS LINE CAUSES THE NUMBER OF TRAINING PATCHES TO DIFFER FROM THE NUMBER REQUESTED IN TRAIN_DATASET_SIZE (ie integer shifts attempting to equal TRAIN_DATASET_SIZE, given patch number in x and y)

    numpatch_y = floor((stack_size_y - patch_y + gap_y) / gap_y);
    numpatch_x = floor((stack_size_x - patch_x + gap_x) / gap_x);
    numpatch_t = floor((stack_size_t - patch_t2 + gap_t) / gap_t);
    num_true_patch_total = numpatch_y*numpatch_x*numpatch_t;
    
end

% these are the patch edges in xyzt (use patch_t2 since alternating frames are sent to either end of the Unet)
for z = 1:stack_size_z
    pcount = 0;
    for y = 0:((stack_size_y - patch_y + gap_y) / gap_y)-1
        for x = 0:((stack_size_x - patch_x + gap_x) / gap_x)-1
            for t = 0:((stack_size_t - patch_t2 + gap_t) / gap_t)-1
                pcount = pcount+1;
                init_x(z, pcount) = gap_y * y;
                end_x(z, pcount) = gap_y * y + patch_y;
                init_y(z, pcount) = gap_x * x;
                end_y(z, pcount) = gap_x * x + patch_x;
                init_t(z, pcount) = gap_t * t;
                end_t(z, pcount) = gap_t * t + patch_t2;
            end
        end
    end
end


overlap_x = patch_x*overlap_factor; %should be at least 90
overlap_y = patch_y*overlap_factor; %should be at least 90
overlap_t = patch_t - gap_t; %should be at least 90


total_vram_for_one_slurm_job = patch_x * patch_y * patch_t * bytes_per_element * train_datasets_size * num_slurm_tasks_on_one_gpu / 1e9 ;% should be under 80 for using one a100 in slurm job

sprintf("patch overlap should be greater than 90 in each dimension, if possible; patch overlap in x, y, t is : " + num2str([overlap_x overlap_y overlap_t]))

sprintf("for one slurm job on one GPU, total VRAM should be a few (?) GB less than " + num2str(single_GPU_VRAM) + ...
    " and total VRAM is : " + num2str(total_vram_for_one_slurm_job))

sprintf("gap t is " + num2str(gap_t))

if train_datasets_size_adjust~=train_datasets_size
    sprintf("train_datasets_size had to be adjusted from " + num2str(train_datasets_size) + " to " + num2str(train_datasets_size_adjust))
else
    sprintf("train_datasets_size did not have to be adjusted, it remains " + num2str(train_datasets_size_adjust))
end

sprintf("actual number patches will be: " + num2str(num_true_patch_total) + " for each of " + num2str(numstacks_trained_simultaneously) + " z slices")
%%
