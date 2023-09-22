CXX = mpic++

SOURCES = billiard_balls_sim.cpp

EXECUTABLE = billiard_balls_sim

all: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES)
	$(CXX) -o $@ $^
	mpirun -np 2 ./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE)

.PHONY: all clean
