#!/bin/bash
BIND8_S1_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153"
BIND8_S2_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"

qmcpack=`pwd`/build/bin/qmcpack
qmcpack=/home/jeongnim/applications.hpc.workloads.aurora.qmcpack/hpval-env/qmcpack_gpu_c0102m24152/bin/qmcpack
jobname=queue_per_det

#qmcpack=/home/jeongnim/applications.hpc.workloads.aurora.qmcpack/hpval-env/qmcpack_gpu_ye/bin/qmcpack
#jobname=aurora.ye.copy-eng.T0

qmcpack=/home/jeongnim/qmcpack.workspace/build/bin/qmcpack
jobname=recycle-immcl-opt.ddr
input=NiO-fcc-S128-dmc.xml
NODECOND="--nodes=16"

#jobname=recycle-immcl-opt.single-node.hbm-flat
#jobname=recycle-immcl-opt.single-node.hbm-cache
#NODECOND="--exclude=c001n[0049-0056],c002n[0008,0045,0049-0051,0053-0056] "

#qmcpack=/home/jeongnim/applications.hpc.workloads.aurora.qmcpack/hpval-env/qmcpack_gpu_c0108_d0109/bin/qmcpack
#jobname=aurora-main

export GPU_AFFINITY=/home/jeongnim/qmcpack.workspace/gpu_mapper.sh

# running on 6 GPUs
export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}
sbatch --job-name=${jobname} --time=00:15:00  --output=logs/%x.%A.out --error=logs/%x.%A.err $NODECOND ./run_aurora_w.sh 12 8 ${qmcpack} ${input}


