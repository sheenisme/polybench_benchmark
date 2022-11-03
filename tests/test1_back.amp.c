#include <assert.h>
#include <stdio.h>
// clang-format off
/*
 * gaussian-sp.sdsl.c: This file is part of the SDSLC project.
 *
 * SDSLC: A compiler for high performance stencil computations
 *
 * Copyright (C) 2011-2013 Ohio State University
 *
 * This program can be redistributed and/or modified under the terms
 * of the license specified in the LICENSE.txt file at the root of the
 * project.
 *
 * Contact: P Sadayappan <saday@cse.ohio-state.edu>
 */

/*
 * @file: gaussian-sp.sdsl.c
 * @author: Tom Henretty <henretty@cse.ohio-state.edu>
 */
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
//#include <malloc.h>
// Problem parameters
#ifndef H
#define H (2048)
#endif

#ifndef W
#define W (2048)
#endif

#ifndef T
#define T (50)
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

	// Initialize arrays
	for (i = 0; i < H; i++) {
		for (j = 0; j < W; j++) {
			aref[0][i][j] = sin(i) * cos(j);
		}
	}

    gettimeofday(&start, 0);
	/* ppcg generated CPU code with AMP */
	int count1=0,count2=0;
	float amp_lower_a[2041][1735][2042];
	float amp_lower_aref[2041][1735][2042];
	
	  for (int c0 = 5; c0 <= 2045; c0 += 1)
	    for (int c1 = c0; c1 <= c0 - (3 * c0 + 21) / 20 + 307; c1 += 1)
	      for (int c2 = 6; c2 <= 2047; c2 += 1)
		  {
		   		a[c0][c1][c2] = ((aref[c0][c1][c2] + 1) * 2);
				count1++;
		  }
	  // amp_kernel
	  // amp_lower
	    for (int c0 = 0; c0 <= 2040; c0 += 1)
	      for (int c1 = c0 - (3 * c0 + 16) / 20; c1 <= 1734; c1 += 1)
	        for (int c2 = 0; c2 <= 2041; c2 += 1)
	          amp_lower_aref[c0][c1][c2] = (float)aref[c0 + 5][c1 + 312][c2 + 6];
	    for (int c0 = 5; c0 <= 2045; c0 += 1)
	      for (int c1 = c0 - (3 * c0 + 21) / 20 + 308; c1 <= 2046; c1 += 1)
	        for (int c2 = 6; c2 <= 2047; c2 += 1){
				amp_lower_a[c0 - 5][c1 - 312][c2 - 6] = ((amp_lower_aref[c0 - 5][c1 - 312][c2 - 6] + 1) * 2);
				count2++;
			}
	    for (int c0 = 0; c0 <= 2040; c0 += 1)
	      for (int c1 = c0 - (3 * c0 + 16) / 20; c1 <= 1734; c1 += 1)
	        for (int c2 = 0; c2 <= 2041; c2 += 1)
	          a[c0 + 5][c1 + 312][c2 + 6] = (double)amp_lower_a[c0][c1][c2];
    gettimeofday(&end, 0);
	printf("\n count1 = %d, count2 = %d. count1\\count2 = %.2f .\n", count1, count2,(count1 * 1.0) /(count2 * 1.0));
	for (int t = 0; t < T; t++) {
		for (int i = 2; i < H; i++) {
			for (int j = 2; j < W; j++) {
				a[t][i][j] = a[t][i][j]*2;
			}
		}
    }
    

    ts_return = timeval_subtract(&result, &end, &start);
    tdiff = (double)(result.tv_sec + result.tv_usec * 1.0e-6);

    printf("Time taken =  %7.5lfms\t", tdiff * 1.0e3);

	return 0;
}
