#!/bin/bash

# Usage : ./launch_interactive.sh 
NGPU=$(sycl-ls | grep level_zero:gpu | wc -l)
mtag=$(date "+%Y%m%d.%H%M")
host=$(hostname)

jtag=${QTAG:-aurora}  # output tag
ppn=${PPN:-$NGPU}     # ppn
omp=${OMP:-8}         # omp threads
nnodes=${NNODES:-1}

# Only use to overwrite default
# CPU mapping
#BIND8_S0_OPTIONS="-bind-to user:1-13+113-125,14-26+126-138"
#BIND8_S1_OPTIONS="-bind-to user:57-69+169-181,70-82+182-194,84-96+196-208,98-110+210-222"
#BIND8_S2_OPTIONS="-bind-to user:1-8+113-120,14-21+126-133,28-35+140-147,42-49+154-161,57-64+169-176,70-77+182-189,84-91+196-203,98-105+210-217"
#export GPU_AFFINITY=$(pwd)/gpu_mapper.sh
#export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}

# Recommended ENVs to run qmcpack
RUN_SCRIPT=execute_qmcpack.sh
qmcpack=$(pwd)/qmcpack

# create a run directory
input_main=input.template.xml
run_dir=${jtag}.p${ppn}.o${omp}.${host}.${mtag}
mkdir -p ${run_dir}
cat $input_main |  sed s/OMP/${omp}/  > ${run_dir}/input.xml

have_h5=0
if [[ -f "einspline.tile_2-2626-22-2-2.spin_0.tw_0.l0u3072.g112x66x66.h5" ]]; then
  have_h5=1
fi

pushd ${run_dir}

if [[ "$have_h5" -eq 1 ]]; then
  ln -s ../einspline.tile_2-2626-22-2-2.spin_0.tw_0.l0u3072.g112x66x66.h5 .
  ln -s ../einspline.tile_2-2626-22-2-2.spin_1.tw_0.l0u3072.g112x66x66.h5 .
fi

../${RUN_SCRIPT} ${qmcpack} 1 ${ppn} ${omp} input.xml

if [[ "$have_h5" -eq 0 ]]; then
  mv einspline*.h5 ../
fi

rm  -rf *.h5

popd
