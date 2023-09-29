#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in bash
for i in 0 4 2
do
    /Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
    --virtenv 'caiman' \
    --index_extraction_param_set 'default' \
    --region_extraction 'pb' 'gar' 'gal' 'no' \
    --denoise_slice_index $i \
    --do_background_subtraction 0 \
    --do_register 0 \
    --do_denoise 0 \
    --do_extract 0 \
    --do_planar_extraction 0 \
    --use_background_subtracted 0 \
    --use_denoised 0 \
    --recdates '20230627' \
    --fly '*' \
    --trial '*' \
    --do_cropping_session 0 \
    --recording_index 0 &

done
