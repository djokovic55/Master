
#include <stdio.h>
#include <string.h>
#include <cstdlib>
#include <mpi.h>
#include <time.h>

using namespace std;

const int MAX_STRING = 100;

int main (void) {
    char gret[MAX_STRING];
    int csize;
    int prank;

    srand(time(0));

    MPI_Init (NULL,NULL);
    MPI_Comm_size(MPI_COMM_WORLD, &csize);
    MPI_Comm_rank(MPI_COMM_WORLD, &prank);

    if (prank != 0) {
        sprintf (gret , "%d%d" , prank , rand() % 10);
        MPI_Send (gret , strlen ( gret )+1 , MPI_CHAR , 0, 0, MPI_COMM_WORLD);
    } else {
        printf (" Process 0 received: ");
        for ( int q = 1; q < csize ; q ++) {
            MPI_Recv ( gret , MAX_STRING , MPI_CHAR , q , 0,
            MPI_COMM_WORLD , MPI_STATUS_IGNORE );
            printf ("%s " , gret );
        }
        printf ("\n");
    }

    if (prank != 1) {
        sprintf (gret , "%d%d" , prank , rand() % 10);
        MPI_Send (gret , strlen ( gret )+1 , MPI_CHAR , 1, 0, MPI_COMM_WORLD);
    } else {
        printf (" Process 1 received: ");
        for ( int q = 0; q < csize ; q ++) {
            if(q != 1)
            {
                MPI_Recv ( gret , MAX_STRING , MPI_CHAR , q , 0,
                MPI_COMM_WORLD , MPI_STATUS_IGNORE );
                printf ("%s " , gret );
            }
        }
        printf ("\n");
    }

    MPI_Finalize ();
    return 0;
}
