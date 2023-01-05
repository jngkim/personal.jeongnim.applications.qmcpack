#!/bin/bash

app=../../hpval-env/build/bin/qmcpack

export OMP_PLACES=cores
export OMP_PROC_BIND=close
export KMP_AFFINITY=verbose
export HYDRA_TOPO_DEBUG=1


export LIBOMPTARGET_PLUGIN=LEVEL0
export SYCL_DEVICE_FILTER=level_zero:gpu

export ZEX_NUMBER_OF_CCS=0:1,1:1,2:1,3:1,4:1,5:1

export LIBOMPTARGET_LEVEL_ZERO_USE_IMMEDIATE_COMMAND_LIST=1
unset SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS
unset SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS

export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS=0

#export DirectSubmissionControllerDivisor=1

input=NiO-fcc-S128-dmc.xml

out=${SLURM_JOB_NAME}

BIND8_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"

omp=8

mpirun  -genv OMP_NUM_THREADS=${omp} ${BIND8_OPTIONS} \
  -np 12 ./gpu_mapper.sh ${app} ${input} --enable-timers=fine \
