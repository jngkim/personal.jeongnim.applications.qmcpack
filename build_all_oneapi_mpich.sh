#!/bin/bash

INSTALL_DIR=$topdir/share

build_hdf5() {

  if [ ! -d "hdf5" ] ; then
    git clone -b hdf5-1_14_0 https://github.com/HDFGroup/hdf5.git
  fi

  cmake -S hdf5 \
    -B build/hdf5 \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
    -DBUILD_TESTS=OFF \
    -DHDF5_BUILD_CPP_LIB=OFF \
    -DHDF5_ENABLE_PARALLEL=ON \
    -DCMAKE_C_COMPILER=mpicc 

  cmake --build build/hdf5 --parallel
  cmake --build build/hdf5 --target install
}

build_libxml2() {
  if [ ! -d "libxml2" ] ; then
    git clone https://github.com/GNOME/libxml2.git
  fi

  cmake -S libxml2 \
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

