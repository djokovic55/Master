
#include <bits/stdc++.h>
#include <mpi.h>
#include <stdio.h>
using namespace std;

#define V 7
#define PATH V+1
#define MAX 1000000
// #define MIN(a,b) ((a<b)?a:b)

int main(int argc, char *argv[])
{
    int rank, size;
    int graph[][V] = { {MAX, 5, 4, 2, 9, 1, 5},
                       {MAX, MAX, 0, 6, 9, 6, 0},
                       { 5, 3, MAX, 7, 6, 3, 2},
                       { 5, 2, 7, MAX, 7, 0, 4},
                       {MAX, 1, 3, 2, MAX, 6, 2},
                       { 9, 1, 8, 0, 9, MAX, 2},
                       { 1, 8, 4, 8, 6, 0, MAX}};

    vector<int> allPerms;
    int* allPerms_p;
    int starting_city = 0;
    int last_permutation_loc;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    if(rank == 0) {
        // Generate all permutations and distribute work to workers
        vector<int> vertex;
        int perms_num = 0;
        cout <<"PASS1"<<endl;

        for (int i = 0; i < int(V); i++){
            if (i != starting_city)
                vertex.push_back(i);
        }


            do {
                allPerms.insert(allPerms.end(), vertex.begin(), vertex.end());
                perms_num++;
            } while (next_permutation(vertex.begin(), vertex.end()));

            last_permutation_loc = (perms_num - 1) * (V-1);
            cout <<"Number of permutations : " <<perms_num<<endl;
            cout <<"Number of elements : " <<allPerms.size()<<endl;
            cout <<"PASS2"<<endl;

            allPerms_p = allPerms.data();

            int k = 0;
            for(int i = 0; i < 4320; i++){
                
                cout<<"On process 0, allPerms_p el:"<<allPerms_p[i]<<endl;
                k++;

            }

            cout <<"Num of elelments inside pointer = "<<k<<endl;

            cout <<"PASS2.1"<<endl;
            // MPI_Bcast(allPerms_p, perms_num*int(V), MPI_INT, 0, MPI_COMM_WORLD);
            MPI_Bcast(allPerms_p, 4320, MPI_INT, 0, MPI_COMM_WORLD);
            cout <<"PASS2.2"<<endl;
            MPI_Bcast(&last_permutation_loc, 1, MPI_INT, 0, MPI_COMM_WORLD);
            cout <<"PASS3"<<endl;

    } 

    MPI_Barrier(MPI_COMM_WORLD);
    
    if(rank == 1) {
        for(int i = 0; i < 4320; i++){
            cout<<"On process 1, allPerms el:"<<allPerms_p[i]<<endl;
        }
    }

    // this is the starting pos of permutation for each process
    int i = rank*(V-1);
    int ds = size;

    int cities[PATH];

    int min_cost = MAX;
    int global_min_cost;

    int best_path[PATH];
    int global_best_path[PATH];

    while(i <= last_permutation_loc){

        if(rank == 0)
            cout<<"Value i = "<<i<<endl;

        int current_cost = 0;

        int j = starting_city;
        // if(rank == 0)
        //     cout<<"All perms size: "<<allPerms.size()<<endl;

        if(rank == 0)
            cout<<"PASS4"<<endl;
        
        for (int k = 0; i < V-1; k++) {
            current_cost += graph[j][allPerms_p[i+k]];
            j = allPerms_p[i+k];
            cities[k+1] = allPerms_p[i+k];
            if(rank == 0)
                cout<<"PASS04."<<k<<endl;
        }
        //Return to origin city
        current_cost += graph[j][starting_city];
        if(rank == 0)
            cout<<"PASS5"<<endl;

        if(current_cost < min_cost) {
            for(int t = 0; t < PATH; t++)
                best_path[t] = cities[t];

            min_cost = current_cost;
        }

        // next permutation starting location
        i += ds* int(V-1);
    }

    if(rank =! 0) {
        MPI_Send(&min_cost, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
        MPI_Send(&best_path, PATH, MPI_INT, 0, 0, MPI_COMM_WORLD);
    } else {
        cout <<"PASS6"<<endl;
        int small_global_min_cost = MAX;
        int small_global_best_path[PATH];

        for(int q = 1; q < size; q++){
            MPI_Recv(&small_global_min_cost, 1, MPI_INT, q, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Recv(&small_global_best_path, PATH, MPI_INT, q, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

            if(small_global_min_cost < global_min_cost) {
                for(int t = 0; t < PATH; t++)
                    global_best_path[t] = small_global_best_path[t];

                global_min_cost = small_global_min_cost;
            }
        }

        // Print result
        cout <<"Max cost: " <<global_min_cost<< endl;
        cout <<"Visited cities: ";
        for(int i = 0; i < PATH; i++)
            cout<< global_best_path[i]<<" ";
        cout<<endl;

    }

    MPI_Finalize();
    return 0;
}
