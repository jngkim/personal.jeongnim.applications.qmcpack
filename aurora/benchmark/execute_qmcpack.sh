#!/bin/bash -l

qmcpack=$1
nnodes=$2
ppn=$3
omp=$4
input=$5
fom=$6

mpi=$(( ppn * nnodes ))

echo "Running ${qmcpack}"
echo "nodes,ppn,omp: $nnodes $ppn $omp"
echo "ExperimentalH2DCpuCopyThreshold=$ExperimentalH2DCpuCopyThreshold"
echo "NEO_CACHE_PERSISTENT=$NEO_CACHE_PERSISTENT"
echo "NEO_CACHE_DIR=$NEO_CACHE_DIR"

#################################
# Running qmcpack Aurora SOW workload
#################################
#input=input.xml

export NEOReadDebugKeys=1
export SplitBcsCopy=0
#Add 2025-03-12
#export ExperimentalH2DCpuCopyThreshold=50000
#export UR_L0_SERIALIZE=2
#export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1 
#export SYCL_PI_LEVEL_ZERO_USE_COPY_ENGINE=0:0

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
#Add 2025-03-12
export FI_CXI_CQ_FILL_PERCENT=20
export MPIR_CVAR_CH4_XPMEM_ENABLE=0

#LAMMPS debug session
export MPIR_CVAR_CH4_ROOTS_ONLY_PMI=1
export MPIR_CVAR_INIT_SKIP_PMI_BARRIER=0

# Questionable envs
#export FI_MR_CACHE_MONITOR=disabled
#export FI_MR_ZE_CACHE_MONITOR_ENABLED=0
#export FI_CXI_RX_MATCH_MODE=hybrid

export OMP_TARGET_OFFLOAD=MANDATORY
export LIBOMPTARGET_PLUGIN=LEVEL0
export LIBOMP_USE_HIDDEN_HELPER_TASK=0
export LIBOMP_NUM_HIDDEN_HELPER_THREADS=0

export ONEAPI_DEVICE_SELECTOR=level_zero:gpu
#export ZEX_NUMBER_OF_CCS=0:1,1:1,2:1,3:1,4:1,5:1,6:1,7:1,8:1,9:1,10:1,11:1
#export ZEX_NUMBER_OF_CCS=0:4,1:4,2:4,3:4,4:4,5:4,6:4,7:4,8:4,9:4,10:4,11:4
export ZE_ENABLE_PCI_ID_DEVICE_ORDER=1

export LIBOMPTARGET_LEVEL_ZERO_COMPILATION_OPTIONS="-ze-opt-large-register-file"
export SYCL_PROGRAM_COMPILE_OPTIONS="-ze-opt-large-register-file"

export LIBOMPTARGET_LEVEL_ZERO_COMMAND_MODE=sync
export ZE_FLAT_DEVICE_HIERARCHY=FLAT
#export SYCL_CACHE_PERSISTENT=1

#export MPI_BIND_OPTIONS="--cpu-bind list:1-8,105-112:9-16,113-120:17-24,121-128:27-34,131-138:35-42,139-146:43-50,147-154:53-60,157-164:61-68,165-172:69-76,173-180:79-86,183-190:87-94,191-198:95-102,199-206"
export MPI_BIND_OPTIONS="--cpu-bind list:1-8:9-16:17-24:27-34:35-42:43-50:53-60:61-68:69-76:79-86:87-94:95-102"

MY_LOG=qmcpack.out
#timeout 330 mpiexec --hostfile hostfile \
mpiexec -l --hostfile hostfile \
  -np ${mpi} -ppn 12 --pmi=pmix -genv OMP_NUM_THREADS=${omp} $MPI_BIND_OPTIONS \
  ./gpu_mapper.sh \
  ${qmcpack} ${input} \
  --enable-timers=fine | tee ${MY_LOG} 

#  --enable-timers=fine > ${MY_LOG} 2>&1

#grep Execution ${MY_LOG}

if [ $fom == "yes" ]; then
  tt=$(grep "DMCBatched::Production" ${MY_LOG} | awk '{print $2}')
  echo $nnodes $omp $tt | awk '{print "FOM", 0.05435817984 * 8192 * $2 / $3,"FOM_"$1"_"$2, 0.05435817984 * $1 * $2 / $3, "time",$3}' 
fi

##save output
#outdir=${logdir}/n${nnodes}.o${omp}.${mtag}
#mkdir -p ${outdir}
#mv ${MY_LOG} ${outdir}/
#mv NiO-fcc-S128-dmc.s003.cont.xml ${outdir}/
#mv hostfile ${outdir}/
#rm -rf NiO-fcc-S128-dmc.s0* NiO-fcc-S128-dmc.info.xml einspline.tile*
