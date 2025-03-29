#!/bin/bash                                                                                                                                      

# Original author: Vikram Narayana (vikram.narayana@intel.com)

export ZE_AFFINITY_MASK=${MPI_LOCALRANKID}
#echo 'ZE_AFFINITY_MASK on '`hostname`' for local rank '${MPI_LOCALRANKID}' is '${ZE_AFFINITY_MASK}

# Invoke the main program
$*
