#!/bin/bash
BIND8_S1_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153"
BIND8_S2_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"

qmcpack=`pwd`/build/bin/qmcpack

# running on 6 GPUs
export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}
sbatch --job-name=aurora --time=00:15:00  --output=%x-%A.out --error=%x-%A.err \
  ./run_aurora_w.sh 12 8 ${qmcpack}
