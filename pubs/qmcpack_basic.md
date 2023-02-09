# Basic structures
```
int main()
{
 
   MPI_Init();

   int nel = 6144; // number of electrons
   int nspline = nel/2; // number of splines, >= nel/2 in general
   int ngX = 112, ngY = 66, nyZ = 66;
   
   //Allocate bigTables: total allocation = 2*nspline*ngX*ngY*ngZ*sizeof(float|double)
   bigTables.resize(2);
   bigTables[0].allocate(nspline, ngX, ngY, ngZ); 
   bigTables[1].allocate(nspline, ngX, nyY, ngZ);
   //Once bigTables are initialized, they are ready by all the threads, never updated
   
   
   //Allocate many objects that are updated by main algorithms
   vector<Walker, DefaultAlloc> walkers;
   vector<WaveFunction, DefaultAlloc> determinants;
   vector<Hamiltonian, DefaultAlloc> measurements;
   // many other objects
   vector<BsplineTable, BsplineAlloc> bigTables;

   int num_walkers =omp_get_max_threads(); // use the number of host threads
   walkers.resize(num_walkers, ...);
   determinants.resize(num_walkers, ...);
   measurements.resize(num_walkers, ...);

#pragma omp parallel
{
   int ip=omp_get_thread_num();

   for(int e=0; e<nel; ++e)
   {
      walkers[ip].do_something();
      determinants[ip].bspline_vgl(bigTables,....); // compute using bigTables
      determinants[ip].do_something();
      ... //do others
    }
    
    measurements[ip].do_something();
}

MPI_Allreduce(measurements);
}
```