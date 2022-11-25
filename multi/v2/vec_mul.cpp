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
    
    int* vec1 = new int[vec_size];
    int* vec2 = new int[vec_size];
    

    cout<<"******start******"<<endl;
    MPI_Init (&argc , &argv);
    MPI_Comm_size (MPI_COMM_WORLD, &csize);
    MPI_Comm_rank(MPI_COMM_WORLD, &prank);
    
    srand(time(0) + prank);
    
    if(prank == 0)
    {

		int sum_seq = 0;
		int res = 0;

		
		for(int i = 0; i < vec_size; i++)
		{
			vec1[i] = rand() % 10;
			vec2[i] = rand() % 10;
		}

		for(int i = 0; i < vec_size; i++)
		{
			cout<<"Vec1 el "<<i<<"= "<<vec1[i]<<endl;

			sum_seq = vec1[i] * vec2[i];      
			res += sum_seq;
		}

		cout<<"######## Sum seq: "<<res<<endl;

		for(int i = 0; i < vec_size; i++)
		{
			cout<<"Vec2 el "<<i<<"= "<<vec2[i]<<endl;
		}

	
	}
	
	MPI_Bcast(vec1, vec_size, MPI_INT, 0, MPI_COMM_WORLD);
	MPI_Bcast(vec2, vec_size, MPI_INT, 0, MPI_COMM_WORLD);
	
	int step = vec_size / csize;
	int rest = vec_size % csize;

    if(vec_size % csize != 0)
    {
		
	//	if(prank < rest)
			step += 1;
    }
    cout<<"step: "<<step<<endl;
	
    // define block
    int start = prank * step;
    int border = start + step;
    
    int sum = 0;
    cout<<"start: "<<start<< " " << border << " from process: "<<prank<<endl;

	int small_sum = 0;
	while (start < border && start  < vec_size)
    {
    	
        small_sum = vec1[start] * vec2[start];      
		sum += small_sum;

        start += 1;
    }

    cout<<"****************partial sum from p"<<prank<<"= "<<sum<<endl;

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
