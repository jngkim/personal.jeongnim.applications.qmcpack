#!/bin/bash
sbatch --job-name=aurora --time=00:15:00  --output=%x-%A.out --error=%x-%A.err ./run_aurora_w.sh 12 8
