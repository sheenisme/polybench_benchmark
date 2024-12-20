/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* 3mm.c: this file is part of PolyBench/C */

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "3mm.h"

/* Array initialization. */
static void init_array(int ni, int nj, int nk, int nl, int nm,
                       DATA_TYPE POLYBENCH_2D(A, SIZE_NI, SIZE_NK, ni, nk),
                       DATA_TYPE POLYBENCH_2D(B, SIZE_NK, SIZE_NJ, nk, nj),
                       DATA_TYPE POLYBENCH_2D(C, SIZE_NJ, SIZE_NM, nj, nm),
                       DATA_TYPE POLYBENCH_2D(D, SIZE_NM, SIZE_NL, nm, nl))
{
  int i, j;

  for (i = 0; i < ni; i++)
    for (j = 0; j < nk; j++)
      A[i][j] = (DATA_TYPE)((i * j + 1) % ni) / (5 * ni);
  for (i = 0; i < nk; i++)
    for (j = 0; j < nj; j++)
      B[i][j] = (DATA_TYPE)((i * (j + 1) + 2) % nj) / (5 * nj);
  for (i = 0; i < nj; i++)
    for (j = 0; j < nm; j++)
      C[i][j] = (DATA_TYPE)(i * (j + 3) % nl) / (5 * nl);
  for (i = 0; i < nm; i++)
    for (j = 0; j < nl; j++)
      D[i][j] = (DATA_TYPE)((i * (j + 2) + 2) % nk) / (5 * nk);
}

/* DCE code. Must scan the entire live-out data.
   Can be used also to check the correctness of the output. */
static void print_array(int ni, int nl,
                        DATA_TYPE POLYBENCH_2D(G, SIZE_NI, SIZE_NL, ni, nl))
{
  int i, j;

  POLYBENCH_DUMP_START;
  POLYBENCH_DUMP_BEGIN("G");
  for (i = 0; i < ni; i++)
    for (j = 0; j < nl; j++)
    {
      if ((i * ni + j) % 20 == 0)
        fprintf(POLYBENCH_DUMP_TARGET, "\n");
      fprintf(POLYBENCH_DUMP_TARGET, DATA_PRINTF_MODIFIER, G[i][j]);
    }
  POLYBENCH_DUMP_END("G");
  POLYBENCH_DUMP_FINISH;
}

/* Main computational kernel. The whole function will be timed,
   including the call and return. */
static void kernel_3mm(int ni, int nj, int nk, int nl, int nm,
                       DATA_TYPE POLYBENCH_2D(E, SIZE_NI, SIZE_NJ, ni, nj),
                       DATA_TYPE POLYBENCH_2D(A, SIZE_NI, SIZE_NK, ni, nk),
                       DATA_TYPE POLYBENCH_2D(B, SIZE_NK, SIZE_NJ, nk, nj),
                       DATA_TYPE POLYBENCH_2D(F, SIZE_NJ, SIZE_NL, nj, nl),
                       DATA_TYPE POLYBENCH_2D(C, SIZE_NJ, SIZE_NM, nj, nm),
                       DATA_TYPE POLYBENCH_2D(D, SIZE_NM, SIZE_NL, nm, nl),
                       DATA_TYPE POLYBENCH_2D(G, SIZE_NI, SIZE_NL, ni, nl))
{
  int i, j, k;
  DATA_TYPE zero = SCALAR_VAL(0.0);

#pragma scop
  /* E := A*B */
  for (i = 0; i < _PB_SIZE_NI; i++)
    for (j = 0; j < _PB_SIZE_NJ; j++)
    {
      E[i][j] = zero;
      for (k = 0; k < _PB_SIZE_NK; ++k)
        E[i][j] += A[i][k] * B[k][j];
    }
  /* F := C*D */
  for (i = 0; i < _PB_SIZE_NJ; i++)
    for (j = 0; j < _PB_SIZE_NL; j++)
    {
      F[i][j] = zero;
      for (k = 0; k < _PB_SIZE_NM; ++k)
        F[i][j] += C[i][k] * D[k][j];
    }
  /* G := E*F */
  for (i = 0; i < _PB_SIZE_NI; i++)
  {
    for (j = 0; j < _PB_SIZE_NL; j++)
    {
      G[i][j] = zero;
      for (k = 0; k < _PB_SIZE_NJ; ++k)
        G[i][j] += E[i][k] * F[k][j];
    }
#ifndef NO_PENCIL_KILL
    __pencil_kill(E[i]);
#endif
  }
#ifndef NO_PENCIL_KILL
  __pencil_kill(F);
#endif
#pragma endscop
}

int main(int argc, char **argv)
{
  /* Retrieve problem size. */
  int ni = SIZE_NI;
  int nj = SIZE_NJ;
  int nk = SIZE_NK;
  int nl = SIZE_NL;
  int nm = SIZE_NM;

  /* Variable declaration/allocation. */
  POLYBENCH_2D_ARRAY_DECL(E, DATA_TYPE, SIZE_NI, SIZE_NJ, ni, nj);
  POLYBENCH_2D_ARRAY_DECL(A, DATA_TYPE, SIZE_NI, SIZE_NK, ni, nk);
  POLYBENCH_2D_ARRAY_DECL(B, DATA_TYPE, SIZE_NK, SIZE_NJ, nk, nj);
  POLYBENCH_2D_ARRAY_DECL(F, DATA_TYPE, SIZE_NJ, SIZE_NL, nj, nl);
  POLYBENCH_2D_ARRAY_DECL(C, DATA_TYPE, SIZE_NJ, SIZE_NM, nj, nm);
  POLYBENCH_2D_ARRAY_DECL(D, DATA_TYPE, SIZE_NM, SIZE_NL, nm, nl);
  POLYBENCH_2D_ARRAY_DECL(G, DATA_TYPE, SIZE_NI, SIZE_NL, ni, nl);

  /* Initialize array(s). */
  init_array(ni, nj, nk, nl, nm,
             POLYBENCH_ARRAY(A),
             POLYBENCH_ARRAY(B),
             POLYBENCH_ARRAY(C),
             POLYBENCH_ARRAY(D));

  /* Start timer. */
  polybench_start_instruments;

  /* Run kernel. */
  kernel_3mm(ni, nj, nk, nl, nm,
             POLYBENCH_ARRAY(E),
             POLYBENCH_ARRAY(A),
             POLYBENCH_ARRAY(B),
             POLYBENCH_ARRAY(F),
             POLYBENCH_ARRAY(C),
             POLYBENCH_ARRAY(D),
             POLYBENCH_ARRAY(G));

  /* Stop and print timer. */
  polybench_stop_instruments;
  polybench_print_instruments;

  /* Prevent dead-code elimination. All live-out data must be printed
     by the function call in argument. */
  polybench_prevent_dce(print_array(ni, nl, POLYBENCH_ARRAY(G)));

  /* Be clean. */
  POLYBENCH_FREE_ARRAY(E);
  POLYBENCH_FREE_ARRAY(A);
  POLYBENCH_FREE_ARRAY(B);
  POLYBENCH_FREE_ARRAY(F);
  POLYBENCH_FREE_ARRAY(C);
  POLYBENCH_FREE_ARRAY(D);
  POLYBENCH_FREE_ARRAY(G);

  return 0;
}
