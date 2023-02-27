#!/bin/bash

ppn=${1:-12}
omp=${2:-8}
app=${3}
input=${4}

if [[ -z ${GPU_AFFINITY} ]]; then
  GPU_AFFINITY=/home/jeongnim/qmcpack.workspace/hpcm/gpu_mapper.sh
  echo "Using default mapper "$GPU_AFFINITY
fi

# MPI_BIND_OPTIONS are not set, use Aurora nodes, 6 GPU configurations
if [[ -z ${MPI_BIND_OPTIONS} ]]; then
  MPI_BIND_OPTIONS="--cpu-bind list:2-9,106-113:10-17,114-121:18-25,122-129:26-33,130-137:34-41,138-145:42-49,146-153:54-61,158-165:62-69,166-173:70-77,174-181:78-85,182-189:86-93,190-197:94-101,198-205"
fi

if [[ -z ${app} ]]; then
  app=`pwd`/build/bin/qmcpack
  echo "Using default binary: ${app}"
fi

if [[ -z ${input} ]]; then
  input=NiO-fcc-S128-dmc.xml
fi

#mtag=`date "+%Y%m%d.%H%M"`
mtag=`date "+%Y%m%d"`
if [[ -z ${PBS_JOBNAME} ]]; then
  log_root=${mtag}.p${ppn}x${omp}
else
  log_root="${mtag}.${PBS_JOBNAME}.n${PBS_NODENUM}.p${ppn}x${omp}.${PBS_JOBID}"
fi

if [[ -z ${PBS_NODELIST} ]]; then
  PBS_NODELIST='any'
fi

# run directory
run_dir=${log_root}
mkdir -p ${run_dir}
cp ${input} ${run_dir}/

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
  echo
  env | grep SLURM
  echo
  env | grep LIBOMP
  echo
  env | grep SYCL
  echo
  ldd ${app}
  echo
}

print_env ${app} 2>&1 | tee -a ${run_dir}/env.out

cd ${run_dir}

echo "mpirun  -genv OMP_NUM_THREADS=${omp} ${MPI_BIND_OPTIONS} -ppn ${ppn} \
  ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine " 2>&1 | tee -a env.out

mpirun  -genv OMP_NUM_THREADS=${omp} ${MPI_BIND_OPTIONS} -ppn ${ppn} \
  ${GPU_AFFINITY}  ${app}  ${input} --enable-timers=fine  2>&1 | tee -a qmcpack.out

mpirun  -genv OMP_NUM_THREADS=${omp} ${MPI_BIND_OPTIONS} -ppn ${ppn} \
  ${GPU_AFFINITY}  ${app}  

#mpirun  -genv OMP_NUM_THREADS=${omp} ${MPI_BIND_OPTIONS} -ppn ${ppn} \
#  ${GPU_AFFINITY}  ${app} 2>&1 | tee -a qmcpack.out

function print_summary()
{
  grep Execution qmcpack.out
  echo
  grep "reference energy" qmcpack.out
  echo
  grep "reference var" qmcpack.out
  echo
  grep " DMC   " qmcpack.out | awk '{print "FOM", 70/$2*66, $2}'
}

print_summary > summary.out

rm -rf einspline.*.dat
