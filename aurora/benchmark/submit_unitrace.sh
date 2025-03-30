#!/bin/bash -l
#PBS -A Intel-Punchlist
#PBS -l walltime=15:00
#PBS -l filesystems=home:flare
#PBS -q nre-priority

ml load pti-gpu/d3639de

cd $PBS_O_WORKDIR

build=${BUILD:-intel}
inverse=${INVERSE:-gpu}
save_h5=${SAVE:-no}
ppn=${PPN:-12}
omp=${OMP:-8}

nodefile=${NODEFILE:-$PBS_NODEFILE}

job_id=$(echo $PBS_JOBID | cut -d '.' -f 1)
nnodes_avail=$(wc $nodefile| awk '{print $1}')
nnodes=${NNODES:-$nnodes_avail}
job_name=${PBS_JOBNAME:-debug}

qmcpack="/flare/Aurora_deployment/jnkim/qmcpack.workspace/build/$build/bin/qmcpack"
input_main="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.aurora.xml"
input_warmup="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.warmup.xml"
input_long="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.long.xml"
data_dir="\/flare\/Aurora_deployment\/jnkim\/data"

rundir=`pwd`/${job_name}.w${job_id}.${build}.n${nnodes}
TMPHOSTFILE=/tmp/allnodes.start
cat $PBS_NODEFILE |  cut -d '.' -f 1 | sort > $TMPHOSTFILE

if [[ -n "$PCREDIT" ]]; then
  export ExperimentalH2DCpuCopyThreshold=$PCREDIT
else
  unset ExperimentalH2DCpuCopyThreshold
fi
echo "ExperimentalH2DCpuCopyThreshold="$ExperimentalH2DCpuCopyThreshold

# prepare run directory
mkdir -p ${rundir}
cp $TMPHOSTFILE ${rundir}/hostfile
cp unitrace_qmcpack.sh ${rundir}/

pushd ${rundir}
ln -s $qmcpack qmcpack

cat $input_main | sed s/DATA/${data_dir}/ | sed s/OMP/${omp}/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.xml
#source ./unitrace_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} ${omp} input.omp${omp}.xml yes

echo "Running ${qmcpack}"
echo "nodes,ppn,omp: $nnodes $ppn $omp"
echo "ExperimentalH2DCpuCopyThreshold=$ExperimentalH2DCpuCopyThreshold"
echo "NEO_CACHE_PERSISTENT=$NEO_CACHE_PERSISTENT"
echo "NEO_CACHE_DIR=$NEO_CACHE_DIR"

#################################
# Setting environments
#################################
export NEOReadDebugKeys=1
export SplitBcsCopy=0

# debugging keys
export PrintDebugSettings=1
export LogAllocationMemoryPool=1
export LogAllocationStdout=1
export LogAllocationType=1
export PrintBOBindingResult=1
export PrintBOCreateDestroyResult=1

export KMP_BLOCKTIME=0
export OMP_PLACES=cores
export OMP_PROC_BIND=spread
export HYDRA_TOPO_DEBUG=1

export PALS_PMI=pmix
export MPIR_CVAR_ENABLE_GPU=0
unset MPIR_CVAR_CH4_COLL_SELECTION_TUNING_JSON_FILE 
unset MPIR_CVAR_COLL_SELECTION_TUNING_JSON_FILE 
unset MPIR_CVAR_CH4_POSIX_COLL_SELECTION_TUNING_JSON_FILE
export FI_CXI_DEFAULT_CQ_SIZE=131072
export FI_CXI_CQ_FILL_PERCENT=20
export MPIR_CVAR_CH4_XPMEM_ENABLE=0
export MPIR_CVAR_CH4_ROOTS_ONLY_PMI=1
export MPIR_CVAR_INIT_SKIP_PMI_BARRIER=0

export OMP_TARGET_OFFLOAD=MANDATORY
export LIBOMPTARGET_PLUGIN=LEVEL0
export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

export ONEAPI_DEVICE_SELECTOR=level_zero:gpu
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1

export LIBOMPTARGET_LEVEL_ZERO_COMPILATION_OPTIONS="-ze-opt-large-register-file"
export SYCL_PROGRAM_COMPILE_OPTIONS="-ze-opt-large-register-file"

export LIBOMPTARGET_LEVEL_ZERO_COMMAND_MODE=sync
export ZE_FLAT_DEVICE_HIERARCHY=FLAT
#export SYCL_CACHE_PERSISTENT=1

#export CPU_BIND=list:1-8,105-112:9-16,113-120:17-24,121-128:27-34,131-138:35-42,139-146:43-50,147-154:53-60,157-164:61-68,165-172:69-76,173-180:79-86,183-190:87-94,191-198:95-102,199-206
export CPU_BIND=list:1-8:9-16:17-24:27-34:35-42:43-50:53-60:61-68:69-76:79-86:87-94:95-102
#
#
mpi=$(( ppn * nnodes ))
export OMP_NUM_THREADS=${omp}
mpiexec --hostfile hostfile -np ${mpi} -ppn ${ppn} --cpu-bind $CPU_BIND ./unitrace_qmcpack.sh
