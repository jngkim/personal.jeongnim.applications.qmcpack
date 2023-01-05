OMP_NUM_THREADS=48 mpirun \
-np 1 --bind-to socket numactl --preferred=2 ./qmcpack NiO-fcc-S128-dmc.xml : \
-np 1 numactl --preferred=3 ./qmcpack NiO-fcc-S128-dmc.xml
