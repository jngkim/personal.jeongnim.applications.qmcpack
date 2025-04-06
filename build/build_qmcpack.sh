#!/bin/bash

src_dir=/nfs/site/home/jeongnim/workspace/qmcpack/src/internal/qmcpack.src
build_dir=${1:-qmcpack}
run_dir=a21-bench

export MPICH_CXX=icpx
export MPICH_C=ic
export I_MPI_CXX=icpx
export I_MPI_C=icx
export I_MPI_CC=icx

if [ "$CPU" == "yes" ]; then
  CXX=mpicxx CC=icx cmake \
  	-S ${src_dir} \
  	-B ${build_dir} \
  	-DCMAKE_CXX_FLAGS="-g -mprefer-vector-width=512 "\
  	-DCMAKE_C_FLAGS="-g -mprefer-vector-width=512 " \
  	-DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}
else
  CXX=mpicxx CC=icx cmake \
    -S ${src_dir} \
    -B ${build_dir} \
    -DENABLE_OFFLOAD=ON -DOFFLOAD_TARGET=spir64 \
    -DENABLE_SYCL=ON \
    -DCMAKE_CXX_FLAGS="-g -mprefer-vector-width=512 "\
    -DCMAKE_C_FLAGS="-g -mprefer-vector-width=512 " \
    -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}
fi
cmake --build ${build_dir} --parallel 16
#
