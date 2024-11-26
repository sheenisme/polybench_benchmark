#include <assert.h>
#include <stdio.h>
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
	/* ppcg generated CPU code with AMP */
	
	float amp_lower_a[5][17][27];
	float amp_lower_aref[5][17][27];
	unsigned long amp_lower_total;
	{
	  for (int c0 = 5; c0 <= 9; c0 += 1)
	    for (int c1 = 2 * c0; c1 < 3 * c0; c1 += 1)
	      for (int c2 = c0 + c1; c2 <= c0 + c1 + (c1 - 1) / 6; c2 += 1)
	        a[c0][c1][c2] = ((aref[c0][c1][c2] + 1.00) * 2);
	  for (int c0 = 5; c0 <= 9; c0 += 1)
	    for (int c1 = 2 * c0; c1 < 3 * c0; c1 += 1)
	      for (int c2 = c0 + c1; c2 <= c0 + c1 + (c1 - 1) / 6; c2 += 1)
	        total++;
	  // amp_kernel
	  // amp_lower
	  {
	    for (int c0 = 0; c0 <= 4; c0 += 1)
	      for (int c1 = 2 * c0; c1 <= 3 * c0 + 4; c1 += 1)
	        for (int c2 = c0 + c1 + (c1 + 3) / 6; c2 <= c0 + c1 + c1 / 3 + 1; c2 += 1)
	          amp_lower_aref[c0][c1][c2] = (float)aref[c0 + 5][c1 + 10][c2 + 17];
	    amp_lower_total = (unsigned long)total;
	    for (int c0 = 5; c0 <= 9; c0 += 1)
	      for (int c1 = 2 * c0; c1 < 3 * c0; c1 += 1)
	        for (int c2 = c0 + c1 + (c1 - 1) / 6 + 1; c2 <= c0 + c1 + (c1 - 1) / 3; c2 += 1)
	          amp_lower_a[c0 - 5][c1 - 10][c2 - 17] = ((amp_lower_aref[c0 - 5][c1 - 10][c2 - 17] + 1.00) * 2);
	    for (int c0 = 5; c0 <= 9; c0 += 1)
	      for (int c1 = 2 * c0; c1 < 3 * c0; c1 += 1)
	        for (int c2 = c0 + c1 + (c1 - 1) / 6 + 1; c2 <= c0 + c1 + (c1 - 1) / 3; c2 += 1)
	          amp_lower_total++;
	    total = (unsigned long)amp_lower_total;
	    for (int c0 = 0; c0 <= 4; c0 += 1)
	      for (int c1 = 2 * c0; c1 <= 3 * c0 + 4; c1 += 1)
	        for (int c2 = c0 + c1 + (c1 + 3) / 6; c2 <= c0 + c1 + c1 / 3 + 1; c2 += 1)
	          a[c0 + 5][c1 + 10][c2 + 17] = (double)amp_lower_a[c0][c1][c2];
	  }
	}
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
