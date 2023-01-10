# qmcpack workspace at Intel

## Build and run on Aurora nodes

Build: `source build_aurora_node.sh`
* clone qmcpack internal repository
* set up modules and libraries: set_aurora_env.sh

Interactive run: `./run_aurora_w.sh [ppn=12] [omp=8] [exe=$PWD/build/bin/qmcpack]`

Batch submission example: sbatch_p12x8.sh

## Source and data repository

https://github.com/intel-innersource/applications.hpc.workloads.aurora.qmcpack.git

* aurora-main : sycl::queue per function;  a pool of sycl::queue, one 
* imm-icl-23q1 : recycle immediate command list using copy
* recycle-immcl-opt : imm-icl-23q1 + VGL optimization
