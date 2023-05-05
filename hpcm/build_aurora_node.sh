#!/bin/bash

build_dir=${1:-build}
qmcpack_home=/home/jeongnim/qmcpack.workspace/qmcpack.intel
src_dir=${qmcpack_home}/qmcpack.src

hdf5_root=/home/jeongnim/share/hpcm/phdf5-fortran
BOOST_ROOT=/home/jeongnim/share/boost

run_dir=a21-bench

export MPICH_CXX=icpx
export MPICH_CC=icx

CMAKE=cmake

CXX=mpicxx CC=icx ${CMAKE} -G Ninja \
  -S ${src_dir} \
  -B ${build_dir} \
  -DENABLE_SYCL=ON \
  -DENABLE_OFFLOAD=ON -DOFFLOAD_TARGET=spir64 \
  -DCMAKE_CXX_FLAGS="-mprefer-vector-width=512  -march=sapphirerapids" \
  -DCMAKE_C_FLAGS="-mprefer-vector-width=512  -march=sapphirerapids" \
  -DHDF5_ROOT=${hdf5_root} -DENABLE_PHDF5=ON \
  -DBoost_INCLUDE_DIR=${BOOST_ROOT} \
  -DUSE_VTUNE_A21=OFF \
  -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}

${CMAKE} --build ${build_dir} --parallel
#
