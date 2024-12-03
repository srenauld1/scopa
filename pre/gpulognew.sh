#!/bin/bash
# this script queries the NVIDIA GPU cards allocated for the jobs every 5 minutes and stores
# utilization data on a file named <jobid>.gpulog
# user should use this script in sbatch script with this format
#
# /n/cluster/bin/job_gpu_monitor.sh &
# your_gpu_job


filname
pathlog="$part1/$SLURM_JOBID.gpulog"
echo "Timestamp GPU_utilization(%) GPU_VRAM(%) GPU_VRAM" > $pathlog
while true
do
   echo $( date +%Y-%m-%dT%H-%M-%S ) $( nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits|awk -F"," '{print$
   sleep 5m
#check the job is doing something else and exit if not
   JOBPID=`ps -AF|grep $SLURM_JOBID|grep slurmstepd|awk '{print $2}'|tail -1`
   JOBPPID=`pstree -A -l -g -p $JOBPID|grep -v gpu_monitor.sh|sed 's/{slurmstepd}([0-9]*,[0-9]*)//g'|sed 's/{.*}//g'|sed -e 's/[^0-9]/\n/g'|grep -v ^$|$
   if [[ -z $JOBPPID ]]
   then
     echo "$( date +%Y-%m-%dT%H-%M-%S ) no other process detected terminitaing the gpu monitor" >> $SLURM_JOBID.gpulog
     exit 0
   fi
done