#ifndef _HEAT_2D_H
#define _HEAT_2D_H

/* Default to 2，don't modify*/
#define M 2

/* Default to EXTRALARGE_DATASET. */
#if !defined(MINI_DATASET) && !defined(SMALL_DATASET) && !defined(MEDIUM_DATASET) && !defined(LARGE_DATASET) && !defined(EXTRALARGE_DATASET)
#define EXTRALARGE_DATASET
#endif

#if !defined(TSTEPS) && !defined(N)
/* Define sample dataset sizes. */
#ifdef MINI_DATASET
#define TSTEPS 20
#define N 10
#endif

#ifdef SMALL_DATASET
#define TSTEPS 40
#define N 20
#endif

#ifdef MEDIUM_DATASET
#define TSTEPS 100
#define N 40
#endif

#ifdef LARGE_DATASET
#define TSTEPS 500
#define N 120
#endif

#ifdef EXTRALARGE_DATASET
// #define TSTEPS 1000
// #define N 400
#define TSTEPS 8000
#define N 3000
#endif

#endif /* !(TSTEPS N) */

#define _PB_TSTEPS POLYBENCH_LOOP_BOUND(TSTEPS, tsteps)
#define _PB_N POLYBENCH_LOOP_BOUND(N, n)

/* Default data type */
#if !defined(DATA_TYPE_IS_INT) && !defined(DATA_TYPE_IS_FLOAT) && !defined(DATA_TYPE_IS_DOUBLE)
#define DATA_TYPE_IS_DOUBLE
#endif

#ifdef DATA_TYPE_IS_INT
#define DATA_TYPE int
#define DATA_PRINTF_MODIFIER "%d "
#endif

#if defined(DATA_TYPE_IS_INT) && !defined(INTEGER_SUPPORT)
#error "Integer data type not supported for this benchmark."
#endif

#ifdef DATA_TYPE_IS_FLOAT
#define DATA_TYPE float
#define DATA_PRINTF_MODIFIER "%0.10f "
#define SCALAR_VAL(x) x##f
#define SQRT_FUN(x) sqrtf(x)
#define EXP_FUN(x) expf(x)
#define POW_FUN(x, y) powf(x, y)
#endif

#ifdef DATA_TYPE_IS_DOUBLE
#define DATA_TYPE double
#define DATA_PRINTF_MODIFIER "%0.10lf "
#define SCALAR_VAL(x) x
#define SQRT_FUN(x) sqrt(x)
#define EXP_FUN(x) exp(x)
#define POW_FUN(x, y) pow(x, y)
#endif

#endif /* !_HEAT_2D_H */
