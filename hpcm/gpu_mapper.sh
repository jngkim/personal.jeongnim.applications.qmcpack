#!/bin/bash                                                                                                                                      

# Original author: Vikram Narayana (vikram.narayana@intel.com)

GPU_COUNT=${PLATFORM_NUM_GPU:-6}  # GPUs per node
TILE_PER_GPU=${PLATFORM_NUM_GPU_TILES:-2}

LOCAL_RANK_ID=${MPI_LOCALRANKID:-${PALS_LOCAL_RANKID}}
LOCAL_NRANKS=${MPI_LOCALNRANKS:-${PALS_LOCAL_SIZE}}

MY_GPU=$(( LOCAL_RANK_ID / TILE_PER_GPU ))
MY_TILE_LOCAL=$(( LOCAL_RANK_ID % TILE_PER_GPU ))

export ZE_AFFINITY_MASK=${MY_GPU}.${MY_TILE_LOCAL}

#echo 'ZE_AFFINITY_MASK on '`hostname`' for local rank '${LOCAL_RANK_ID}' is '${ZE_AFFINITY_MASK}

# Invoke the main program
$*
