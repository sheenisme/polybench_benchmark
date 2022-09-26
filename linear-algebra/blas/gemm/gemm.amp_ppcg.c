#include <assert.h>
#include <stdio.h>
/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* gemm.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "gemm.h"


/* Array initialization. */
static
void init_array(int ni, int nj, int nk,
		DATA_TYPE *alpha,
		DATA_TYPE *beta,
		DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj),
		DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk),
		DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj))
{
  int i, j;

  *alpha = 1.5;
  *beta = 1.2;
  for (i = 0; i < ni; i++)
    for (j = 0; j < nj; j++)
      C[i][j] = (DATA_TYPE) ((i*j+1) % ni) / ni;
  for (i = 0; i < ni; i++)
    for (j = 0; j < nk; j++)
      A[i][j] = (DATA_TYPE) (i*(j+1) % nk) / nk;
  for (i = 0; i < nk; i++)
    for (j = 0; j < nj; j++)
      B[i][j] = (DATA_TYPE) (i*(j+2) % nj) / nj;
}


/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static
void print_array(int ni, int nj,
		 DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj))
{
  int i, j;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("C");
  for (i = 0; i < ni; i++)
    for (j = 0; j < nj; j++) {
	if ((i * ni + j) % 20 == 0) fprintf (POLYBENCH_DUMP_TARGET, "\n");
	fprintf (POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, C[i][j]);
    }
  POLYBENCH_DUMP_END("C");
  POLYBENCH_DUMP_FINISH;
}


/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static
void kernel_gemm(int ni, int nj, int nk,
		 DATA_TYPE alpha,
		 DATA_TYPE beta,
		 DATA_TYPE POLYBENCH_2D(C,NI,NJ,ni,nj),
		 DATA_TYPE POLYBENCH_2D(A,NI,NK,ni,nk),
		 DATA_TYPE POLYBENCH_2D(B,NK,NJ,nk,nj))
{
  int i, j, k;

//BLAS PARAMS
//TRANSA = 'N'
//TRANSB = 'N'
// => Form C := alpha*A*B + beta*C,
//A is NIxNK
//B is NKxNJ
//C is NIxNJ
  /* ppcg generated CPU code with AMP */
  
  float amp_lower_A[100][240];
  float amp_lower_B[240][220];
  float amp_lower_C[100][220];
  float amp_lower_alpha;
  float amp_lower_beta;
  {
    for (int c0 = 0; c0 <= 99; c0 += 1)
      for (int c1 = 0; c1 <= 219; c1 += 1) {
        C[c0][c1] *= beta;
        for (int c2 = 0; c2 <= 239; c2 += 1)
          C[c0][c1] += ((alpha * A[c0][c2]) * B[c2][c1]);
      }
    // amp_kernel
    // amp_lower
    {
      for (int c0 = 0; c0 <= 99; c0 += 1)
        for (int c1 = 0; c1 <= 239; c1 += 1)
          amp_lower_A[c0][c1] = (float)A[c0 + 100][c1];
      for (int c0 = 0; c0 <= 239; c0 += 1)
        for (int c1 = 0; c1 <= 219; c1 += 1)
          amp_lower_B[c0][c1] = (float)B[c0][c1];
      for (int c0 = 0; c0 <= 99; c0 += 1)
        for (int c1 = 0; c1 <= 219; c1 += 1)
          amp_lower_C[c0][c1] = (float)C[c0 + 100][c1];
      amp_lower_alpha = (float)alpha;
      amp_lower_beta = (float)beta;
      for (int c0 = 100; c0 <= 199; c0 += 1)
        for (int c1 = 0; c1 <= 219; c1 += 1) {
          amp_lower_C[c0 - 100][c1] *= amp_lower_beta;
          for (int c2 = 0; c2 <= 239; c2 += 1)
            amp_lower_C[c0 - 100][c1] += ((amp_lower_alpha * amp_lower_A[c0 - 100][c2]) * amp_lower_B[c2][c1]);
        }
      for (int c0 = 0; c0 <= 99; c0 += 1)
        for (int c1 = 0; c1 <= 219; c1 += 1)
          C[c0 + 100][c1] = (double)amp_lower_C[c0][c1];
    }
  }

}


int main(int argc, char** argv)
{
  /* Retrieve problem size. */
  int ni = NI;
  int nj = NJ;
  int nk = NK;

  /* Variable declaration/allocation. */
  DATA_TYPE alpha;
  DATA_TYPE beta;
  POLYBENCH_2D_ARRAY_DECL(C,DATA_TYPE,NI,NJ,ni,nj);
  POLYBENCH_2D_ARRAY_DECL(A,DATA_TYPE,NI,NK,ni,nk);
  POLYBENCH_2D_ARRAY_DECL(B,DATA_TYPE,NK,NJ,nk,nj);

  /* Initialize array(s). */
  init_array (ni, nj, nk, &alpha, &beta,
	      POLYBENCH_ARRAY(C),
	      POLYBENCH_ARRAY(A),
	      POLYBENCH_ARRAY(B));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_gemm (ni, nj, nk,
	       alpha, beta,
	       POLYBENCH_ARRAY(C),
	       POLYBENCH_ARRAY(A),
	       POLYBENCH_ARRAY(B));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(ni, nj,  POLYBENCH_ARRAY(C)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(C);
  POLYBENCH_FREE_ARRAY(A);
  POLYBENCH_FREE_ARRAY(B);

  return 0;
}
