/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* bicg.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "bicg.h"

/* Array initialization. */
static void init_array(int m, int n,
                       DATA_TYPE POLYBENCH_2D(A, SIZE_N, SIZE_M, n, m),
                       DATA_TYPE POLYBENCH_1D(r, SIZE_N, n),
                       DATA_TYPE POLYBENCH_1D(p, SIZE_M, m))
{
  int i, j;

  for (i = 0; i < m; i++)
    p[i] = (DATA_TYPE)(i % m) / m;
  for (i = 0; i < n; i++)
  {
    r[i] = (DATA_TYPE)(i % n) / n;
    for (j = 0; j < m; j++)
      A[i][j] = (DATA_TYPE)(i * (j + 1) % n) / n;
  }
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int m, int n,
                        DATA_TYPE POLYBENCH_1D(s, SIZE_M, m),
                        DATA_TYPE POLYBENCH_1D(q, SIZE_N, n))

{
  int i;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("s");
  for (i = 0; i < m; i++)
  {
    if (i % 20 == 0)
      fprintf(POLYBENCH_DUMP_TARGET, "\n");
    fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, s[i]);
  }
  POLYBENCH_DUMP_END("s");
  POLYBENCH_DUMP_BEGIN("q");
  for (i = 0; i < n; i++)
  {
    if (i % 20 == 0)
      fprintf(POLYBENCH_DUMP_TARGET, "\n");
    fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, q[i]);
  }
  POLYBENCH_DUMP_END("q");
  POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_bicg(int m, int n,
                        DATA_TYPE POLYBENCH_2D(A, SIZE_N, SIZE_M, n, m),
                        DATA_TYPE POLYBENCH_1D(s, SIZE_M, m),
                        DATA_TYPE POLYBENCH_1D(q, SIZE_N, n),
                        DATA_TYPE POLYBENCH_1D(p, SIZE_M, m),
                        DATA_TYPE POLYBENCH_1D(r, SIZE_N, n))
{
  int i, j;
  DATA_TYPE zero = SCALAR_VAL(0.0);

#pragma scop
  for (i = 0; i < _PB_SIZE_M; i++)
    s[i] = 0;
  for (i = 0; i < _PB_SIZE_N; i++)
  {
    q[i] = zero;
    for (j = 0; j < _PB_SIZE_M; j++)
    {
      s[j] = s[j] + r[i] * A[i][j];
      q[i] = q[i] + A[i][j] * p[j];
    }
  }
#pragma endscop
}

int main(int argc, char **argv)
{
  /* Retrieve problem size. */
  int n = SIZE_N;
  int m = SIZE_M;

  /* Variable declaration/allocation. */
  POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, SIZE_N, SIZE_M, n, m);
  POLYBENCH_1D_ARRAY_DECL(s, DATA_TYPE, SIZE_M, m);
  POLYBENCH_1D_ARRAY_DECL(q, DATA_TYPE, SIZE_N, n);
  POLYBENCH_1D_ARRAY_DECL(p, DATA_TYPE, SIZE_M, m);
  POLYBENCH_1D_ARRAY_DECL(r, DATA_TYPE, SIZE_N, n);

  /* Initialize array(s). */
  init_array(m, n,
             POLYBENCH_ARRAY(A),
             POLYBENCH_ARRAY(r),
             POLYBENCH_ARRAY(p));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_bicg(m, n,
              POLYBENCH_ARRAY(A),
              POLYBENCH_ARRAY(s),
              POLYBENCH_ARRAY(q),
              POLYBENCH_ARRAY(p),
              POLYBENCH_ARRAY(r));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(m, n, POLYBENCH_ARRAY(s), POLYBENCH_ARRAY(q)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(A);
  POLYBENCH_FREE_ARRAY(s);
  POLYBENCH_FREE_ARRAY(q);
  POLYBENCH_FREE_ARRAY(p);
  POLYBENCH_FREE_ARRAY(r);

  return 0;
}
