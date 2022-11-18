
#include <stdio.h>
#include <mpi.h>

using namespace std;

double getInput ()
{
    int res ;
    printf (" Number : " );
    fflush ( stdout );
    scanf ("%d" , &res);
    return double (res);
}
int main ( int argc , char * argv [])
{

    int n;
    double sum = 0;
    int csize, prank;

    MPI_Init (& argc , & argv );
    MPI_Comm_size (MPI_COMM_WORLD, &csize);
    MPI_Comm_rank(MPI_COMM_WORLD, &prank);

    if (prank == 0)
    {
        n = getInput ();
    }

    // MPI_Barrier ( MPI_COMM_WORLD );
    MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
    double s = MPI_Wtime();
    double i = (double) prank;
    double ds = (double) csize;

    int step = n / csize;

    if(n % csize != 0)
    {
    	step += 1;
    }
    cout<<"step: "<<step<<endl;
    int start = i * step;
    int border = start + step;
    
    cout<<"start: "<<start<< " " << border << " from process: "<<prank<<endl;
    
    while (start < border && start  <= n)
    {
        sum += start;      
        start += 1;
    }
	cout<<"sum: "<<sum<<endl<<"from process: "<<prank<<endl;

    double tsum ;
    MPI_Reduce (&sum , &tsum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    double e = MPI_Wtime();
    double d = e - s ;
    double mind ;

    MPI_Reduce (&d , &mind , 1 , MPI_DOUBLE , MPI_MAX , 0, MPI_COMM_WORLD);

    if ( prank == 0)
    {
        printf (" Sum first %d integer is %f \n" , n , tsum );
        printf (" Elapsed time : %f\n " , d );
    }

    MPI_Finalize ();
    return 0;
}
