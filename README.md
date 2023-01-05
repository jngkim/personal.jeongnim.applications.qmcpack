# qmcpack workspace at Intel

## Build and run on Aurora nodes

Build: `source build_aurora_node.sh`
* clone qmcpack internal repository
* set up modules and libraries: set_aurora_env.sh

Interactive run: run_aurora_w.sh [ppn=12] [omp=8]

Batch submission example: sbatch_p12x8.sh
* Execute: run_aurora_w.sh 12 8
