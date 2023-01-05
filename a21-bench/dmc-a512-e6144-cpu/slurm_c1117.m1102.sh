#!/bin/bash

#SBATCH --job-name=auto-imm.c1117m1102
#SBATCH --output=%x.%A.out
#SBATCH --error=%x.%A.err
#SBATCH --time=00:10:00

#########################################################
#
# batch script with compilers 20221117
# OMP interop returns SYCL::queue with immediate command list
# Require libpi_level_zero.so patch by Rajiv D
#
#########################################################

export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE

cdir=`pwd`
app=/home/jeongnim/applications.hpc.workloads.aurora.qmcpack/hpval-env/qmcpack_gpu_c1117m1102/bin/qmcpack

export LD_LIBRARY_PATH="/home/jeongnim/share/imm-fix-20221117:$LD_LIBRARY_PATH"

module list
env | grep SLURM
lscpu
numactl -H
sycl-ls
echo '***********************'
echo ${app}
ldd ${app}
echo '***********************'
icpx -V

run="${SLURM_JOB_NAME}.${SLURM_JOB_ID}.${SLURMD_NODENAME}"

export KMP_BLOCKTIME=0
export OMP_PLACES=cores
export OMP_PROC_BIND=close
export KMP_AFFINITY=verbose
export HYDRA_TOPO_DEBUG=1
#Dsiable GPU optimization of MPICH
#export MPIR_CVAR_ENABLE_GPU=0


export LIBOMPTARGET_PLUGIN=LEVEL0
export SYCL_DEVICE_FILTER=level_zero:gpu

export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

#export ForceHostPointerImport=1

export ZEX_NUMBER_OF_CCS=0:1,1:1,2:1,3:1,4:1,5:1
#export ZEX_NUMBER_OF_CCS=0:4,1:4,2:4,3:4,4:4,5:4

export LIBOMPTARGET_LEVEL_ZERO_USE_IMMEDIATE_COMMAND_LIST=1
export LIBOMPTARGET_LEVEL0_USE_COPY_ENGINE=main
#export LIBOMPTARGET_LEVEL_ZERO_COMMAND_BATCH=copy
#export LIBOMPTARGET_LEVEL_ZERO_COMMAND_BATCH=compute

unset SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS
unset SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS

export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS=0
#export SYCL_PI_LEVEL_ZERO_USE_COPY_ENGINE=1

export PLATFORM_NUM_GPU=6
export PLATFORM_NUM_GPU_TILES=2

input=input.a21.xml
out=aurora
#
omp=8
#mpirun  -genv OMP_NUM_THREADS=${omp} -bind-to user:18-25+122-129,26-33+130-137 \
#  -np 1 -env ZE_AFFINITY_MASK=1.0  ${app} ${input} --enable-timers=fine \
#: -np 1 -env ZE_AFFINITY_MASK=1.1  ${app} ${input} --enable-timers=fine 2>&1 | tee -a ${out}.p2x${omp}.g1.out

BIND8_S2_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146#-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"
mpirun  -genv OMP_NUM_THREADS=${omp} ${BIND8_S2_OPTIONS} \
-ppn 12 ./gpu_mapper.sh  ${app} ${input} --enable-timers=fine \
2>&1 | tee -a ${out}.p12x${omp}.out

