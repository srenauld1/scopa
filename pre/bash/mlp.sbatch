#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge
module load matlab/2023a

if [ "$DO_COPYFILES" == 1 ] || [ "$DO_COPYFILES" == 2 ]; then #no need to load any virtual environment for copying files 
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
else #load virtual env if not copying files
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
fi

matlab -batch "try; a2p("$PTH_PARSFILE", "$DO_COPYFILES", $SLURM_ARRAY_TASK_ID); catch; end; quit"

##ampersand???

wait
sleep 1m
date
sleep 1m


# scontrol show job $SLURM_JOB_ID

