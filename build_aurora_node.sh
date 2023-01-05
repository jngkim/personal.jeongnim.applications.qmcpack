#!/bin/bash

qmcpack_home=qmcpack.intel
src_dir=${qmcpack_home}/qmcpack.src
build_dir=build
hdf5_root=/home/sys_seth/hpval/qmcpack/hdf5/v1.13.0/install
run_dir=a21-bench

if [ ! -d "$qmcpack_home" ] ; then
  git clone -b aurora-main https://github.com/intel-innersource/applications.hpc.workloads.aurora.qmcpack.git qmcpack.intel
fi

if [[ -z ${QMCPACK_ENV} ]];then
  source set_aurora_env.sh
else
  echo "QMCPACK env is set"
fi

if [ ! -f "a21-bench/NiO-fcc-supertwist111-supershift000-S128.h5" ]; then
  ln -s /home/sys_seth/hpval/qmcpack/NiO-fcc-supertwist111-supershift000-S128.h5 ${run_dir}/
fi

CXX=mpicxx CC=icx cmake \
  -S ${src_dir} \
  -B ${build_dir} \
  -DENABLE_OFFLOAD=ON -DOFFLOAD_TARGET=spir64 \
  -DENABLE_SYCL=ON \
  -DCMAKE_CXX_FLAGS="-cxx=icpx -mprefer-vector-width=512 -march=sapphirerapids " \
  -DCMAKE_C_FLAGS="-mprefer-vector-width=512  -march=sapphirerapids" \
  -DSYCL_INCLUDE_DIR=${CMPLR_ROOT}/linux/include \
  -DSYCL_LIBRARY_DIR=${CMPLR_ROOT}/linux/lib \
  -DCMAKE_EXE_LINKER_FLAGS:STRING="-lsycl -lOpenCL" \
  -DHDF5_ROOT=${hdf5_root} \
  -DUSE_VTUNE_A21=OFF \
  -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}

cmake --build ${build_dir} --parallel
#
