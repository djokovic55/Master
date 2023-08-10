
#include <bits/stdc++.h>
#include <mpi.h>
using namespace std;

#define V 7
#define PATH V+1
#define MAX 1000000
// #define MIN(a,b) ((a<b)?a:b)

int tsp(int graph[][V], int s)
{
    int cities[PATH];
    int vertex[V];
    int min_cost = MAX;
    int current_cost = 0;
    int j = s;
    
    for (int i = 0; i < V-1; i++) {
        current_cost += graph[j][vertex[i]];
        j = vertex[i];
        cities[i+1] = vertex[i];
    }
    current_cost += graph[j][s];
    if(current_cost < min_cost)
        min_cost = current_cost;
    current_cost = 0;
    j = s;

    return min_cost;
}

int main(int argc, char *argv[])
{
    int rank, size, best_path[PATH];
    int graph[][V] = { {MAX, 5, 4, 2, 9, 1, 5},
                       {MAX, MAX, 0, 6, 9, 6, 0},
                       { 5, 3, MAX, 7, 6, 3, 2},
                       { 5, 2, 7, MAX, 7, 0, 4},
                       {MAX, 1, 3, 2, MAX, 6, 2},
                       { 9, 1, 8, 0, 9, MAX, 2},
                       { 1, 8, 4, 8, 6, 0, MAX}};

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int chunkSize; 
    vector<int> allPerms;
    int starting_city;
    int perms_num;

    
    if(rank == 0) {
        // Generate all permutations and distribute work to workers
        vector<int> vertex;
        perms_num = 0;

        for (int i = 0; i < V; i++)
            if (i != starting_city)
                vertex.push_back(i);

        do {
            allPerms.insert(allPerms.end(), vertex.begin(), vertex.end());
            perms_num++;
        } while (next_permutation(vertex.begin(), vertex.end()));

        // chunkSize = allPerms.size() / size;
        MPI_Bcast(&allPerms, 1, MPI_INT, 0, MPI_COMM_WORLD);
        MPI_Bcast(&perms_num, 1, MPI_INT, 0, MPI_COMM_WORLD);




        // for (int i = 1; i < size; ++i) {
        // MPI_Send(&allPerms[(i - 1) * chunkSize], chunkSize, MPI_INT, i, 0, MPI_COMM_WORLD);
        // }
        // arr = vector<int>(allPerms.begin() + (size - 1) * chunkSize, allPerms.end());
    } 
        // Receive work from master and generate permutations
        // MPI_Recv(arr.data(), totalElements, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Barrier(MPI_COMM_WORLD);





    // int s = 6;
    // int local_min = tsp(graph, s);
    // int global_min;
    // MPI_Reduce(&local_min, &global_min, 1, MPI_INT, MPI_MIN, 0, MPI_COMM_WORLD);

    // if (rank == 0) {
    //     cout<<"Min cost: "<<global_min<<endl;
    // }

    MPI_Finalize();
    return 0;
}
