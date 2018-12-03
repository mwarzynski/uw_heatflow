#include <stdio.h>

// start prepares simulation, initializes memory.
void start(
	int width,   // width of the matrix
	int height,  // height of the matrix
	float *M,    // initial value for matrix fields
	float *G,    // initial value for heat engine
	float *C,    // initial value for cool engine
	float weight // weight is a proportion for heat movement
);

// step does one round of the simulation.
void step();

int main() {
	return 0;
}
