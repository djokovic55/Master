#include<stdio.h>
#include<mpi.h>
int returnSize (char* fname)
{
    FILE* f = fopen(fname ,"r" );
    int dim = 0;
    double tmp;
    while (fscanf (f , "%lf " , &tmp) != EOF)
    dim ++;
    fclose (f);
    return dim;
}
double* loadVec(char* fname ,int n)
{
    FILE* f = fopen ( fname , "r" );
    double* res = new double [ n ];
    double* it = res ;
    while (fscanf(f , "%lf" , it++) != EOF);
    fclose (f );
    return res ;
}
double* loadMat ( char * fname , int n)
{
    FILE* f = fopen ( fname , "r" );
    double* res = new double [n*n];
    double* it = res;
    while(fscanf(f, "%lf" , it ++) != EOF);
    fclose(f);
    return res;
}
void logRes ( const char * fname , double * res , int n)
{
    FILE* f = fopen ( fname , "w");
    for (int i = 0; i != n ; ++i)
    fprintf (f , "%lf " , res [i]);
    fclose (f);
}
int main ( int argc , char * argv [])
{
    int csize;
    int prank;
    MPI_Init (& argc , & argv );
    MPI_Comm_size ( MPI_COMM_WORLD , & csize );
    MPI_Comm_rank ( MPI_COMM_WORLD , & prank );
    char* vfname = argv [1];
    char* mfname = argv [2];
    int dim;
    double* mat;
    double* vec;
    double* tmat;
    double* lres;
    double* res;

    if (prank == 0)
        dim = returnSize(vfname);

    MPI_Bcast(&dim , 1, MPI_INT, 0, MPI_COMM_WORLD);

    if (prank == 0)
        vec = loadVec ( vfname , dim );
    else
        vec = new double [ dim ];

    MPI_Bcast (vec , dim , MPI_DOUBLE , 0, MPI_COMM_WORLD);

    if(prank == 0)
        tmat = loadMat(mfname ,dim);
    
    MPI_Bcast (tmat , dim*dim , MPI_DOUBLE , 0, MPI_COMM_WORLD);

    int row_count = dim / csize;

    if(dim % csize != 0)
        if(prank < dim % csize)
            row_count++;

    mat = new double [dim*(1 + row_count)];

    lres = new double [row_count];

    // cik cak uzimanje redova
    // int row = prank;

    // while(row <= dim)
    // {
    //     double s = 0;
        
    //     for (int j = 0; j != dim ; ++ j)
    //         s += mat[row * dim + j] * vec[j];

    //     lres[row] = s;

    //     row += csize;

    // }

    for (int i = 0; i != row_count ; ++ i)
    {
        double s = 0;
        
        for ( int j = 0; j != dim ; ++ j)
            s += mat [i * dim +j] * vec[j];
        lres[i] = s;
    }

    if(prank == 0)
        res = new double [ dim ];

    MPI_Reduce (&lres , &res, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);

    // MPI_Gather ( lres , row_count , MPI_DOUBLE ,
    // res , row_count , MPI_DOUBLE ,
    // 0, MPI_COMM_WORLD );

    if (prank == 0) {
        logRes("res.txt" , res, dim);
    }
    if (prank == 0)
    {
        delete [] tmat ;
        delete [] res ;
    }
    delete [] vec ;
    delete [] mat ;
    delete [] lres ;

    MPI_Finalize ();

    return 0;
}