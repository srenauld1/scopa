#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in bash
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--virtenv 'caiman' \
--index_extraction_param_set -75 \
--regionex 'post' \
--do_background_subtraction 0 \
--do_register 0 \
--do_denoise 0 \
--do_extract 1 \
--extract_in_2d 1 \
--use_background_subtracted 0 \
--use_denoised 1 \
--recdates '2211*' \
--fly '*' \
--trial '1' \
--do_cropping_session 0 \
--recording_index 'all'
