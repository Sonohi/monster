#!/bin/bash

for pin in {1..73}
do
	for sin in {1..2}
	do
		echo "Pin: $pin -- Spacing: $sin"
		qsub -v sin=$sin,pin=$pin my_queue_sims_sweep.sh
	done
done
