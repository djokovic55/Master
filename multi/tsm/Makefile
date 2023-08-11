CXX = mpic++

SOURCES = tsm_mpi.cpp

EXECUTABLE = tsm_mpi

all: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES)
	$(CXX) -o $@ $^
	mpirun -np 4 ./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE)