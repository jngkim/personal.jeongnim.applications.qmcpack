#!/bin/bash

ppn=${1:-12}
omp=${2:-8}
app=${3}
input=${4}

########################################################
# source /home/ftartagl/oneapi/inteloneapi-basekit-2023.1.001_PUBLIC/vtune/2023.1.0/vtune-vars.sh
# export VTUNE_ROOT=$VTUNE_PROFILER_DIR
# (i) add to cmake -DUSE_VTUNE_A21=ON or (2) modify CMakeCache.txt USE_VTUNE_A21 -> ON
########################################################

export KMP_BLOCKTIME=0
export OMP_PLACES=cores
export OMP_PROC_BIND=spread
export MPIR_CVAR_ENABLE_GPU=0
export HYDRA_TOPO_DEBUG=1
export FI_CXI_DEFAULT_CQ_SIZE=131072

export LIBOMPTARGET_PLUGIN=LEVEL0
export ONEAPI_DEVICE_SELECTOR=level_zero:gpu
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1

export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

export ZEX_NUMBER_OF_CCS=0:1,1:1,2:1,3:1,4:1,5:1

export LIBOMPTARGET_LEVEL0_COMPILATION_OPTIONS="-ze-opt-large-register-file"
export SYCL_PROGRAM_COMPILE_OPTIONS="-ze-opt-large-register-file"

export LIBOMPTARGET_LEVEL_ZERO_USE_IMMEDIATE_COMMAND_LIST=all
export LIBOMPTARGET_LEVEL_ZERO_INTEROP_USE_IMMEDIATE_COMMAND_LIST=1
export LIBOMPTARGET_LEVEL0_USE_COPY_ENGINE=main

export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS=0
export SYCL_PI_LEVEL_ZERO_USE_COPY_ENGINE=0:0

function print_env()
{
  module list
  icpx -V
  sycl-ls
  numactl -H
  numastat -m
  ucs bios options get ${SLURM_NODELIST} memory_mode
  ucs bios options get ${SLURM_NODELIST} snc_enabled

  echo 'MKLROOT='${MKLROOT}
  echo 'Binary='${app}
  env
  ldd ${app}
  echo
}

print_env ${app} 2>&1 | tee -a env.out

nnodes=${ppn}
export OMP_NUM_THREADS=${omp} 
echo "mpiexec ${MPI_BIND_OPTIONS} -n ${nnodes} -ppn ${ppn} ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine"
mpiexec ${MPI_BIND_OPTIONS} -n ${nnodes} -ppn ${ppn} ${GPU_AFFINITY}  \
vtune -c hotspots -r results -- ${app}  ${input} --enable-timers=fine  2>&1 | tee -a qmcpack.out

rm -rf einspline.*.dat
