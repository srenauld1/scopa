#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in bash
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--index 0 \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_motion_correction 0 \
--do_denoise 0 \
--do_extraction 1 \
--do_planar_extraction 1 \
--recdates '20230627' \
--fly '*' \
--trial '2' \
--do_cropping_session 0 \
--array_index 0
