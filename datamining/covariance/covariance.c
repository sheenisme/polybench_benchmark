/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* covariance.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "covariance.h"

/* Array initialization. */
static void init_array(int m, int n,
                       DATA_TYPE *float_n,
                       DATA_TYPE POLYBENCH_2D(data, SIZE_N, SIZE_M, n, m))
{
  int i, j;

  *float_n = (DATA_TYPE)n;

  for (i = 0; i < n; i++)
    for (j = 0; j < m; j++)
      data[i][j] = ((DATA_TYPE)i * j) / m;
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int m,
                        DATA_TYPE POLYBENCH_2D(cov, SIZE_M, SIZE_M, m, m))

{
  int i, j;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("cov");
  for (i = 0; i < m; i++)
    for (j = 0; j < m; j++)
    {
      if ((i * m + j) % 20 == 0)
        fprintf(POLYBENCH_DUMP_TARGET, "\n");
      fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, cov[i][j]);
    }
  POLYBENCH_DUMP_END("cov");
  POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_covariance(int m, int n,
                              DATA_TYPE float_n,
                              DATA_TYPE POLYBENCH_2D(data, SIZE_N, SIZE_M, n, m),
                              DATA_TYPE POLYBENCH_2D(cov, SIZE_M, SIZE_M, m, m),
                              DATA_TYPE POLYBENCH_1D(mean, SIZE_M, m))
{
  int i, j, k;
  DATA_TYPE one = SCALAR_VAL(1.0);
  DATA_TYPE zero = SCALAR_VAL(0.0);

#pragma scop
  for (j = 0; j < _PB_SIZE_M; j++)
  {
    mean[j] = zero;
    for (i = 0; i < _PB_SIZE_N; i++)
      mean[j] += data[i][j];
    mean[j] /= float_n;
  }

  for (i = 0; i < _PB_SIZE_N; i++)
    for (j = 0; j < _PB_SIZE_M; j++)
      data[i][j] -= mean[j];
#ifndef NO_PENCIL_KILL
  __pencil_kill(mean);
#endif
  for (i = 0; i < _PB_SIZE_M; i++)
    for (j = i; j < _PB_SIZE_M; j++)
    {
      cov[i][j] = zero;
      for (k = 0; k < _PB_SIZE_N; k++)
        cov[i][j] += data[k][i] * data[k][j];
      cov[i][j] /= (float_n - one);
      cov[j][i] = cov[i][j];
    }
#ifndef NO_PENCIL_KILL
  __pencil_kill(data, float_n);
#endif
#pragma endscop
}

int main(int argc, char **argv)
{
  /* Retrieve problem size. */
  int n = SIZE_N;
  int m = SIZE_M;

  /* Variable declaration/allocation. */
  DATA_TYPE float_n;
  POLYBENCH_2D_ARRAY_DECL(data, DATA_TYPE, SIZE_N, SIZE_M, n, m);
  POLYBENCH_2D_ARRAY_DECL(cov, DATA_TYPE, SIZE_M, SIZE_M, m, m);
  POLYBENCH_1D_ARRAY_DECL(mean, DATA_TYPE, SIZE_M, m);

  /* Initialize array(s). */
  init_array(m, n, &float_n, POLYBENCH_ARRAY(data));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_covariance(m, n, float_n,
                    POLYBENCH_ARRAY(data),
                    POLYBENCH_ARRAY(cov),
                    POLYBENCH_ARRAY(mean));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(m, POLYBENCH_ARRAY(cov)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(data);
  POLYBENCH_FREE_ARRAY(cov);
  POLYBENCH_FREE_ARRAY(mean);

  return 0;
}
