/* fdtd-1d.c: this file is part of PolyBench/C, which is extend by sheen song*/

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "fdtd-1d.h"

/* Array initialization. */
static void init_array(int n, DATA_TYPE POLYBENCH_1D(H, N, n),
                       DATA_TYPE POLYBENCH_1D(E, N, n))
{
    int i;

    for (i = 0; i < n; i++)
    {
        H[i] = ((DATA_TYPE)i) / n;
        E[i] = ((DATA_TYPE)i) / n;
    }
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int n, DATA_TYPE POLYBENCH_1D(H, N, n))

{
    int i;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("H");
    for (i = 0; i < n; i++)
    {
        if (i % 20 == 0)
            fprintf(POLYBENCH_DUMP_TARGET, "\n");
        fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, H[i]);
    }
    POLYBENCH_DUMP_END("H");
    POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_fdtd_1d(int tsteps, int n, DATA_TYPE POLYBENCH_1D(H, N, n),
                           DATA_TYPE POLYBENCH_1D(E, N, n))
{
    int t, i;
    DATA_TYPE coeff1 = SCALAR_VAL(0.5);
    DATA_TYPE coeff2 = SCALAR_VAL(0.7);

#pragma scop
    for (t = 0; t < _PB_TSTEPS; t++)
    {
        for (i = 1; i <= _PB_N - 1; i++)
            E[i] = E[i] - coeff1 * (H[i] - H[i - 1]);
        for (i = 0; i <= _PB_N - 1; i++)
            H[i] = H[i] - coeff2 * (E[i + 1] - E[i]);
    }
#ifndef NO_PENCIL_KILL
    __pencil_kill(E);
#endif
#pragma endscop
}

int main(int argc, char **argv)
{
    /* Retrieve problem size. */
    int n = N;
    int tsteps = TSTEPS;

    /* Variable declaration/allocation. */
    POLYBENCH_1D_ARRAY_DECL(H, DATA_TYPE, N, n);
    POLYBENCH_1D_ARRAY_DECL(E, DATA_TYPE, N, n);

    /* Initialize array(s). */
    init_array(n, POLYBENCH_ARRAY(H), POLYBENCH_ARRAY(E));

    /* Start timer. */
    polybench_start_instruments;

    /* Run kernel. */
    kernel_fdtd_1d(tsteps, n, POLYBENCH_ARRAY(H), POLYBENCH_ARRAY(E));

    /* Stop and print timer. */
    polybench_stop_instruments;
    polybench_print_instruments;

    /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
    polybench_prevent_dce(print_array(n, POLYBENCH_ARRAY(H)));

    /* Be clean. */
    POLYBENCH_FREE_ARRAY(H);
    POLYBENCH_FREE_ARRAY(E);

    return 0;
}
