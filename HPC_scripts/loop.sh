#!/bin/bash

for seed in {1..5}
do
	for util_lo in {1..4}
	do
		echo "Seed: $seed -- util_lo: $util"
		qsub -v seed=$seed, util_lo=$util_lo queue_sims.sh
	done
done
