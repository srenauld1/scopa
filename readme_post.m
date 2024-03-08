
hires is not processed in python; in matlab it is registered to the registered stack; this seemed simpler 



%a2p.m is the entry point to the 2nd half of the analysis analysis pipeline for volumetric xyzt 2p imaging data with behavior and stimulus
% first part (motion correction, denoising, and source extraction) is in python, entry point pipeline_init.py:

%%a2p.m loads output files from python pipeline,
%%if high-z-res stack exists, it can be used to aid with morphological identification
% register it in 3d (here in matlab) to caiman-registered functional stack
%%(didn't see the point of registering it in python/caiman)

%%for each regionex, draw 2d mask
%%3d mask is automatically extracted (using hi-z-res stack if it exists, otherwise just the lo-z-res)
%%use 3d mask to define morphological rois, which can optionally be used in response quantification
%%normalize responses
%%map functional rois to mophological rois, if desired
%%written to cycle through all source extraction files (different params) and cycle through all normalization methods, and compare all of them
%%since it can be hard to intuit the optimal settings

% Hi-z-res stack is only useful for mapping multiple morphological ROIs
% Because hires can help increase z res in the interior of the region if functional ROIs span multiple lo res planes (def flawed though)
% But won't help at the region exterior since you don't know where lores roi ends

% rois can be morphological or functional
%morphological rois are clustered
%functional rois are clustered
%some

%note remove_scan_noise should ideally only occur prior to
%caiman roi extraction, but this pipeline allows the user to run remove_scan_noise afterwards 
% (need to fix this so the user has the option to use nosn suffix stack for roi extraction)

% rval documentation The algorithm also measures the reliability of the spatial mask by comparing the filters in A
%      with the average of the movies over samples where exceptional events happen, after  removing (if possible)
%     frames when neighboring neurons were active

%%g4 frame 0 (in vis.raw) assigned to angle -pi (in vis.ang)

