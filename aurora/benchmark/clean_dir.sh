#!/bin/bash
#rundir=$1
#rm -rf ${rundir}/einspline.* ${rundir}/*.h5

for dir in *; do
    # Check if it is a directory
    if [ -d "$dir" ]; then
        rm -rf ${dir}/einspline.* ${dir}/*.h5
    fi
done
