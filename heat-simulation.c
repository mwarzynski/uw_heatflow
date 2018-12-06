#include <stdio.h>
#include <stdlib.h>

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

// cleanup should be used when simulating heat flow ended.
// It frees used memory for computing heat flow.
void cleanup();

int main() {
    int width = 10;
    int height = 10;
	float *M, *G, *C;
    float weight = 0.5;

    M = malloc(sizeof(float)*width*height);
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            M[i*width + j] = 20 + i*j;
        }
    }
    G = malloc(sizeof(float)*width*2);
    for (int i = 0; i < width; i++) {
        G[i] = 300 + i;
        G[i + width] = 400 + i;
    }
    C = malloc(sizeof(float)*height*2);
    for (int i = 0; i < height; i++) {
        C[i] = i;
        C[i + height] = 10 + i;
    }

    // Call heatflow asm procedures.
	start(width, height, M, G, C, weight);
	step();
    cleanup();

    free(M); free(G); free(C);
	return 0;
}
