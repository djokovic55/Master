#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "mpi.h"
#define NPTS 38
#define NPROC 4
#define NRBUF 10
int main(int argc, char **argv)
{
  float *sendbuf, *recvbuf;
  int   sendcounts[NPROC], displs[NPROC];
  int   recvcount, myrank;
  int   nmin, nextra, k, i;

  MPI_Datatype sendtype = MPI_FLOAT;
  MPI_Datatype recvtype = MPI_FLOAT;
  int root = 0;
  MPI_Comm comm = MPI_COMM_WORLD;

  MPI_Init(&argc,&argv);
  MPI_Comm_rank(comm,&myrank);
  if (myrank==0)
    {
      float a[3] = { 0.60, -0.30, 0.20 };
      float w[3] = { 3.25,  1.45, 5.30 };
      float x[NPTS];
      sendbuf = malloc(sizeof(float)*NPTS);
      for (i=0;i<NPTS;i++)
        {
          x[i] = 0.1*i;
          sendbuf[i] = a[0]*sin(w[0]*x[i]) +
            a[1]*sin(w[1]*x[i]) + a[2]*sin(w[2]*x[i]);
        }
    }
  recvbuf =  malloc(sizeof(int)*NRBUF);

  nmin = NPTS/NPROC;
  nextra = NPTS%NPROC;
  k = 0;
  for (i=0; i<NPROC; i++)
    {
      if (i<nextra) sendcounts[i] = nmin+1;
      else sendcounts[i] = nmin;
      displs[i] = k;
      k = k+sendcounts[i];
    }
  // need to set recvcount also ...
  MPI_Scatterv(
    sendbuf, sendcounts, displs, ...

  char outstr[80];
  sprintf(outstr,"%1d: ",myrank);
  for(i=0;i<recvcount;i++)
    sprintf(outstr+2+7*i,"%7.3f",recvbuf[i]);
  printf("%s\n",outstr);

  MPI_Finalize();
  return 0;
}