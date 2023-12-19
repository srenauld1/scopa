#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in a bash script like this
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--do_register 1 \
--do_planar_registration 1 \
--do_background_subtraction 0 \
--len_window_smooth_t 0 \
--recdates '*' '20231119' '20231120' '20237897897897' \
--fly '*' '1' '9' '100' \
--trial '*' '2' '200' \
--recording_index 'all'

