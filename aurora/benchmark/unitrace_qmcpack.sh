#!/bin/bash -l

export mynode=$(hostname)
export LOCAL_RANK_ID=${MPI_LOCALRANKID:-${PALS_LOCAL_RANKID}}
export ZE_AFFINITY_MASK=${LOCAL_RANK_ID}

#unitrace -c /flare/Aurora_deployment/jnkim/qmcpack.workspace/build/pinmem/bin/qmcpack input.xml > /tmp/${mynode}_qmc_out_rank${LOCAL_RANK_ID}.txt 2>&1
unitrace -c ./qmcpack input.xml > /tmp/${mynode}_qmc_out_rank${LOCAL_RANK_ID}.txt 2>&1
grep Execution /tmp/${mynode}_qmc_out_rank${LOCAL_RANK_ID}.txt

#wc /tmp/${mynode}_qmc_out_rank${LOCAL_RANK_ID}.txt

no_page_faults=$(grep -nr /tmp/${mynode}_qmc_out_rank${LOCAL_RANK_ID}.txt -e "page fault" | wc -l)
if [ "$no_page_faults" -ne 0 ]
then
  cp /tmp/${mynode}_qmc_out_rank${LOCAL_RANK_ID}.txt /flare/Aurora_deployment/jnkim/qmcpack.workspace/benchmark/traces/
fi
#
