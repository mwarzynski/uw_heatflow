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

int main() {
    int width = 10;
    int height = 10;
	float *M, *G, *C;
    float weight = 0.5;

    M = malloc(sizeof(float)*width*height);
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            M[i*width + j] = 4;
        }
    }

    G = malloc(sizeof(float)*width*2);
    for (int i = 0; i < width; i++) {
        G[i] = 8;
        G[i + width] = 8;
    }
    C = malloc(sizeof(float)*height*2);
    for (int i = 0; i < height; i++) {
        C[i] = 1;
        C[i + height] = 1;
    }

	start(width, height, M, G, C, weight);
	step();

    free(M); free(G); free(C);
	return 0;
}
