#include <iostream>
#include <cmath>
#include <vector>
#include <mpi.h>

using namespace std;

// Define a Ball class with properties like mass, position, velocity, and radius.
class Ball {
public:
    double mass;
    double radius;
    double x, y; // Position
    double vx, vy; // Velocity
    bool in_the_hole;

    Ball(double m, double r, double startX, double startY, double startVX, double startVY)
        : mass(m), radius(r), x(startX), y(startY), vx(startVX), vy(startVY), in_the_hole(false) {}
};

// Define a Hole class with properties like position and radius.
class Hole {
public:
    double x, y; // Position
    double radius;

    Hole(double posX, double posY, double r)
        : x(posX), y(posY), radius(r) {}
};

// Define a function to check if two balls are colliding.
bool areBallsColliding(const Ball& ball1, const Ball& ball2) {
    double distance = std::sqrt((ball1.x - ball2.x) * (ball1.x - ball2.x) + (ball1.y - ball2.y) * (ball1.y - ball2.y));
    return distance <= (ball1.radius + ball2.radius);
}

// Define a function to handle ball-to-ball collisions.
void handleBallCollision(Ball& ball1, Ball& ball2) {
    // Calculate relative velocity
    double relVelX = ball2.vx - ball1.vx;
    double relVelY = ball2.vy - ball1.vy;
   
    // Calculate normal vector
    double normalX = ball2.x - ball1.x;
    double normalY = ball2.y - ball1.y;
    double distance = std::sqrt(normalX * normalX + normalY * normalY);
    normalX /= distance;
    normalY /= distance;
   
    // Calculate relative velocity along the normal vector
    double relVelDotNormal = relVelX * normalX + relVelY * normalY;
   
    // Calculate impulse along the normal vector (use restitution for elasticity)
    double impulse = (2.0 * (ball1.mass * ball2.mass) * relVelDotNormal) /
                     ((ball1.mass + ball2.mass) * ball1.radius);
   
    // Update ball velocities
    ball1.vx += impulse * normalX / ball1.mass;
    ball1.vy += impulse * normalY / ball1.mass;
    ball2.vx -= impulse * normalX / ball2.mass;
    ball2.vy -= impulse * normalY / ball2.mass;
}

// Define a function to handle ball-to-wall collisions.
void handleWallCollision(Ball& ball) {
    if (ball.x - ball.radius < 0.0 || ball.x + ball.radius > 50.0) {
        // Horizontal wall collision
        ball.vx = -ball.vx; // Reverse the horizontal velocity component
        cout<<"Horizontal wall colision!"<<endl;
    }
    if (ball.y - ball.radius < 0.0 || ball.y + ball.radius > 20.0) {
        // Vertical wall collision
        ball.vy = -ball.vy; // Reverse the vertical velocity component
        cout<<"Vertical wall colision!"<<endl;
    }
}

// Define a function to check if a ball has fallen into a hole.
bool isBallInHole(const Ball& ball, const Hole& hole) {
    double distance = std::sqrt((ball.x - hole.x) * (ball.x - hole.x) + (ball.y - hole.y) * (ball.y - hole.y));
    return distance < hole.radius;
}


// Simulate the movement of a ball using simple Euler integration.
void simulateBallMotion(Ball& ball, double timeStep, double friction) {
    // Update position
    ball.x += ball.vx * timeStep;
    ball.y += ball.vy * timeStep;

    // Apply friction
    ball.vx *= (1.0 - friction);
    ball.vy *= (1.0 - friction);

    // Simulate gravity (if needed)
    // ball.vy -= gravity * timeStep;
}


int main() {
    
    int rank;
    int size;
    int numTimeSteps = 100;
    const double timeStep = 0.01; // Time step for simulation
    int numBalls = 0; // Number of balls

    MPI_Init(NULL, NULL);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);


    if(rank == 0){
        FILE* inputFile = fopen("balls.txt", "r"); // Open the input file in read mode

        const double friction = 0.001; // Friction factor
        // const double ballRadius = 0.5;

        // Create holes
        Hole leftUpperHole(0.0, 0.0, 0.5);
        Hole rightUpperHole(50.0, 0.0, 0.5);
        Hole middleUpperHole(25.0, 0.0, 0.5);
        Hole leftBottomHole(0.0, 20.0, 0.5);
        Hole rightBottomHole(50.0, 20.0, 0.5);
        Hole middleBottomHole(25.0, 20.0, 0.5);


        if (!inputFile) {
            std::cerr << "Error opening input file." << std::endl;
            return 1;
        }


        std::vector<Ball> balls; // Vector to store ball objects

        double mass, radius, x, y, vx, vy;

        while (fscanf(inputFile, "%lf %lf %lf %lf %lf %lf", &mass, &radius, &x, &y, &vx, &vy) == 6) {
            Ball ball(mass, radius, x, y, vx, vy);
            balls.push_back(ball);
            numBalls++;
        }
        // cout<<"Balls num "<< numBalls<<endl; 

        MPI_Send(&numBalls, 1, MPI_INT, 1, 1, MPI_COMM_WORLD);

        // Close the input file
        fclose(inputFile);

        // Simulation loop
        for (int i = 0; i < numTimeSteps; ++i) { // Simulate for 10 seconds (adjust as needed)
            // Iterate through all balls
            for (int j = 0; j < numBalls; ++j) {
                // Skip the cue ball
                if(balls[j].in_the_hole) continue;
                
                // Simulate ball motion
                simulateBallMotion(balls[j], timeStep, friction);
                
                // Check for ball-to-wall collisions
                handleWallCollision(balls[j]);
                
                // Check for ball-to-ball collisions with other balls if it is on the table
                for (int k = 0; k < numBalls; ++k) {
                    if (k != j && areBallsColliding(balls[j], balls[k])) {
                        handleBallCollision(balls[j], balls[k]);
                        // cout<<"Ball "<<j<<" and ball "<<k<<" collided!"<<endl;
                    }
                }
                
                // Check if the ball has fallen into a hole
                if (isBallInHole(balls[j], leftUpperHole) ||
                    isBallInHole(balls[j], rightUpperHole) ||
                    isBallInHole(balls[j], middleUpperHole) ||
                    isBallInHole(balls[j], leftBottomHole) ||
                    isBallInHole(balls[j], rightBottomHole) ||
                    isBallInHole(balls[j], middleBottomHole)) {
                    // Set the ball's position to (-1, -1) when it falls into a hole
                    balls[j].x = -1.0;
                    balls[j].y = -1.0;
                    balls[j].vx = 0;
                    balls[j].vy = 0;
                    balls[j].in_the_hole = true;
                }
            }
            
            
            // Print ball positions
            // std::cout << "Time: " << i * timeStep << "s\n";
            for (int j = 0; j < numBalls; ++j) {
                // std::cout << "Ball " << j << ": (" << balls[j].x << ", " << balls[j].y << ")\n";
                float cor_x = balls[j].x;
                float cor_y = balls[j].y;

                MPI_Send(&j, 1, MPI_INT, 1, 2, MPI_COMM_WORLD);
                MPI_Send(&cor_x, 1, MPI_FLOAT, 1, 3, MPI_COMM_WORLD);
                MPI_Send(&cor_y, 1, MPI_FLOAT, 1, 4, MPI_COMM_WORLD);
            }


        }
    } else if(rank == 1) {
        FILE* outputFile = fopen("simulation.txt", "w"); // Open the output file in write mode
        float cor_x = 0.0; 
        float cor_y = 0.0;
        int ball_num;

        cout<<"Proc:"<<rank<<". Pass1"<<endl;

        if (!outputFile) {
            std::cerr << "Error opening output file." << std::endl;
            MPI_Finalize();
            return 1;
        }

        MPI_Recv(&numBalls, 1, MPI_INT, 0, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        cout<<"Proc:"<<rank<<". Number of balls"<<numBalls<<endl;


        for (int i = 0; i < numTimeSteps; ++i) { // Simulate for 10 seconds (adjust as needed)

            fprintf(outputFile, "Time: %.2lf s\n", i * timeStep);
            for (int j = 0; j < numBalls; ++j) {
                MPI_Recv(&ball_num, 1, MPI_INT, 0, 2, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Recv(&cor_x, 1, MPI_FLOAT, 0, 3, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                MPI_Recv(&cor_y, 1, MPI_FLOAT, 0, 4, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
                
                if(j == 0){
                    cout<<"Proc:"<<rank<<". Number of balls"<<numBalls<<endl;
                    cout<<"Proc:"<<rank<<". Cor x: "<<cor_x<<endl;
                    cout<<"Proc:"<<rank<<". Cor y: "<<cor_y<<endl;
                }
                // Print the same data to the output file

                fprintf(outputFile, "Ball %d: (%.2lf, %.2lf)\n", j, cor_x, cor_y);
            }

        }


        fclose(outputFile);

    // Close the output file
    }

    MPI_Finalize();
    return 0;
}