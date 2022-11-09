// clang-format off
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
//#include <malloc.h>
// Problem parameters
#ifndef H
#define H (128)
#endif

#ifndef W
#define W (256)
#endif

#ifndef T
#define T (10)
//#define T (1)
#endif


int timeval_subtract(struct timeval *result, struct timeval *x, struct timeval *y) {
    if (x->tv_usec < y->tv_usec) {
        int nsec = (y->tv_usec - x->tv_usec) / 1000000 + 1;

        y->tv_usec -= 1000000 * nsec;
        y->tv_sec += nsec;
    }

    if (x->tv_usec - y->tv_usec > 1000000) {
        int nsec = (x->tv_usec - y->tv_usec) / 1000000;

        y->tv_usec += 1000000 * nsec;
        y->tv_sec -= nsec;
    }

    result->tv_sec = x->tv_sec - y->tv_sec;
    result->tv_usec = x->tv_usec - y->tv_usec;

    return x->tv_sec < y->tv_sec;
}
/** Main program */
int main(int argc, char *argv[]) {
	int i, j, ii, jj, t, tt;
	double refElapsed, sdslElapsed;
	double refGFLOPS, sdslGFLOPS;
    int ts_return = -1;
    struct timeval start, end, result;
    double tdiff = 0.0;
    double *aref_def = (double *)malloc((T+1) * sizeof(double) * H * W);
    double *a_def = (double *)malloc((T+1) * sizeof(double) * H * W);
    double(*aref)[H][W] = (double(*)[H][W])aref_def;
    double(*a)[H][W] = (double(*)[H][W])a_def;


    unsigned long int upper = 0;
    unsigned long int lower = 0;
    unsigned long int total = 0;

	// Initialize arrays
    for (int t = 0; t < T; t++) {
	    for (i = 0; i < H; i++) {
		    for (j = 0; j < W; j++) {
			    aref[t][i][j] = sin(i) * cos(j);
		    }
	    }
    }

    gettimeofday(&start, 0);
#pragma scop
	for (int t = 5; t < T; t++) {
		for (int i = 2 * t; i < 3 *t; i++) {
			for (int j = t + i; 3 * j < 3 * t + 4 * i; j++) {
				a[t][i][j] = (aref[t][i][j] + 1.00)*2;
                total++;
			}
		}
    }
#pragma endscop
    gettimeofday(&end, 0);
	for (int t = 0; t < T; t++) {
		for (int i = 2; i < H; i++) {
			for (int j = 2; j < W; j++) {
				a[t][i][j] = a[t][i][j]*2;
			}
		}
    }
    

    ts_return = timeval_subtract(&result, &end, &start);
    tdiff = (double)(result.tv_sec + result.tv_usec * 1.0e-6);

    printf("Time taken =  %7.5lfms\n", tdiff * 1.0e3);

    // print domain size of upper and lower
    printf("total is: %lu, upper count is : %lu, lower count is : %lu. \n", total, upper, lower);
	return 0;
}
