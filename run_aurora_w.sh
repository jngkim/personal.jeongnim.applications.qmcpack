#!/bin/bash

ppn=${1:-12}
omp=${2:-8}
app=${3}

if [[ -z ${app} ]]; then
  app=`pwd`/build/bin/qmcpack
  echo "Using default binary: ${app}"
fi

mtag=`date "+%Y%m%d.%H%M"`

if [[ -z ${SLURM_JOB_NAME} ]]; then
  log_root=o${mtag}
else
  log_root="${SLURM_JOB_NAME}.${SLURM_JOB_ID}.${SLURMD_NODENAME}"
fi

export OMP_PLACES=cores
export OMP_PROC_BIND=close
export KMP_AFFINITY=verbose
export HYDRA_TOPO_DEBUG=1

export ONEAPI_DEVICE_SELECTOR=level_zero:gpu

export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

export ZEX_NUMBER_OF_CCS=0:1,1:1,2:1,3:1,4:1,5:1

export LIBOMPTARGET_LEVEL_ZERO_USE_IMMEDIATE_COMMAND_LIST=1

export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export SYCL_PI_LEVEL_ZERO_DEVICE_SCOPE_EVENTS=0

# binary

module list
echo
echo 'MKLROOT='${MKLROOT}
echo 'Binary=' ${app}
echo
ldd ${app}

echo ${LD_LIBRARY_PATH}
echo

# run directory
run_dir=a21-bench/dmc-a512-e6144-cpu
input=NiO-fcc-S128-dmc.xml

pushd ${run_dir}

####################################################
# 12 MPI ranks and 8 threads, 1 MPI rank per tile
# Affinity for 3 MPI ranks per socket and 8 theads per MPI rank
# Apply to 52-core parts
####################################################
GPU_AFFINITY=./gpu_mapper.sh

# MPI_BIND_OPTIONS are not set, use Aurora nodes, 6 GPU configurations
if [[ -z ${MPI_BIND_OPTIONS} ]]; then
  MPI_BIND_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"
fi

echo "mpirun  -genv OMP_NUM_THREADS=${omp} ${MPI_BIND_OPTIONS} -ppn ${ppn} \
  ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine "

mpirun  -genv OMP_NUM_THREADS=${omp} ${MPI_BIND_OPTIONS} -ppn ${ppn} \
  ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine  2>&1 | tee -a ${log_root}.out

echo '================================='
grep Production ${log_root}.out
grep Execution ${log_root}.out
grep "reference energy" ${log_root}.out
grep "reference var" ${log_root}.out
echo '================================='

popd
