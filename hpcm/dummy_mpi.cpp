#include <mpi.h>
#include <iostream>
int main(int argc, char** argv)
{
  int m_size=1;
  int m_rank=0;
  MPI_Init(&argc, &argv);
  auto m_world = MPI_COMM_WORLD;
  MPI_Comm_rank(m_world, &m_rank);
  MPI_Comm_size(m_world, &m_size);

  std::cout << "My rank " << m_rank << " among " << m_size << std::endl;

  MPI_Finalize();
}
