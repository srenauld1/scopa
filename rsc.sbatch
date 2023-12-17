#!/bin/bash
#SBATCH -p short
#SBATCH -t 11:00:00
#SBATCH -c 5
#SBATCH --mem=55G
#SBATCH --array=[1-5]

module purge
module load matlab/2023a
RECDATES='*'
FLY='*'
TRIAL='*'
SMOOTHWINDOWTIME=30

matlab -batch "try; cx_remove_scan_noise('$RECDATES', '$FLY', '$TRIAL', $SMOOTHWINDOWTIME, $SLURM_ARRAY_TASK_ID); catch; end; quit"
