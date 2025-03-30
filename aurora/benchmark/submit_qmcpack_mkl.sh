#!/bin/bash -l

# Testing the impact of shared linraries
# copy mkl libraries to /tmp/transfer
cd $PBS_O_WORKDIR

build=${BUILD:-intel}
inverse=${INVERSE:-gpu}
save_h5=${SAVE:-no}
neocache=${NEOCACHE:-home} #flare, tmp, home, no
#omp=${OMP:-8}

nodefile=${NODEFILE:-$PBS_NODEFILE}

job_id=$(echo $PBS_JOBID | cut -d '.' -f 1)
nnodes_avail=$(wc $nodefile| awk '{print $1}')
nnodes=${NNODES:-$nnodes_avail}
job_name=${PBS_JOBNAME:-debug}

#qmcpack="/flare/Aurora_deployment/jnkim/qmcpack.workspace/build/$build/bin/qmcpack"
export qmcpack="/tmp/transfer/qmcpack"
input_main="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.aurora.xml"
input_warmup="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.warmup.xml"
data_dir="\/flare\/Aurora_deployment\/jnkim\/data"

rundir=`pwd`/${job_name}.w${job_id}.${build}.n${nnodes}
TMPHOSTFILE=/tmp/allnodes.start
cat $PBS_NODEFILE |  cut -d '.' -f 1 | sort > $TMPHOSTFILE

mtag=$(date "+%Y-%m-%dT%H:%M:%S")

ALLNODES=$(nodeset -f $(sed -e 's,[.].*,,'  $PBS_NODEFILE))
timeout 120 mpiexec -np $nnodes -ppn 1 --hostfile $TMPHOSTFILE --no-abort-on-failure /flare/Aurora_deployment/intel/mpi_copy/broadcast_file transfer.tgz /tmp

ALLNODES=$(pdsh -w $ALLNODES -f 128 -u 60 'cat /tmp/transfer.tgz | wc -c' | grep $FILESIZE | sed -e 's,:.*,,')
test -n "$ALLNODES" && ALLNODES=$(nodeset -f $ALLNODES)

timeout 900  mpiexec -np $nnodes -ppn 1 --hostfile $TMPHOSTFILE --no-abort-on-failure /bin/bash -c "cd /tmp; test -e  transfer && rm -rf transfer; tar xzf transfer.tgz; ls /tmp/transfer"

#export LD_LIBRARY_PATH="/tmp/transfer:$LD_LIBRARY_PATH"
#
export LD_LIBRARY_PATH=/tmp/transfer:/opt/aurora/24.180.3/spack/unified/0.8.0/install/linux-sles15-x86_64/oneapi-2024.07.30.002/lib:/opt/aurora/24.180.3/updates/oneapi/compiler/eng-20240629/lib:/opt/aurora/24.180.3/spack/unified/0.8.0/install/linux-sles15-x86_64/gcc-12.2.0/gcc-12.2.0-zt4lle2/lib64:/opt/aurora/24.180.3/updates/oneapi/compiler/eng-20240629/lib:/opt/aurora/24.180.3/spack/unified/0.8.0/install/linux-sles15-x86_64/oneapi-2024.07.30.002/hwloc-master-git.1793e43-bqjeblt/lib:/opt/aurora/24.180.3/spack/unified/0.8.0/install/linux-sles15-x86_64/oneapi-2024.07.30.002/yaksa-0.3-aw2kkvy/lib:/opt/cray/libfabric/1.20.1/lib64:/opt/aurora/24.180.3/spack/unified/0.8.0/install/gcc_bootstrap/linux-sles15-x86_64/gcc-7.5.0/gcc-12.2.0-5ieouwtcwrrwan33k5itbqrsrom7cjrh/lib64:/opt/aurora/24.180.3/updates/oneapi/compiler/eng-20240629/lib:/opt/aurora/24.180.3/support/libraries/khronos/default/lib64

#ldd /tmp/transfer/qmcpack

mkdir -p ${rundir}
cp $TMPHOSTFILE ${rundir}/hostfile
cp execute_qmcpack.sh ${rundir}/
cp gpu_mapper.sh ${rundir}/

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
  pdsh -w ^$TMPHOSTFILE "mkdir -p $NEO_CACHE_DIR"
fi

if [ $neocache == "home" ]; then
  export NEO_CACHE_PERSISTENT=1
  echo 'Using ~/.cache/neo_compiler_cache'
  #export NEO_CACHE_DIR=/home/jnkim/.cache/neo_compiler_cache
fi

if [ $neocache == "flare" ]; then
  export NEO_CACHE_PERSISTENT=1
  export NEO_CACHE_DIR=${PBS_O_WORKDIR}/neo_cache_qmcpack
fi


pushd ${rundir}

ppn=12

##warmup run
#cat $input_warmup | sed s/DATA/${data_dir}/ | sed s/OMP/4/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.warmup.xml
#source ./execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} 4 input.warmup.xml no
#mv qmcpack.out qmcpack.warmup.out

#ls $NEO_CACHE_DIR

for omp in 4 6 8;
do
  cat $input_main | sed s/DATA/${data_dir}/ | sed s/OMP/${omp}/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.omp${omp}.xml
  source ./execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} ${omp} input.omp${omp}.xml yes
  sleep 2
  if [ $neocache == "hybrid" ]; then
    echo "NEO_CACHE_DIR"
    cp -r $NEO_CACHE_DIR ./
  fi
  mv qmcpack.out qmcpack.omp${omp}.out
done
#
