#!/bin/bash

#SBATCH --job-name=aurora
#SBATCH --output=%x-%A.out
#SBATCH --error=%x-%A.err
##SBATCH -N 16
#SBATCH --time=00:15:00

export OMP_PLACES=cores
export OMP_PROC_BIND=close
export KMP_AFFINITY=verbose
export HYDRA_TOPO_DEBUG=1

export LIBOMPTARGET_PLUGIN=LEVEL0
export SYCL_DEVICE_FILTER=level_zero:gpu

export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

export ZEX_NUMBER_OF_CCS=0:1,1:1,2:1,3:1,4:1,5:1

export LIBOMPTARGET_LEVEL_ZERO_USE_IMMEDIATE_COMMAND_LIST=1

export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS=0

BIND8_S2_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"

# binary
app=/home/jeongnim/applications.hpc.workloads.aurora.qmcpack/hpval-env/qmcpack_gpu_hpval/bin/qmcpack

module list
echo
echo 'MKLROOT='${MKLROOT}
echo 'Binary=' ${app}
echo
ldd ${app}
echo
env | grep SLURM

####################################################
# 12 MPI ranks and 8 threads, 1 MPI rank per tile
# Affinity for 3 MPI ranks per socket and 8 theads per MPI rank
# Apply to 52-core parts
####################################################
ppn=12
omp=8

export PLATFORM_NUM_GPU=6
export PLATFORM_NUM_GPU_TILES=2
GPU_AFFINITY=./gpu_mapper.sh

input=NiO-fcc-S128-dmc.xml

mpirun  -genv OMP_NUM_THREADS=${omp} ${BIND8_S2_OPTIONS} -ppn ${ppn} \
  ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine  
