# qmcpack workspace at Intel

## Build and run on Borealis nodes

### Set modules and paths

As 2023-05-05,
```
  module use -a /home/nsdhaman/shared/modulefiles
  module use -a /home/ftartagl/graphics-compute-runtime/modulefiles
  module use -a /home/ftartagl/nightly
  module load gcc
  module unload oneapi
  module load nightly-compiler/2023.04.10
  module load nightly-mkl/2023.03.29
  module load graphics-compute-runtime/ci-neo-master-026097
  # cmake
  export PATH="/home/jeongnim/share/hpcm/ninja-build/bin:/home/jeongnim/share/hpcm/cmake-3.26.3/bin:$PATH"
```
Do not use cmpilers later than 2023.04.10 until notified.

### Build and run Aurora workload

These scrpts [hpcm](hpcm) directory show how to use HPCM environments and oneAPI ENVs
* hpcm/build_aurora_node.sh
* hpcm/launch_interactive.sh
* hpcm/launch_pbs.sh
* hpcm/run_copy_eng_imm.sh

## Source and data repository

https://github.com/intel-innersource/applications.hpc.workloads.aurora.qmcpack.git

* aurora-main branch
