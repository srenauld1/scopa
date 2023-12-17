#!/bin/bash
#SBATCH -p short
#SBATCH -t 2:00:00
#SBATCH -c 5
#SBATCH --mem=30G
#SBATCH --array=[0-6]

module purge
module load matlab/2023a
RECDATES='*'
FLY='*'
TRIAL='*'
SMOOTHWINDOWTIME=30

matlab -batch "try; cx_remove_scan_noise('$RECDATES', '$FLY', '$TRIAL', $SMOOTHWINDOWTIME, $SLURM_ARRAY_TASK_ID); catch; end; quit"
