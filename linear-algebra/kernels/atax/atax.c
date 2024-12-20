/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* atax.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "atax.h"

/* Array initialization. */
static void init_array(int m, int n,
                       DATA_TYPE POLYBENCH_2D(A, SIZE_M, SIZE_N, m, n),
                       DATA_TYPE POLYBENCH_1D(x, SIZE_N, n))
{
  int i, j;
  DATA_TYPE fn;
  fn = (DATA_TYPE)n;

  for (i = 0; i < n; i++)
    x[i] = 1 + (i / fn);
  for (i = 0; i < m; i++)
    for (j = 0; j < n; j++)
      A[i][j] = (DATA_TYPE)((i + j) % n) / (5 * m);
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int n,
                        DATA_TYPE POLYBENCH_1D(y, SIZE_N, n))

{
  int i;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("y");
  for (i = 0; i < n; i++)
  {
    if (i % 20 == 0)
      fprintf(POLYBENCH_DUMP_TARGET, "\n");
    fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, y[i]);
  }
  POLYBENCH_DUMP_END("y");
  POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_atax(int m, int n,
                        DATA_TYPE POLYBENCH_2D(A, SIZE_M, SIZE_N, m, n),
                        DATA_TYPE POLYBENCH_1D(x, SIZE_N, n),
                        DATA_TYPE POLYBENCH_1D(y, SIZE_N, n),
                        DATA_TYPE POLYBENCH_1D(tmp, SIZE_M, m))
{
  int i, j;
  DATA_TYPE zero = SCALAR_VAL(0.0);

#pragma scop
  for (i = 0; i < _PB_SIZE_N; i++)
    y[i] = zero;
  for (i = 0; i < _PB_SIZE_M; i++)
  {
    tmp[i] = zero;
    for (j = 0; j < _PB_SIZE_N; j++)
      tmp[i] = tmp[i] + A[i][j] * x[j];
    for (j = 0; j < _PB_SIZE_N; j++)
      y[j] = y[j] + A[i][j] * tmp[i];
#ifndef NO_PENCIL_KILL
    __pencil_kill(tmp[i]);
#endif
  }
#pragma endscop
}

int main(int argc, char **argv)
{
  /* Retrieve problem size. */
  int m = SIZE_M;
  int n = SIZE_N;

  /* Variable declaration/allocation. */
  POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, SIZE_M, SIZE_N, m, n);
  POLYBENCH_1D_ARRAY_DECL(x, DATA_TYPE, SIZE_N, n);
  POLYBENCH_1D_ARRAY_DECL(y, DATA_TYPE, SIZE_N, n);
  POLYBENCH_1D_ARRAY_DECL(tmp, DATA_TYPE, SIZE_M, m);

  /* Initialize array(s). */
  init_array(m, n, POLYBENCH_ARRAY(A), POLYBENCH_ARRAY(x));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_atax(m, n,
              POLYBENCH_ARRAY(A),
              POLYBENCH_ARRAY(x),
              POLYBENCH_ARRAY(y),
              POLYBENCH_ARRAY(tmp));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(n, POLYBENCH_ARRAY(y)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(A);
  POLYBENCH_FREE_ARRAY(x);
  POLYBENCH_FREE_ARRAY(y);
  POLYBENCH_FREE_ARRAY(tmp);

  return 0;
}
