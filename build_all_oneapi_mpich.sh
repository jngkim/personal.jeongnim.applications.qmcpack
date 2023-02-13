#!/bin/bash

topdir=`pwd`
INSTALL_DIR=$topdir/share
BOOST_DIR=$topdir/external
qmcpack_home=qmcpack.intel

mtag=`date "+%Y%m%d.%H%M"`

if [ ! -d "$qmcpack_home" ] ; then
  git clone -b aurora-main https://github.com/intel-innersource/applications.hpc.workloads.aurora.qmcpack.git qmcpack.intel
fi

if [ ! -d "external/hdf5" ] ; then
  git clone -b hdf5-1_14_0 https://github.com/HDFGroup/hdf5.git external/hdf5
fi

if [ ! -d "external/libxml2" ] ; then
  git clone https://github.com/GNOME/libxml2.git external/libxml2
fi

build_hdf5() {

  CC=icx cmake -S external/hdf5 \
    -B build/hdf5 \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_TESTS=OFF \
    -DHDF5_BUILD_CPP_LIB=OFF 

  cmake --build build/hdf5 --parallel
  cmake --build build/hdf5 --target install
}

#parallel hdf5 not working on ortce
build_phdf5() {

  CC=mpicc cmake -S external/hdf5 \
    -B build/hdf5 \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_TESTS=OFF \
    -DHDF5_BUILD_CPP_LIB=OFF \
    -DHDF5_ENABLE_PARALLEL=ON 

  cmake --build build/hdf5 --parallel
  cmake --build build/hdf5 --target install
}

build_libxml2() {

  cmake -S external/libxml2 \
    -B build/libxml2 \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DCMAKE_C_COMPILER=icx \
    -DCMAKE_CXX_COMPILER=icpx \
    -DLIBXML2_WITH_ZLIB=OFF \
    -DLIBXML2_WITH_LZMA=OFF \
    -DLIBXML2_WITH_PYTHON=OFF\
    -DLIBXML2_WITH_TESTS=OFF

  cmake --build build/libxml2 --parallel
  cmake --build build/libxml2 --target install
}

build_qmcpack_cpu() {

  src_dir=${qmcpack_home}/qmcpack.src
  build_dir=build_cpu

  CXX=mpicxx CC=icx cmake \
    -S ${src_dir} \
    -B ${build_dir} \
    -DCMAKE_CXX_FLAGS="-cxx=icpx -mprefer-vector-width=512 -march=sapphirerapids " \
    -DCMAKE_C_FLAGS="-mprefer-vector-width=512 -march=sapphirerapids " \
    -DHDF5_ROOT=${INSTALL_DIR} \
    -DLibXml2_ROOT=${INSTALL_DIR} \
    -DBoost_INCLUDE_DIR=${BOOST_DIR} \
    -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}

  cmake --build ${build_dir} --parallel

}


build_qmcpack_gpu() {

  src_dir=${qmcpack_home}/qmcpack.src
  build_dir=build_gpu

  CXX=mpicxx CC=icx cmake \
    -S ${src_dir} \
    -B ${build_dir} \
    -DCMAKE_CXX_FLAGS="-cxx=icpx -mprefer-vector-width=512 -march=sapphirerapids " \
    -DCMAKE_C_FLAGS="-mprefer-vector-width=512 -march=sapphirerapids " \
    -DHDF5_ROOT=${INSTALL_DIR} \
    -DLibXml2_ROOT=${INSTALL_DIR} \
    -DBoost_INCLUDE_DIR=${BOOST_DIR} \
    -DENABLE_OFFLOAD=ON -DOFFLOAD_TARGET=spir64 -DENABLE_SYCL=ON \
    -DQMC_MIXED_PRECISION=ON 2>&1 | tee ${log_file}

  cmake --build ${build_dir} --parallel

}

build_hdf5 
build_libxml2
build_qmcpack_gpu
