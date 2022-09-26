/*
 * Discretized 2D heat equation stencil with non periodic boundary conditions
 * Adapted from Pochoir test bench
 *
 * Irshad Pananilath: irshad@csa.iisc.ernet.in
 */
/* heat-1d.c: this file is part of PolyBench/C, which is extend by sheen song*/

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "heat-1d.h"

/* Array initialization. */
static void init_array(int n, int m, DATA_TYPE POLYBENCH_2D(A, M, N, m, n)) {
    int i;
    const int BASE = 1024;

    srand(42); // seed with a constant value to verify results

    for (i = 0; i < n; i++) {
        A[0][i] = (DATA_TYPE)(rand() % BASE);
    }
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int n, int m, DATA_TYPE POLYBENCH_2D(A, M, N, m, n)) {
    int i;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("A");
    for (i = 0; i < n; i++) {
        if (i % 20 == 0)
            fprintf(POLYBENCH_DUMP_TARGET, "\n");
        fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, A[(_PB_TSTEPS - 1) % 2][i]);
    }
    POLYBENCH_DUMP_END("A");
    POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_heat_1d(int tsteps, int n, int m, DATA_TYPE POLYBENCH_2D(A, M, N, m, n)) {
    int t, i;
    DATA_TYPE v1 = SCALAR_VAL(0.250);
    DATA_TYPE v2 = SCALAR_VAL(2.0);

#pragma scop
    for (t = 0; t < _PB_TSTEPS - 1; t++) {
        for (i = 1; i < _PB_N - 1; i++) {
            A[(t + 1) % 2][i] = v1 * (A[t % 2][i + 1] - v2 * A[t % 2][i] + A[t % 2][i - 1]);
        }
    }
#pragma endscop
}

int main(int argc, char **argv) {
    /* Retrieve problem size. */
    int tsteps = TSTEPS;
    int m = M;
    int n = N;

    /* Variable declaration/allocation. */
    POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, M, N, m, n);

    /* Initialize array(s). */
    init_array(n, m, POLYBENCH_ARRAY(A));

    /* Start timer. */
    polybench_start_instruments;

    /* Run kernel. */
    kernel_heat_1d(tsteps, n, m, POLYBENCH_ARRAY(A));

    /* Stop and print timer. */
    polybench_stop_instruments;
    polybench_print_instruments;

    /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
    polybench_prevent_dce(print_array(n, m, POLYBENCH_ARRAY(A)));

    /* Be clean. */
    POLYBENCH_FREE_ARRAY(A);

    return 0;
}
