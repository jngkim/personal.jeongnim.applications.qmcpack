module use -a /home/nsdhaman/shared/modulefiles
module use -a /home/ftartagl/graphics-compute-runtime/modulefiles
module use -a /home/ftartagl/nightly
module use -a /home/ftartagl/modulefiles

module unload oneapi
module load nightly-compiler/2023.01.03
source /home/ftartagl/oneapi_install/patches/mkl/l_onemkl_p_2023.0.0.24152/env/vars.sh
module load graphics-compute-runtime/agama-ci-devel-549
module load gnu9/9.3.0

export QMCPACK_ENV=1
