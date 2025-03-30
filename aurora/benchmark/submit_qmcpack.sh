#!/bin/bash -l
#PBS -A Intel-Punchlist
#PBS -l walltime=20:00
#PBS -l filesystems=home:flare
#PBS -q nre-priority

# using a new mpich
#module unload mpich/opt
#source /lus/flare/projects/Aurora_deployment/servesh/mpich-install/mpich-9f7fd4c/setup.sh

cd $PBS_O_WORKDIR

build=${BUILD:-intel}
inverse=${INVERSE:-gpu}
save_h5=${SAVE:-no}
neocache=${NEOCACHE:-no} #flare, tmp, home, no
ppn=${PPN:-12}
#omp=${OMP:-8}

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

echo "qmcpack=${qmcpack}"
ldd ${qmcpack}
echo

rundir=`pwd`/${job_name}.w${job_id}.${build}.n${nnodes}
TMPHOSTFILE=/tmp/allnodes.start
cat $PBS_NODEFILE |  cut -d '.' -f 1 | sort > $TMPHOSTFILE

mkdir -p ${rundir}
cp $TMPHOSTFILE ${rundir}/hostfile
cp execute_qmcpack.sh ${rundir}/
cp gpu_mapper.sh ${rundir}/

if [[ -n "$PCREDIT" ]]; then
  export ExperimentalH2DCpuCopyThreshold=$PCREDIT
else
  unset ExperimentalH2DCpuCopyThreshold
fi
echo "ExperimentalH2DCpuCopyThreshold="$ExperimentalH2DCpuCopyThreshold

# Set neo_cache environment
if [ $neocache == "tmp" ]; then
  export NEO_CACHE_PERSISTENT=1
  export NEO_CACHE_DIR=/tmp/neo_cache_qmcpack
  pdsh -w ^$TMPHOSTFILE "mkdir -p $NEO_CACHE_DIR"
  pdsh -w ^$TMPHOSTFILE "cd /tmp; tar -zxf ${PBS_O_WORKDIR}/neo_cache_qmcpack.tgz"
  pdsh -w ^$TMPHOSTFILE "diff -qr $NEO_CACHE_DIR ${PBS_O_WORKDIR}/neo_cache_qmcpack"
fi

if [ $neocache == "hybrid" ]; then
  export NEO_CACHE_PERSISTENT=1
  export NEO_CACHE_DIR=/tmp/neo_cache_qmcpack

  #export SYCL_CACHE_PERSISTENT=1
  #export SYCL_CACHE_DIR=/tmp/neo_cache_qmcpack
  pdsh -w ^$TMPHOSTFILE "mkdir -p $NEO_CACHE_DIR"
fi

if [ $neocache == "home" ]; then
  export NEO_CACHE_PERSISTENT=1
  #export SYCL_CACHE_PERSISTENT=1
  echo 'Using ~/.cache/neo_compiler_cache'
  #export NEO_CACHE_DIR=/home/jnkim/.cache/neo_compiler_cache
fi

if [ $neocache == "flare" ]; then
  export NEO_CACHE_PERSISTENT=1
  export NEO_CACHE_DIR=${PBS_O_WORKDIR}/neo_cache_qmcpack
  #export SYCL_CACHE_PERSISTENT=1
  #export SYCL_CACHE_DIR=${PBS_O_WORKDIR}/neo_cache_qmcpack
fi

if [ $neocache == "no" ]; then
  unset NEO_CACHE_PERSISTENT
fi

pushd ${rundir}


## warmup run
#cat $input_warmup | sed s/DATA/${data_dir}/ | sed s/OMP/4/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.warmup.xml
#source ./execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} 4 input.warmup.xml no
#mv qmcpack.out qmcpack.warmup.out

#ls $NEO_CACHE_DIR


count=1
for omp in 8;
do
  cat $input_main | sed s/DATA/${data_dir}/ | sed s/OMP/${omp}/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.omp${omp}.xml
echo "start time: `date`"
  source ./execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} ${omp} input.omp${omp}.xml yes
echo "end time: `date`"
  sleep 2
  if [ $neocache == "hybrid" ]; then
    echo "NEO_CACHE_DIR"
    cp -r $NEO_CACHE_DIR ./
  fi
  mv qmcpack.out qmcpack.${count}.omp${omp}.out
  count=$((count+1))
done
#
