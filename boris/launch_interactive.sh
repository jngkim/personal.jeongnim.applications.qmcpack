#!/bin/bash

# Usage : ./launch_interactive.sh [special-name] [ppn] [omp]
jtag=${1:-aurora}
ppn=${2:-12}
omp=${3:-8}

BIND8_S0_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153"
BIND8_S2_OPTIONS="-bind-to user:2-9+106-113,10-17+114-121,18-25+122-129,26-33+130-137,34-41+138-145,42-49+146-153,54-61+158-165,62-69+166-173,70-77+174-181,78-85+182-189,86-93+190-197,94-101+198-205"

qmcpack=/home/jeongnim/qmcpack.workspace/build_boris_c0227/bin/qmcpack

input=NiO-fcc-S128-dmc.xml
input=input.batch.xml
nnodes=1

export GPU_AFFINITY=`pwd`/gpu_mapper.sh

export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}

mtag=`date "+%Y%m%d.%H%M"`
export A21_JOBNAME="${mtag}.${jtag}.${HOST}"
export SBATCH_RESERVATION=Performance_Tuning
RUN_SCRIPT=`pwd`/run_aurora_w.sh

# Add new ENVs
#export NEOReadDebugKeys=1
#export DirectSubmissionRelaxedOrdering=1
#export RebuildPrecompiledKernels=1
#export ForceLargeGrfCompilationMode=1
#export DirectSubmissionControllerTimeout=50000
#export A21_JOBNAME="${mtag}.neo-025716.bd-ooos.n1"
#export LIBOMPTARGET_LEVEL_ZERO_COMMAND_MODE=async

# Use L0 defaults with OOOS
unset NEOReadDebugKeys
unset DirectSubmissionRelaxedOrdering
unset RebuildPrecompiledKernels
unset ForceLargeGrfCompilationMode
unset DirectSubmissionControllerTimeout

###################
have_h5=0
if [[ -f "einspline.tile_2-2626-22-2-2.spin_0.tw_0.l0u3072.g112x66x66.h5" ]]; then
  have_h5=1
fi

run_dir=${A21_JOBNAME}.n${nnodes}.p${ppn}x${omp}
mkdir -p ${run_dir}
cp ${input} ${run_dir}/

cd ${run_dir}

if [[ "$have_h5" -eq 1 ]]; then
  ln -s ../einspline.tile_2-2626-22-2-2.spin_0.tw_0.l0u3072.g112x66x66.h5 .
  ln -s ../einspline.tile_2-2626-22-2-2.spin_1.tw_0.l0u3072.g112x66x66.h5 .
fi

${RUN_SCRIPT} ${ppn} ${omp} ${qmcpack} ${input}

if [[ "$have_h5" -eq 0 ]]; then
  mv einspline*.h5 ../
fi

rm  -rf *.h5

cd -
