#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in bash
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--index_extraction_param_set 'default' \
--region_extraction 'pre' 'post' \
--do_background_subtraction 1 \
--do_motion_correction 1 \
--denoise_slice_index 'all' \
--do_denoise 0 \
--do_extraction 1 \
--do_planar_extraction 1 \
--use_background_subtracted 1 \
--use_denoised 0 \
--recdates '221120' \
--fly '*' \
--trial '*' \
--do_cropping_session 0 \
--recording_index 'all'

