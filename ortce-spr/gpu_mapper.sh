#!/bin/bash                                                                                                                                      

# Original author: Vikram Narayana (vikram.narayana@intel.com)

GPU_COUNT=${PLATFORM_NUM_GPU:-6}  # GPUs per node
TILE_PER_GPU=${PLATFORM_NUM_GPU_TILES:-2}

TILE_COUNT=$(( GPU_COUNT * TILE_PER_GPU ))
MY_TILE_GLOBAL=$(( MPI_LOCALRANKID % TILE_COUNT ))
MY_GPU=$(( MY_TILE_GLOBAL / TILE_PER_GPU ))
MY_TILE_LOCAL=$(( MY_TILE_GLOBAL % TILE_PER_GPU ))

export ZE_AFFINITY_MASK=${MY_GPU}.${MY_TILE_LOCAL}

echo 'ZE_AFFINITY_MASK on '`hostname`' for local rank '${MPI_LOCALRANKID}' is '${ZE_AFFINITY_MASK}

# Invoke the main program
$*
