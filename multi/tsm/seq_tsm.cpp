#include <iostream>
#include <bits/stdc++.h>
#include <mpi.h>
using namespace std;
using namespace chrono;
#define V 7
#define PATH V+1
#define MAX 1000000

int tsp(int graph[][V], int s, int* best_path)
{
    int cities[PATH];
    for (int i = 0; i < PATH; i++) cities[i] = -1;

    vector<int> vertex;
    for (int i = 0; i < V; i++)
        if (i != s)
            vertex.push_back(i);
    int min_cost = MAX;

    do {
        int current_cost = 0;
        int j = s;
        cities[0] = s;
        for (int i = 0; i < vertex.size(); i++) {
            current_cost += graph[j][vertex[i]];
            j = vertex[i];
            cities[i+1] = vertex[i];
        }
        current_cost += graph[j][s];
        cities[PATH-1] = s;
        if(current_cost < min_cost) {
            for(int i = 0; i < PATH; i++)
                best_path[i] = cities[i];
            min_cost = current_cost;
        }
    } while (next_permutation(vertex.begin(), vertex.end()));

    return min_cost;
}

int main()
{
    int rank, size;

    MPI_Init(NULL, NULL);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    int best_path[PATH];
    int graph[][V] = { {MAX, 5, 4, 2, 9, 1, 5},
                       {MAX, MAX, 0, 6, 9, 6, 0},
                       { 5, 3, MAX, 7, 6, 3, 2},
                       { 5, 2, 7, MAX, 7, 0, 4},
                       {MAX, 1, 3, 2, MAX, 6, 2},
                       { 9, 1, 8, 0, 9, MAX, 2},
                       { 1, 8, 4, 8, 6, 0, MAX}};                      
    int s = 0;
    double start_time = MPI_Wtime();

    cout <<"Max cost: " <<tsp(graph, s, best_path) << endl;
    cout <<"Visited cities: ";
    for(int i = 0; i < PATH; i++)
        cout<< best_path[i]<<" ";
    cout<<endl;

    double end_time = MPI_Wtime();
    double res_time = end_time - start_time;
    if(rank == 0)
        cout << "Sequential Execution Time: " << res_time << endl;


    MPI_Finalize();

    return 0;
}
