#!/bin/bash

# Usage : ./launch_interactive.sh [special-name] [ppn] [omp]
jtag=${1:-aurora}
ppn=${2:-2}
omp=${3:-8}

# Better mapping on SNC4
BIND8_S1_OPTIONS="-bind-to user:57-69+169-181,70-82+182-194,84-96+196-208,98-110+210-222"
BIND8_G0_OPTIONS="-bind-to user:1-13+113-125,14-26+126-138"
BIND8_S2_OPTIONS="-bind-to user:1-8+113-120,14-21+126-133,28-35+140-147,42-49+154-161,57-64+169-176,70-77+182-189,84-91+196-203,98-105+210-217"

qmcpack=/nfs/site/home/jeongnim/workspace/GitHub/qmcpack.workspace/build/bin/qmcpack

input=NiO-fcc-S128-dmc.xml
input=input.batch.xml
nnodes=1

export PLATFORM_NUM_GPU=1
export GPU_AFFINITY=`pwd`/gpu_mapper.sh

export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}

mtag=`date "+%Y%m%d.%H%M"`
export A21_JOBNAME="${mtag}.${jtag}.${HOSTNAME}"

###################
RUN_SCRIPT=run_copy_eng_imm.sh

have_h5=0
if [[ -f "einspline.tile_2-2626-22-2-2.spin_0.tw_0.l0u3072.g112x66x66.h5" ]]; then
  have_h5=1
fi

run_dir=${A21_JOBNAME}.p${ppn}x${omp}
mkdir -p ${run_dir}
cp ${input} ${run_dir}/

cd ${run_dir}

if [[ "$have_h5" -eq 1 ]]; then
  ln -s ../einspline.tile_2-2626-22-2-2.spin_0.tw_0.l0u3072.g112x66x66.h5 .
  ln -s ../einspline.tile_2-2626-22-2-2.spin_1.tw_0.l0u3072.g112x66x66.h5 .
fi

../${RUN_SCRIPT} ${ppn} ${omp} ${qmcpack} ${input}

if [[ "$have_h5" -eq 0 ]]; then
  mv einspline*.h5 ../
fi

rm  -rf *.h5
#
cd -
