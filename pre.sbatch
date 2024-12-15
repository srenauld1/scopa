#!/bin/bash

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

module purge

## LOAD MODULES ##
if [ "$JOBNM" == dnp ]; then #deepcad denoising uses different python version
    module load gcc/9.2.0 python/3.9.14
else 
    module load python/3.10.11
fi

## LOAD VIRTUAL ENVIRONMENT ##
if [ "$DO_COPYFILES" == 0 ]; then  #load virtual env if not copying files from wilsonlab server into O2
    echo "DOING ANALYSIS (NOT COPYING FILES) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
    if [ "$JOBNM" == alo ]; then
        echo "RUNNING AUTOALLOCATE JOB ON TRANSFER PARTITION"
    elif [ "$JOBNM" == dnp ]; then #deepcad denoising
        module load cuda/11.7 #12.1
        eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"
        conda activate deepcad
        /n/cluster/bin/job_gpu_monitor.sh &
    elif [ "$JOBNM" == mcp ] || [ "$JOBNM" == exp ] || [ "$JOBNM" == stc ]; then #auto-allocate (doesn't actually need caiman but this will work) or caiman registration or extraction (stitch should not need it but maybe still does bc of an error?)
        eval "$(/n/data1/hms/neurobio/wilson/miniforge3/bin/conda shell.bash hook)"
        conda activate caiman #should not have to activate caiman for do_stitch but ffmpeg does not work when i remove this; should fix this but doens't really matter
    elif [ "$JOBNM" == rsc ] || [ "$JOBNM" == a2p ]; then #matlab engine
        source /n/data1/hms/neurobio/wilson/mle/bin/activate
    fi
else  #no need to load any virtual environment for copying files
    echo "COPYING FILES (NOT DOING ANALYSIS) BECAUSE DO_COPYFILES IS SET TO "$DO_COPYFILES""
fi


## SET PYTHON PATH ##
if [ "$JOBNM" == dnp ]; then #deepcad denoising
    pydir=/n/data1/hms/neurobio/wilson/miniforge3/envs/deepcad/bin/python3
elif [ "$JOBNM" == alo ] || [ "$JOBNM" == mcp ] || [ "$JOBNM" == exp ] || [ "$JOBNM" == stc ]; then #auto-allocate (doesn't actually need caiman but this will work) or caiman registration or extraction (stitch should not need it but maybe still does bc of an error?)
    pydir=/n/data1/hms/neurobio/wilson/miniforge3/envs/caiman/bin/python3
elif [ "$JOBNM" == rsc ] || [ "$JOBNM" == a2p ]; then #matlab engine
    pydir=/n/data1/hms/neurobio/wilson/mle/bin/python3
fi


## CALL PIPELINE ##
$pydir $SCOPADIR/ppl.py \
--first_job "$FIRST_JOB" \
--do_copyfiles "$DO_COPYFILES" \
--jobnm "$JOBNM" \
--recording_index $SLURM_ARRAY_TASK_ID \
--pth_parsfile "$PTH_PARSFILE"

#wait
sleep 1m
date
sleep 1m

# scontrol show job $SLURM_JOB_ID


