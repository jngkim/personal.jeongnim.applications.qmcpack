#!/bin/bash
##
#ml load cmake
#ml load hdf5/1.14.3

src=${SRC:-"intel.postat/qmcpack.src"}
build=${BUILD:-intel}

src_dir=src/$src
build_dir=build/$build

LIB_DIR=/flare/Aurora_deployment/jnkim/share
export MPICH_CXX=icpx
export MPICH_CC=icx

# Use AOT
#  -DENABLE_OFFLOAD=ON -DQMC_GPU_ARCHS=pvc \

CMAKE=cmake
CXX=mpicxx CC=icx ${CMAKE} \
  -S ${src_dir} \
  -B ${build_dir} \
  -DENABLE_SYCL=ON \
  -DENABLE_OFFLOAD=ON \
  -DENABLE_OFFLOAD=ON -DQMC_GPU_ARCHS=pvc \
  -DCMAKE_CXX_FLAGS="-mprefer-vector-width=512  -march=sapphirerapids" \
  -DCMAKE_C_FLAGS="-mprefer-vector-width=512  -march=sapphirerapids" \
  -DENABLE_PHDF5=ON \
  -DBoost_INCLUDE_DIR=${LIB_DIR}/boost \
  -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}

${CMAKE} --build ${build_dir} --parallel

#rm -rf transfer.tgz
#tar zcf transfer.tgz transfer ${build_dir}/bin/qmcpack
