#!/bin/bash
#PBS -M s113113@student.dtu.dk
#PBS -m a
#PBS -N 16QAM
#PBS -q hpc
#PBS -l walltime=00:50:00

cd $PBS_O_WORKDIR
pwd > "out Pin $pin Spacing $sin.txt"
printenv | grep PBS >> "out Pin $pin Spacing $sin.txt"
matlab -nodisplay -r "sweepPin_Spacing_sim("$pin","$sin")" >> "out Pin $pin Spacing $sin.txt"
