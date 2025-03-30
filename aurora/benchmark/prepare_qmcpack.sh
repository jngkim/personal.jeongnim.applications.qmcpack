#!/bin/bash -l

cd $PBS_O_WORKDIR

build=${BUILD:-intel}
inverse=${INVERSE:-gpu}
save_h5=${SAVE:-no}
omp=${OMP:-8}

nodefile=${NODEFILE:-$PBS_NODEFILE}

job_id=$(echo $PBS_JOBID | cut -d '.' -f 1)
nnodes_avail=$(wc $nodefile| awk '{print $1}')
nnodes=${NNODES:-$nnodes_avail}
job_name=${PBS_JOBNAME:-debug}

qmcpack="/flare/Aurora_deployment/jnkim/qmcpack.workspace/build/$build/bin/qmcpack"
input_main="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.aurora.xml"
input_warmup="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.warmup.xml"
data_dir="\/flare\/Aurora_deployment\/jnkim\/data"

# Create cache directory
TMPHOSTFILE=/tmp/allnodes.start
cat $PBS_NODEFILE |  cut -d '.' -f 1 > $TMPHOSTFILE

rundir=`pwd`/${job_name}.w${job_id}.${build}.n${nnodes}

mkdir -p ${rundir}
cp $nodefile ${rundir}/hostfile

pushd ${rundir}

cat $input_main | sed s/DATA/${data_dir}/ | sed s/OMP/${omp}/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.omp${omp}.xml
echo "Run run qmcpack: source ../execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} ${omp} input.omp${omp}.xml yes"

