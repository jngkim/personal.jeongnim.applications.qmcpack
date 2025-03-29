#!/bin/bash

qmcpack=$1
nnodes=$2
ppn=$3
omp=$4
input=$5
fom=$6

mpi=$(( ppn * nnodes ))

export NEOReadDebugKeys=1
export SplitBcsCopy=0
export ExperimentalH2DCpuCopyThreshold=50000

export KMP_BLOCKTIME=0
export OMP_PLACES=cores
export OMP_PROC_BIND=spread
export HYDRA_TOPO_DEBUG=1

export OMP_TARGET_OFFLOAD=MANDATORY
export LIBOMPTARGET_PLUGIN=LEVEL0
export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

export ONEAPI_DEVICE_SELECTOR=level_zero:gpu
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1

export LIBOMPTARGET_LEVEL_ZERO_COMPILATION_OPTIONS="-ze-opt-large-register-file"
export SYCL_PROGRAM_COMPILE_OPTIONS="-ze-opt-large-register-file"

export LIBOMPTARGET_LEVEL_ZERO_COMMAND_MODE=sync
export ZE_FLAT_DEVICE_HIERARCHY=FLAT

export OMP_NUM_THREADS=${omp} 
#echo "mpirun ${MPI_BIND_OPTIONS} -np ${ppn} ${GPU_AFFINITY}  ${qmcpack}  ${input} --enable-timers=fine"
#mpirun ${MPI_BIND_OPTIONS} -np ${mpi} ${GPU_AFFINITY}  ${qmcpack}  ${input} --enable-timers=fine  2>&1 | tee -a qmcpack.out

mpirun -np ${mpi} ${qmcpack}  ${input} --enable-timers=fine  2>&1 | tee -a qmcpack.out

grep Execution qmcpack.out
grep "reference energy" qmcpack.out
grep "reference var" qmcpack.out
grep "  DMCBatched::Production   " qmcpack.out | awk '{print "FOM", 70/$2*66, $2}'

rm -rf einspline.*.dat
