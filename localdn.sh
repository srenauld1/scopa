#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in bash
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--index_extraction_param_set 0 \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_background_subtraction 0 \
--do_motion_correction 0 \
--do_denoise 1 \
--use_denoised 0 \
--do_extraction 1 \
--do_planar_extraction 0 \
--recdates '*' \
--fly '*' \
--trial '*' \
--do_cropping_session 0 \
--recording_index 0
