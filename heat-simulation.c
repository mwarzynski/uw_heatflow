#include <stdio.h>
#include <stdlib.h>

// start prepares simulation, initializes memory.
void start(
	int width,   // width of the board
	int height,  // height of the board
	float *M,    // initial value for board cells
	float *G,    // values for heat cells
	float *C,    // values for cool cells
	float flow   // flow is a proportion for heat movement
);

// step does one round of the simulation.
void step();

// cleanup should be used when simulating heat flow ended.
// It frees used memory for computing heat flow.
void cleanup();

// global variables to be parsed from the input file.
int width, height;
float *M, *G, *C;
float flow;
// NOTE: I assumed that heater/cooler values might differ depending on the
// side. Task descripiton specifies standard of the input file and
// there it's the same at both sides (there is only one row for heater/cooler).
// Therefore, I duplicated those values while initialization process.

// intialize function is used to read filename and prepare global variables
// to pass them to asm procedures.
int initialize(char *filename) {
    FILE *f;
    f = fopen(filename, "r");
    if (f == NULL) {
        perror("couldn't open input file");
        return 1;
    }

    if (fscanf(f, "%d %d\n", &width, &height) <= 0) {
        printf("couldn't parse width/height\n");
        fclose(f);
        return 1;
    }

    M = malloc(sizeof(float)*width*height);
    if (M == NULL) {
        perror("couldn't allocate memory for the board");
        fclose(f);
        return 1;
    }
    for (int i = 0; i < width; i++) {
        for (int j = 0; j < height; j++) {
            M[i*width + j] = 50;
        }
    }
    G = malloc(sizeof(float)*width*2);
    if (G == NULL) {
        perror("couldn't allocate memory for the heater");
        fclose(f);
        return 1;
    }
    for (int i = 0; i < width; i++) {
        G[i] = 100;
        G[i + width] = 100;
    }
    C = malloc(sizeof(float)*height*2);
    if (C == NULL) {
        perror("couldn't allocate memory for the cooler");
        fclose(f);
        return 1;
    }
    for (int i = 0; i < height; i++) {
        C[i] = 0;
        C[i + height] = 0;
    }

    // Scan the board cell's heat values.
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            if (fscanf(f, "%f", &M[y*width + x]) <= 0) {
                printf("couldn't scan the cell's heat value");
                printf(" at (%d,%d)\n", y, x);
                fclose(f);
                return 1;
            }
        }
    }
    // Scan the heater cell's values.
    for (int x = 0; x < width; x++) {
        if (fscanf(f, "%f", &G[x]) <= 0) {
            printf("couldn't scan the heater cell's value at %d\n", x);
            fclose(f);
            return 1;
        }
        G[width + x] = G[x];
    }
    // Scan the cooler cell's values.
    for (int y = 0; y < height; y++) {
        if (fscanf(f, "%f", &C[y]) <= 0) {
            printf("couldn't scan the cooler cell's value at %d\n", y);
            fclose(f);
            return 1;
        }
        C[height + y] = C[y];
    }

    fclose(f);
    return 0;
}

void print_board() {
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            printf("%.1f ", M[y*width + x]);
        }
        printf("\n");
    }
}

int main(int argc, char **argv) {
    if (argc != 2 && argc != 3) {
        printf("Usage: heatflow ./input-file\n");
        printf("       heatflow ./input-file flow\n");
        printf("Parameter 'flow' is optional.\n\n");
        printf("While in the stepping stage:");
        printf("    press Enter to do next step.\n");
        printf("    press 'e' to exit.\n");
        return 1;
    }
    if (argc == 3) {
        if (sscanf(argv[2], "%f", &flow) <= 0) {
            printf("Invalid 'flow' parameter value: expected float.\n");
            return 2;
        }
    } else {
        flow = 0.5;
    }

    if (initialize(argv[1]) != 0) {
        return 3;
    }

	start(width, height, M, G, C, flow);

    char c;
    while (c != 'e') {
        c = getchar();
        if (c == '\n') {
            step();
            print_board();
        }
    }
    cleanup();

    free(M); free(G); free(C);
	return 0;
}
