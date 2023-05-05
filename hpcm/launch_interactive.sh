#!/bin/bash

# Usage : ./launch_interactive.sh [special-name] [ppn] [omp]
jtag=${1:-aurora}
ppn=${2:-12}
omp=${3:-8}

BIND8_S0_OPTIONS="--cpu-bind list:1-8,105-112:9-16,113-120:17-24,121-128:27-34,131-138:35-42,139-146:43-50,147-154"
BIND8_S1_OPTIONS="--cpu-bind list:53-60,157-164:61-68,165-172:69-76,173-180:79-86,183-190:87-94,191-198:95-102,199-206"
BIND8_S2_OPTIONS="--cpu-bind list:1-8,105-112:9-16,113-120:17-24,121-128:27-34,131-138:35-42,139-146:43-50,147-154:53-60,157-164:61-68,165-172:69-76,173-180:79-86,183-190:87-94,191-198:95-102,199-206"

qmcpack=/tmp/jeongnim/build/bin/qmcpack

input=NiO-fcc-S128-dmc.xml
input=input.batch.xml

export CPU_MEMORY=`numactl -H | grep available | awk '{print $2}'`

export GPU_AFFINITY=`pwd`/gpu_snc4_mapper.sh
export GPU_AFFINITY=`pwd`/gpu_quad_mapper.sh
export GPU_AFFINITY=`pwd`/gpu_mapper.sh

export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}

mtag=`date "+%Y%m%d.%H%M"`

export A21_JOBNAME="${mtag}.${HOST}.${jtag}"

#RUN_SCRIPT=run_debug.sh
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
