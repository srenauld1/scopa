#!/bin/bash
#SBATCH -p short
#SBATCH --mem 20G
#SBATCH --time=11:59:00
#SBATCH -c 8

echo "$(date): job $SLURM_JOBID (array task $SLURM_ARRAY_TASK_ID) starting on $SLURM_NODELIST"

#rsync -a /n/scratch3/users/p/par26/stacks/analysis/ /n/files/Neurobio/wilsonlab/pablo/analysis -ignore-existing
rsync -anv /n/scratch3/users/p/par26/stacks/analysis/ /n/files/Neurobio/wilsonlab/pablo/analysis -ignore-existing
