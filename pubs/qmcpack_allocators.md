# Problem statement

* How to use HBM effectively with offloads on PVC?
* How to use HBM effectively without PVC?
* How to generalize the allocation policy on super nodes (multi-socket and multi-device nodes) for larger problems demanding more memory?

Constraints

Large-scale code modifications are not desired. Specialized allocators for target objects are used for explorations and the solutions must provide the portability for productivity and performance improvement.

## Basic structure of QMCPACK: allocations and computations

[miniqmc](https://github.com/intel-innersource/applications.hpc.workloads.aurora.miniqmc/blob/main/src/Drivers/miniqmc.cpp) captures the core elements and is a model application for the new implementations.

```
int main()
{
 
   MPI_Init();
   
   //problem size of Aurora workload
   int nel = 6144; // number of electrons
   int nspline = nel/2; // number of splines, >= nel/2
   int ngX = 112, ngY = 66, nyZ = 66;
   
   //1. Per process allocation 
   //bigTables: total allocation = 2*nspline*ngX*ngY*ngZ*sizeof(float|double)
   vector<BsplineTable, BsplineAlloc> bigTables;
   bigTables.resize(2);
   bigTables[0].allocate(nspline, ngX, ngY, ngZ); 
   bigTables[1].allocate(nspline, ngX, nyY, ngZ);
   //Once bigTables are initialized, they are ready by all the threads, never updated
   
   
   //2. Per thread allocation
   //many objects that are updated by main algorithms
   vector<Walker, DefaultAlloc> walkers;
   vector<WaveFunction, DefaultAlloc> determinants;
   vector<Hamiltonian, DefaultAlloc> measurements;
   // many other objects
  
   int num_walkers =omp_get_max_threads(); // use the number of host threads
   walkers.resize(num_walkers, ...);
   determinants.resize(num_walkers, ...);
   measurements.resize(num_walkers, ...);

for(int step=0; step < many_steps; step++)
{
#pragma omp parallel for
for(int iw=0; iw < num_walkers; ++iw)
{
   for(int e=0; e<nel; ++e)
   {
      walkers[iw].do_something();
      determinants[iw].bspline_vgl(bigTables,....); // compute using bigTables
      determinants[iw].do_something();
      ... //do others
   }
    
   measurements[iw].do_something();
} // iw

MPI_Allreduce(measurements);

} // step

MPI_Finalize();
}
```
## Main workload characteristics

We use Aurora node configurations with 6 PVCs (12 tiles) and map 1 MPI rank on a tile and 8 host threads for the problem descriptions.

Memory use in GB per socket

|                    |  NiO-a512| NiO-a1024| NiO-defect |
|--------------------| ---:| ---:| ---:|
| bigTables          |  14 |   28| 112 |
| per thread objects |   1 |    4|   1 |
| Per rank           |  22 |   60| 128 |
| 6 ranks per socket | 132 |  360| 720 |

The two workloads, NiO-a512 and NiO-a1024, are among the QMCPACK ECP NiO benchmark suite problems. NiO-a512 is the Aurora acceptance workload and improving its performance on SPR+HBM is the primary target. NiO-defect is a grand-challenge problem for QMC: the number of electrons is the same as NiO-a512 but the size of bigTables is increased by 8x.

Based on the memory requirements, the current parallelization for optimal computations is not a good solution for NiO-a1024 and NiO-defect; fundamental changes QMCPACK are needed and will be our next target. 

## Aurora workload (NiO-a512) on Aurora systems

### What are the problems with SPR+HBM?

* SPR+HBM parts run at lower frequency than SPR+DDR due to power limit and bad for latency and L2-bound Aurora workload
* cache/quad BW increase has no impact on the performance.
* flat/quad is the only option but can use only DDR: 6 ranks do not fit to 64 GB HBM per socket

How to better use HBM flat/quad mode with minimum changes in QMCPACK?

### Option 1: bigTables on DDR and everything else on HBM

In theory, this can be achieved with the combination of numactl and OpenMP allocator in omp_large_cap_mem_space as BsplineAlloc.
Assuming flat/quad mode, DefaultAlloc will use the local HBM numa-node  2 or 3 depending on the MPI rank if we use 

```
mpirun -np 1 numactl -p 2 qmcpack : # rank  0 on socket 0
       -np 1 numactl -p 2 qmcpack : # rank  1 on socket 0
      ...
       -np 1 numactl -p 2 qmcpack : # rank  5 on socket 0
       -np 1 numactl -p 3 qmcpack : # rank  6 on socket 1
       -np 1 numactl -p 3 qmcpack : # rank  7 on socket 1
      ...
       -np 1 numactl -p 3 qmcpack   # rank 11 on socket 1
```
This requires OpenMP to use memkind library and the user has to provide a proper link to the right memkind build. Limited evaluations reveal that numactl, MPI and OpenMP are not working consistently for the simple solution. The example above used `numactl -p node_id` because MPICH does not work with `-m node_id`. Exposing numactl is not good for general users and we want the solution to be completely internal and is managed by OpenMP RT and leverage hwloc/memkind.

### Option 2: share bigTables among the MPI ranks on the same socket

This will reduce the total memory use to 62 GB = 14 + 48 per socket. Since
bigTables are read-only after construction, using MPI shared allocator is
expected to add overhead and gives lower performance. nmap is another method
but a shared-memory allocator is preferred.

### Option 3: use 1 MPI rank per socket and manage 48 threads

This is a general solution to deal with multiple GPUs in a process and will be
pursued in the context of distributed data structure.
