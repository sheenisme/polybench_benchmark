/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* correlation.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "correlation.h"

/* Array initialization. */
static void init_array(int m,
                       int n,
                       DATA_TYPE *float_n,
                       DATA_TYPE POLYBENCH_2D(data, SIZE_N, SIZE_M, n, m))
{
  int i, j;

  *float_n = (DATA_TYPE)n;

  for (i = 0; i < n; i++)
    for (j = 0; j < m; j++)
      data[i][j] = (DATA_TYPE)(i * j) / m + i;
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int m,
                        DATA_TYPE POLYBENCH_2D(corr, SIZE_M, SIZE_M, m, m))

{
  int i, j;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("corr");
  for (i = 0; i < m; i++)
    for (j = 0; j < m; j++)
    {
      if ((i * m + j) % 20 == 0)
        fprintf(POLYBENCH_DUMP_TARGET, "\n");
      fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, corr[i][j]);
    }
  POLYBENCH_DUMP_END("corr");
  POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_correlation(int m, int n,
                               DATA_TYPE float_n,
                               DATA_TYPE POLYBENCH_2D(data, SIZE_N, SIZE_M, n, m),
                               DATA_TYPE POLYBENCH_2D(corr, SIZE_M,SIZE_M, m, m),
                               DATA_TYPE POLYBENCH_1D(mean, SIZE_M, m),
                               DATA_TYPE POLYBENCH_1D(stddev, SIZE_M, m))
{
  int i, j, k;

  DATA_TYPE eps = SCALAR_VAL(0.1);
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

  for (j = 0; j < _PB_SIZE_M; j++)
  {
    stddev[j] = zero;
    for (i = 0; i < _PB_SIZE_N; i++)
      stddev[j] += (data[i][j] - mean[j]) * (data[i][j] - mean[j]);
    stddev[j] /= float_n;
    stddev[j] = SQRT_FUN(stddev[j]);
    /* The following in an inelegant but usual way to handle
       near-zero std. dev. values, which below would cause a zero-
       divide. */
    stddev[j] = stddev[j] <= eps ? one : stddev[j];
  }

  /* Center and reduce the column vectors. */
  for (i = 0; i < _PB_SIZE_N; i++)
    for (j = 0; j < _PB_SIZE_M; j++)
    {
      data[i][j] -= mean[j];
      data[i][j] /= SQRT_FUN(float_n) * stddev[j];
    }
#ifndef NO_PENCIL_KILL
  __pencil_kill(stddev, mean, float_n);
#endif
  /* Calculate the m * m correlation matrix. */
  for (i = 0; i < _PB_SIZE_M - 1; i++)
  {
    corr[i][i] = one;
    for (j = i + 1; j < _PB_SIZE_M; j++)
    {
      corr[i][j] = zero;
      for (k = 0; k < _PB_SIZE_N; k++)
        corr[i][j] += (data[k][i] * data[k][j]);
      corr[j][i] = corr[i][j];
    }
  }
#ifndef NO_PENCIL_KILL
  __pencil_kill(data);
#endif
#pragma endscop
  corr[_PB_SIZE_M - 1][_PB_SIZE_M - 1] = one;
}

int main(int argc, char **argv)
{
  /* Retrieve problem size. */
  int n = SIZE_N;
  int m = SIZE_M;

  /* Variable declaration/allocation. */
  DATA_TYPE float_n;
  POLYBENCH_2D_ARRAY_DECL(data, DATA_TYPE, SIZE_N, SIZE_M, n, m);
  POLYBENCH_2D_ARRAY_DECL(corr, DATA_TYPE, SIZE_M, SIZE_M, m, m);
  POLYBENCH_1D_ARRAY_DECL(mean, DATA_TYPE, SIZE_M, m);
  POLYBENCH_1D_ARRAY_DECL(stddev, DATA_TYPE, SIZE_M, m);

  /* Initialize array(s). */
  init_array(m, n, &float_n, POLYBENCH_ARRAY(data));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_correlation(m, n, float_n,
                     POLYBENCH_ARRAY(data),
                     POLYBENCH_ARRAY(corr),
                     POLYBENCH_ARRAY(mean),
                     POLYBENCH_ARRAY(stddev));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(m, POLYBENCH_ARRAY(corr)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(data);
  POLYBENCH_FREE_ARRAY(corr);
  POLYBENCH_FREE_ARRAY(mean);
  POLYBENCH_FREE_ARRAY(stddev);

  return 0;
}
