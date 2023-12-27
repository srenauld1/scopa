#!/bin/bash

##noglob \  #noglob is for passing this directly to zsh shell (mac terminal), not needed in a bash script like this
/Users/wienecke/mambaforge/envs/caiman/bin/python /Users/wienecke/Documents/scopa/pipeline_init.py \
--pars_filename 'pars.txt' \
--do_copyfiles 'in' 

