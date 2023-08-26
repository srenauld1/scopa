#!/bin/bash

##noglob \
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--index 0 \
--region_extraction 'pb' 'gar' 'gal' 'no' \
--do_motion_correction 1 \
--do_denoise 0 \
--do_extraction 0 \
--do_planar_extraction 0 \
--recdates '*' \
--fly '*' \
--trial '*' \
--do_cropping_session 0 \
--array_index 1
