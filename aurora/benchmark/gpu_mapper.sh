#!/bin/bash                                                                                                                                      

# Original author: Vikram Narayana (vikram.narayana@intel.com)

LOCAL_RANK_ID=${MPI_LOCALRANKID:-${PALS_LOCAL_RANKID}}
mynode=$(hostname)
export ZE_AFFINITY_MASK=${LOCAL_RANK_ID}
export TMP_LOG=/tmp/${mynode}_qmc_out_rank_${LOCAL_RANK_ID}.txt

#echo 'ZE_AFFINITY_MASK on '`hostname`' for local rank '${LOCAL_RANK_ID}' is '${ZE_AFFINITY_MASK}

# Invoke the main program
$*
