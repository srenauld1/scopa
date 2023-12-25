#!/bin/bash
#SBATCH --time=0:15:00
#SBATCH -p short
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --mem-per-cpu=3G
#SBATCH --array=[0-2]
#SBATCH --begin=now+10
#SBATCH --signal=B:SIGUSR1@90
#SBATCH --requeue

cat $(pwd)/pars.txt

echo $MANPATH
