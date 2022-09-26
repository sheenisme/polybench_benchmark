/*
 * Order-1, 3D 7 point stencil
 * Adapted from Pochoir test bench
 *
 * Irshad Pananilath: irshad@csa.iisc.ernet.in
 */
/* 3d27pt.c: this file is part of PolyBench/C, which is extend by sheen song*/

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "3d27pt.h"

/* Array initialization. */
static void init_array(int n, int m, DATA_TYPE POLYBENCH_4D(A, M, N, N, N, m, n, n, n)) {
    int i, j, k;
    const int BASE = 1024;

    srand(42); // seed with a constant value to verify results

    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            for (k = 0; k < n; k++) {
                A[0][i][j][k] = (DATA_TYPE)(rand() % BASE);
                // A[0][i][j][k] = (DATA_TYPE)(i + j + (n - k)) * 10 / (n);
            }
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int n, int m, DATA_TYPE POLYBENCH_4D(A, M, N, N, N, m, n, n, n)) {
    int i, j, k;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("A");
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            for (k = 0; k < n; k++) {
                if ((i * n * n + j * n + k) % 20 == 0)
                    fprintf(POLYBENCH_DUMP_TARGET, "\n");
                fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, A[(_PB_TSTEPS - 1) % 2][i][j][k]);
            }
    POLYBENCH_DUMP_END("A");
    POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_3d27pt(int tsteps, int n, int m, DATA_TYPE POLYBENCH_4D(A, M, N, N, N, m, n, n, n)) {
    int t, i, j, k;
    DATA_TYPE alpha = SCALAR_VAL(0.09415);
    DATA_TYPE beta = SCALAR_VAL(0.02333);

#pragma scop
    for (t = 0; t < _PB_TSTEPS - 1; t++) {
        for (i = 1; i < _PB_N - 1; i++) {
            for (j = 1; j < _PB_N - 1; j++) {
                for (k = 1; k < _PB_N - 1; k++) {
                    A[(t + 1) % 2][i][j][k] = alpha * (A[t % 2][i][j][k]) +
                                              beta * (A[t % 2][i - 1][j][k] + A[t % 2][i + 1][j][k] +
                                                      A[t % 2][i][j - 1][k] + A[t % 2][i][j + 1][k] +
                                                      A[t % 2][i][j][k - 1] + A[t % 2][i][j][k + 1] +
                                                      A[t % 2][i - 1][j - 1][k] + A[t % 2][i + 1][j - 1][k] +
                                                      A[t % 2][i - 1][j + 1][k] + A[t % 2][i + 1][j + 1][k] +
                                                      A[t % 2][i - 1][j][k - 1] + A[t % 2][i + 1][j][k - 1] +
                                                      A[t % 2][i - 1][j][k + 1] + A[t % 2][i + 1][j][k + 1] +
                                                      A[t % 2][i][j - 1][k - 1] + A[t % 2][i][j + 1][k - 1] +
                                                      A[t % 2][i][j - 1][k + 1] + A[t % 2][i][j + 1][k + 1] +
                                                      A[t % 2][i - 1][j - 1][k - 1] + A[t % 2][i + 1][j - 1][k - 1] +
                                                      A[t % 2][i - 1][j + 1][k - 1] + A[t % 2][i + 1][j + 1][k - 1] +
                                                      A[t % 2][i - 1][j - 1][k + 1] + A[t % 2][i + 1][j - 1][k + 1] +
                                                      A[t % 2][i - 1][j + 1][k + 1] + A[t % 2][i + 1][j + 1][k + 1]);
                }
            }
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
    POLYBENCH_4D_ARRAY_DECL(A, DATA_TYPE, M, N, N, N, m, n, n, n);

    /* Initialize array(s). */
    init_array(n, m, POLYBENCH_ARRAY(A));

    /* Start timer. */
    polybench_start_instruments;

    /* Run kernel. */
    kernel_3d27pt(tsteps, n, m, POLYBENCH_ARRAY(A));

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
