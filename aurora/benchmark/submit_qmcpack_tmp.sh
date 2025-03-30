#!/bin/bash -l

cd $PBS_O_WORKDIR

build=${BUILD:-intel}
inverse=${INVERSE:-gpu}
save_h5=${SAVE:-no}
#omp=${OMP:-8}

nodefile=${NODEFILE:-$PBS_NODEFILE}

job_id=$(echo $PBS_JOBID | cut -d '.' -f 1)
nnodes_avail=$(wc $nodefile| awk '{print $1}')
nnodes=${NNODES:-$nnodes_avail}
job_name=${PBS_JOBNAME:-debug}

qmcpack="/flare/Aurora_deployment/jnkim/qmcpack.workspace/build/$build/bin/qmcpack"
input_main="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.aurora.xml"
input_warmup="/flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/input.warmup.xml"
data_dir="\/flare\/Aurora_deployment\/jnkim\/data"

TMPHOSTFILE=/tmp/allnodes.start
cat $PBS_NODEFILE |  cut -d '.' -f 1 > $TMPHOSTFILE
rundir=/tmp/qmcpack
pdsh -w ^$TMPHOSTFILE "mkdir -p $rundir"
pdcp -w ^$TMPHOSTFILE gpu_mapper.sh $rundir/
pdcp -w ^$TMPHOSTFILE execute_qmcpack.sh $rundir/

export NEO_CACHE_PERSISTENT=1

outdir=$PBS_O_WORKDIR/${job_name}.w${job_id}.${build}.n${nnodes}
mkdir -p ${outdir}
cp $TMPHOSTFILE ${outdir}/allnodes.start

pdcp -w ^$TMPHOSTFILE ${nodefile} $rundir/hostfile

pushd ${rundir}
#
ppn=12
cat $input_warmup | sed s/DATA/${data_dir}/ | sed s/OMP/4/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.warmup.xml
pdcp -w ^$TMPHOSTFILE input.warmup.xml ${rundir}/

source ./execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} 4 input.warmup.xml no
mv qmcpack.out ${outdir}/qmcpack.warmup.out

for omp in 4 6 8;
do
  sleep 10
  cat $input_main | sed s/DATA/${data_dir}/ | sed s/OMP/${omp}/  | sed s/SAVE/${save_h5}/ | sed s/INVERSE/${inverse}/ > ./input.omp${omp}.xml
  pdcp -w ^$TMPHOSTFILE input.omp${omp}.xml ${rundir}/

  source ./execute_qmcpack.sh ${qmcpack} ${nnodes} ${ppn} ${omp} input.omp${omp}.xml yes

  mv qmcpack.out ${outdir}/qmcpack.omp${omp}.out
  mv NiO-fcc-S128-dmc.info.xml ${outdir}/NiO-fcc-S128-dmc.omp${omp}.info.xml
done

