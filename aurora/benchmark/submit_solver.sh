#!/bin/bash -l

cd $PBS_O_WORKDIR

neocache=${NEOCACHE:-no} 
omp=${OMP:-4}
ppn=${PPN:-12}
norb=${NORB:-3072}
blocks=${BLOCKS:-1}

sycl_solver=/flare/Aurora_deployment/jnkim/qmcpack.workspace/build/intel/bin/sycl_solver

nodefile=${NODEFILE:-$PBS_NODEFILE}

job_id=$(echo $PBS_JOBID | cut -d '.' -f 1)
nnodes_avail=$(wc $nodefile| awk '{print $1}')
nnodes=${NNODES:-$nnodes_avail}
job_name=${PBS_JOBNAME:-debug}

export MPIR_CVAR_CH4_XPMEM_ENABLE=0

TMPHOSTFILE=/tmp/allnodes.start
cat $PBS_NODEFILE |  cut -d '.' -f 1 | sort > $TMPHOSTFILE

# Set neo_cache environment
if [ $neocache == "hybrid" ]; then
  export NEO_CACHE_PERSISTENT=1
  export NEO_CACHE_DIR=/tmp/neo_cache_solver
  pdsh -w ^$TMPHOSTFILE "mkdir -p $NEO_CACHE_DIR"
fi

if [ $neocache == "home" ]; then
  export NEO_CACHE_PERSISTENT=1
  echo 'Using ~/.cache/neo_compiler_cache'
  #export NEO_CACHE_DIR=/home/jnkim/.cache/neo_compiler_cache
fi

rundir=`pwd`/sycl_solver/${job_name}.w${job_id}.n${nnodes}.omp${omp}
mkdir -p $rundir

cp $TMPHOSTFILE ${rundir}/hostfile
cp gpu_mapper.sh ${rundir}/
cp execute_solver.sh ${rundir}/

pushd ${rundir}
for iter in {0..2}; do
  source ./execute_solver.sh ${sycl_solver} ${nnodes} ${ppn} ${omp} ${norb} ${blocks} ${iter}
  sleep 5
done
#pdsh -w ^$TMPHOSTFILE "ls /tmp/solver*"
#pdsh -w ^$TMPHOSTFILE "cp -r /tmp/solver* ${rundir}"
#grep "Iter 0" *.out

popd

