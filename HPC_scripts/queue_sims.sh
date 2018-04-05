#!/bin/bash
# -- Name of the job ---
#PBS -N MONSTeR
# –- specify queue --
#PBS -q hpc
# -- estimated wall clock time (execution time): hh:mm:ss --
#PBS -l walltime=06:00:00
# –- number of processors/cores/nodes --
#PBS -l nodes=1:ppn=4
# –- user email address --
#PBS -M matart@fotonik.dtu.dk
# –- mail notification –-
#PBS -m a
# -- run in the current working (submission) directory --
if test X$PBS_ENVIRONMENT = XPBS_BATCH; then cd $PBS_O_WORKDIR; fi
# here follow the commands you want to execute

pwd > "out seed $seed util_lo $util_lo.txt"
printenv | grep PBS >> "out seed $seed util_lo $util_lo.txt"
matlab -nodisplay -r "sweep_seed_util_lo_sim("$seed","$util_lo")" >> "seed $seed util_lo $util_lo.txt"