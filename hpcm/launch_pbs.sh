#!/bin/bash
BIND8_S0_OPTIONS="--cpu-bind list:2-9,106-113:10-17,114-121:18-25,122-129:26-33,130-137:34-41,138-145:42-49,146-153"
BIND8_S1_OPTIONS="--cpu-bind list:54-61,158-165:62-69,166-173:70-77,174-181:78-85,182-189:86-93,190-197:94-101,198-205"
BIND8_S2_OPTIONS="--cpu-bind list:2-9,106-113:10-17,114-121:18-25,122-129:26-33,130-137:34-41,138-145:42-49,146-153:54-61,158-165:62-69,166-173:70-77,174-181:78-85,182-189:86-93,190-197:94-101,198-205"

qmcpack=/home/jeongnim/qmcpack.workspace/build_hpcm_c0215/bin/qmcpack
jobname=aus.debug

input=NiO-fcc-S128-dmc.xml
input=input.batch.xml

export GPU_AFFINITY=/home/jeongnim/qmcpack.workspace/hpcm/gpu_mapper.sh

export MPI_BIND_OPTIONS=${BIND8_S2_OPTIONS}

mtag=`date "+%Y%m%d.%H%M"`

#export JOBTAG="${mtag}.neo-025375.n1"

#export NEOReadDebugKeys=1
#export DirectSubmissionRelaxedOrdering=1
#export RebuildPrecompiledKernels=1
#export ForceLargeGrfCompilationMode=1
#export DirectSubmissionControllerTimeout=50000
#export A21_JOBNAME="${mtag}.neo-025716.bd-ooos.n1"


#export LIBOMPTARGET_LEVEL_ZERO_COMMAND_MODE=async

unset NEOReadDebugKeys
unset DirectSubmissionRelaxedOrdering
unset RebuildPrecompiledKernels
unset ForceLargeGrfCompilationMode
unset DirectSubmissionControllerTimeout
export A21_JOBNAME="${mtag}.neo-025716.default-ooos.n1"


RUN_SCRIPT=run_copy_eng_imm.sh

#export LIBOMPTARGET_DEBUG=5

ppn=${1:-12}
omp=${2:-8}

run_dir=${A21_JOBNAME}.p${ppn}x${omp}
mkdir -p ${run_dir}
cp ${input} ${run_dir}/
cp ${RUN_SCRIPT} ${run_dir}
cd ${run_dir}

cat << EOF > myjob.sh
#PBS -S /bin/bash
#PBS -q R830
#PBS -V
#PBS -W block=true
#PBS -l nodes=x1003c1s3b0n0
#PBS -l walltime=00:12:00
#PBS -N helpme
./${RUN_SCRIPT} ${ppn} ${omp} ${qmcpack} ${input}
EOF

qsub myjob.sh

cd -
