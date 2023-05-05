#!/bin/bash

ppn=${1:-12}
omp=${2:-8}
app=${3}
input=${4}

nnodes=${ppn}
export OMP_NUM_THREADS=${omp} 
echo "mpiexec ${MPI_BIND_OPTIONS} -n ${nnodes} -ppn ${ppn} ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine"
mpiexec ${MPI_BIND_OPTIONS} -n ${nnodes} -ppn ${ppn} ${GPU_AFFINITY} ../dummy_mpi
