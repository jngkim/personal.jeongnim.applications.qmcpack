#!/bin/bash
BIND8_S1_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153"
BIND8_S2_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"

qmcpack=/home/jeongnim/qmcpack.workspace/build_boris_c0227/bin/qmcpack
jobname=hbm.flat-snc4.mpich49.c0227.neo-025375.immcl

input=NiO-fcc-S128-dmc.xml
input=input.batch.xml

export GPU_AFFINITY=/home/jeongnim/qmcpack.workspace/gpu_mapper.sh

export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}

export SBATCH_RESERVATION=Performance_Tuning

RUN_SCRIPT=run_copy_eng_imm.sh

sbatch --job-name=${jobname} --time=00:12:00  --output=logs/%x.%A.out --error=logs/%x.%A.err $NODECOND ./${RUN_SCRIPT} 12 8 ${qmcpack} ${input}

