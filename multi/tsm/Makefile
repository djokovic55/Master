CXX = mpic++

SOURCES = tsm_mpi.cpp

EXECUTABLE = tsm_mpi

all: $(EXECUTABLE)

seq:
	mpic++ seq_tsm.cpp -o seq_tsm 
	mpirun -np 1 ./seq_tsm

$(EXECUTABLE): $(SOURCES)
	$(CXX) -o $@ $^
	mpirun -np 4 ./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE) 

seq_clean:
	rm -f seq_tsm