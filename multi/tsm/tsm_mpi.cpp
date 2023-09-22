
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
    // defaults
    // for(int i = 0; i < 10; i++)
    //     allPerms.push_back(i);

    int allPerms_size = 0;
    int perms_num = 0;
    // int* allPerms_p;
    int starting_city = 0;
    int last_permutation_loc;

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    if(rank == 0) {
        // Generate all permutations and distribute work to workers
        vector<int> vertex;
        cout <<"PASS1, proc0"<<endl;

        //form basic city vector
        for (int i = 0; i < int(V); i++){
            if (i != starting_city)
                vertex.push_back(i);
        }

        // GENERATE ALL PERMUTATIONS - Broadcast
        do {
            allPerms.insert(allPerms.end(), vertex.begin(), vertex.end());
            perms_num++;
        } while (next_permutation(vertex.begin(), vertex.end()));

        // POSITION OF THE LAST PERMUTATIONS - Broadcast
        last_permutation_loc = (perms_num - 1) * (V-1);

        // ALL PERMUTATIONS SIZE - Broadcast
        allPerms_size = allPerms.size();
        cout <<"All perms in proc0 size "<<allPerms.size()<<"Perms number "<<perms_num<<endl;


    } 

    MPI_Bcast(&allPerms_size, 1, MPI_INT, 0, MPI_COMM_WORLD);
    allPerms.resize(allPerms_size);
    // cout <<"Bcast1"<<endl;

    MPI_Bcast(allPerms.data(), allPerms_size, MPI_INT, 0, MPI_COMM_WORLD);
    // cout <<"Bcast2"<<endl;

    MPI_Bcast(&last_permutation_loc, 1, MPI_INT, 0, MPI_COMM_WORLD);
    // cout <<"Bcast3"<<endl;

    
    // if(rank == 1) {
    //     for(int i = 0; i < 4320; i++){
    //         cout<<"On process 1, allPerms el:"<<allPerms_p[i]<<endl;
    //     }
    // }

    // this is the starting pos of permutation for each process
    int i = rank*(V-1);
    int ds = size;

    int cities[PATH];

    int min_cost = MAX;
    int global_min_cost;

    int best_path[PATH];
    int global_best_path[PATH];


    if(rank == 1) {
        cout<<"Last permutation loc: "<<last_permutation_loc<<". Proc " <<rank<<endl;
        cout<<"All perms size"<< allPerms.size()<<". Proc "<<rank<<endl;

    }

    while(i <= last_permutation_loc){

        int current_cost = 0;
        // if(rank == 1) {
        //     cout<<"Current permutation start location "<<i<<". Proc " <<rank<<endl;
        // }

        int j = starting_city;
        
        for (int k = 0; k < V-1; k++) {
            current_cost += graph[j][allPerms[i+k]];
            j = allPerms[i+k];
            cities[k+1] = allPerms[i+k];
        }
        //Return to origin city
        current_cost += graph[j][starting_city];

        if(current_cost < min_cost) {
            for(int t = 0; t < PATH; t++)
                best_path[t] = cities[t];

            min_cost = current_cost;
        }


        // for 2 proc and 7 cities proc0 should take permutations on position 0 14 28, while proc1 takes 7 21 42 etc
        // next permutation starting location
        i += ds* int(V-1);
    }

    // MPI_Barrier(MPI_COMM_WORLD);
    if(rank != 0){
        cout <<"Proc "<<rank<<" before if, "<<size<<endl;

    }
    

    if(rank =! 0) {
        cout <<"Proc "<<rank<<" sends, "<<size<<endl;
        MPI_Send(&min_cost, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
        MPI_Send(&best_path, PATH, MPI_INT, 0, 0, MPI_COMM_WORLD);

    } else {
        cout <<"Proc "<<rank<<" receives"<<endl;

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
