# Basic structures
```
int main()
{
 
   MPI_Init();

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