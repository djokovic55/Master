
#include <iostream>
#include <bits/stdc++.h>
using namespace std;
#define V 7
#define PATH V+1
#define MAX 1000000

int tsp(int graph[][V], int s, int* best_path)
{
    // save the city path
    int cities[PATH];

    vector<int> vertex;
    vector<int> permutations;
    vector<vector<int>> permutations_2d;

    for (int i = 0; i < V; i++)
        if (i != s)
            vertex.push_back(i);
    int min_cost = MAX;
	//
	// store all permutations in an array
	int count = 0;
    while(next_permutation(vertex.begin(), vertex.end()))
    {
		
        for (int i = 0; i < vertex.size(); i++) {
			permutations_2d[count].push_back(vertex[i]);
		}
		count++;
    }
	
	cout<<"Number of permutations: " <<count<<endl;
	
	cout<<"All permutations: ";
	for(int i = 0; i < permutations_2d.size(); i++)
			for (int j = 0; j < permutations_2d[0].size(); j++) {
					cout<<permutations_2d[i][j];
			}
	cout<<endl;

    cities[0] = s;
    cities[PATH - 1] = s;

    while(next_permutation(vertex.begin(), vertex.end()))
     {
        int current_cost = 0;
        int j = s;
        
        for (int i = 0; i < vertex.size(); i++) {
                current_cost += graph[j][vertex[i]];
                j = vertex[i];
                cities[i+1] = vertex[i];
        }
        current_cost += graph[j][s];
        if(current_cost < min_cost)
            for(int i = 0; i < PATH; i++)
                best_path[i] = cities[i];

        min_cost = min(min_cost, current_cost);
	}
	return min_cost;
}
int main()
{
    int best_path[PATH];
    int graph[][V] = { {MAX, 5, 4, 2, 9, 1, 5},
                       {MAX, MAX, 0, 6, 9, 6, 0},
                       { 5, 3, MAX, 7, 6, 3, 2},
                       { 5, 2, 7, MAX, 7, 0, 4},
                       {MAX, 1, 3, 2, MAX, 6, 2},
                       { 9, 1, 8, 0, 9, MAX, 2},
                       { 1, 8, 4, 8, 6, 0, MAX}};                      
    int s = 6;
    cout <<"Max cost: " <<tsp(graph, s, best_path) << endl;
    cout <<"Visited cities: ";
    for(int i = 0; i < PATH; i++)
        cout<< best_path[i]<<" ";
    cout<<endl;


    return 0;
}

