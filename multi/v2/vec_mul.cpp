#include <stdio.h>
#include <mpi.h>
#include <vector>
#include <time.h>
#include <cstdlib>

using namespace std;

int main (int argc , char * argv [])
{

    int csize, prank;
    
    int vec_size = atoi(argv[1]);
    
    vector<int> vec1;
    vector<int> vec2;
    
    
    int* p1;
	int* p2;
    

    MPI_Init (&argc , &argv);
    MPI_Comm_size (MPI_COMM_WORLD, &csize);
    MPI_Comm_rank(MPI_COMM_WORLD, &prank);
    
    srand(time(0) + prank);
    
    if(prank == 0)
    {
		for(int i = 0; i < vec_size; i++)
		{
			vec1.push_back(rand() % 10);
			vec2.push_back(rand() % 10);
    	}
    	p1 = vec1.data();
		p2 = vec2.data();
	}
	
	
	MPI_Bcast(p1, vec_size, MPI_INT, 0, MPI_COMM_WORLD);
	MPI_Bcast(p2, vec_size, MPI_INT, 0, MPI_COMM_WORLD);


	int step = vec_size / csize;

    if(vec_size % csize != 0)
    {
    	if(prank < vec_size % csize)
    		step += 1;
    }
    //cout<<"step: "<<step<<endl;
    
    int start = prank * step;
    int border = start + step;
    
    int sum;
    //cout<<"start: "<<start<< " " << border << " from process: "<<prank<<endl;
    while (start < border && start  < vec_size)
    {
    	
        //sum = vec1.at(start) * vec2.at(start);      
        start += 1;
    }

    // MPI_Barrier ( MPI_COMM_WORLD );
   


    int tsum ;
    MPI_Reduce (&sum , &tsum, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
 

    if ( prank == 0)
    {
        printf (" Sum first %d integer is %d \n" , vec_size , tsum );
    }

    MPI_Finalize ();
    return 0;
}
