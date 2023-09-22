CXX = g++
CXXFLAGS = -std=c++11 -Wall
LDFLAGS =
SOURCES = billiard_balls_sim.cpp
EXECUTABLE = billiard_balls_sim

all: $(EXECUTABLE)

$(EXECUTABLE): $(SOURCES)
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $(EXECUTABLE) $(LDFLAGS)
	./$(EXECUTABLE)

clean:
	rm -f $(EXECUTABLE)

.PHONY: all clean
