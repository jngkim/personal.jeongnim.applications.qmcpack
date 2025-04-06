#!/bin/bash

export I_MPI_CXX=icpx
export I_MPI_CC=icx

src_dir=/nfs/site/home/jeongnim/workspace/GitHub/miniqmc
build_dir=miniqmc

CXX=mpicxx CC=icx cmake -S ${src_dir} -B ${build_dir} \
  -DQMC_MIXED_PRECISION=ON -DENABLE_OFFLOAD=ON -DENABLE_SYCL=ON \
  -DCMAKE_CXX_FLAGS="-g -mprefer-vector-width=512 "\
  -DCMAKE_C_FLAGS="-g -mprefer-vector-width=512 " 

