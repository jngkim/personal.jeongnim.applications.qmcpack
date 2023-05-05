#!/bin/bash

src_dir=/nfs/site/home/jeongnim/workspace/GitHub/qmcpack.workspace/qmcpack.intel/qmcpack.src
#install_dir=/scratch/hpc-wl-automation/qmcpack/share
install_dir=/scratch/users/jeongnim/share/gcc/9.4.0
build_dir=build
run_dir=a21-bench

export MPICH_CXX=icpx
export MPICH_C=icc

CXX=mpicxx CC=icx cmake \
  -S ${src_dir} \
  -B ${build_dir} \
  -DENABLE_OFFLOAD=ON -DOFFLOAD_TARGET=spir64 \
  -DENABLE_SYCL=ON \
  -DCMAKE_CXX_FLAGS="-mprefer-vector-width=512 -march=sapphirerapids " \
  -DCMAKE_C_FLAGS="-mprefer-vector-width=512  -march=sapphirerapids" \
  -DHDF5_ROOT=${install_dir} \
  -DLibXml2_ROOT=${install_dir} \
  -DUSE_VTUNE_A21=OFF \
  -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}

cmake --build ${build_dir} --parallel 16
#
