#!/bin/bash

ppn=${1:-12}
omp=${2:-8}
app=${3}
input=${4}

# run directory

#export DirectSubmissionRelaxedOrdering=1
#export NEOReadDebugKeys=1
#export EventWaitOnHost=1
#export PrintDebugSettings=1

#export NEOReadDebugKeys=1
#export SplitBcsCopy=0

export KMP_BLOCKTIME=0
export OMP_PLACES=cores
export OMP_PROC_BIND=spread
export HYDRA_TOPO_DEBUG=1

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

nnodes=${SLURM_JOB_NUM_NODES:-1}

if [[ "$nnodes" -eq 1 ]]; then
  unset HYDRA_TOPO_DEBUG
fi

print_env ${app} 2>&1 | tee -a env.out

export OMP_NUM_THREADS=${omp} 
echo "mpiexec ${MPI_BIND_OPTIONS} -n ${nnodes} -ppn ${ppn} ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine"
mpirun ${MPI_BIND_OPTIONS} -ppn ${ppn} ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine 2>&1 | tee -a qmcpack.out

function print_summary()
{
  grep Execution qmcpack.out
  echo
  grep "reference energy" qmcpack.out
  echo
  grep "reference var" qmcpack.out
  echo
  grep "  DMCBatched   " qmcpack.out | awk '{print "FOM", 70/$2*66, $2}'
}

print_summary > summary.out

rm -rf einspline.*.dat
