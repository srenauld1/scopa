#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in bash
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--index_extraction_param_set 'default' \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_background_subtraction 0 \
--do_motion_correction 0 \
--denoise_slice_index 'all' \
--do_denoise 0 \
--use_denoised 0 \
--do_extraction 0 \
--do_planar_extraction 0 \
--recdates '*' \
--fly '*' \
--trial '*' \
--do_cropping_session 0 \
--recording_index 'all'

