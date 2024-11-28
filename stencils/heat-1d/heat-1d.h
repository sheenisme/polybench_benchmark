#ifndef _HEAT_1D_H
#define _HEAT_1D_H



/* Default to LARGE_DATASET. */
#if !defined(MINI_DATASET) && !defined(SMALL_DATASET)                          \
    && !defined(MEDIUM_DATASET) && !defined(LARGE_DATASET)                     \
    && !defined(EXTRALARGE_DATASET)
#define LARGE_DATASET
#endif

#if !defined(TSTEPS) && !defined(M) && !defined(N)
/* Define sample dataset sizes. */
#ifdef MINI_DATASET
#define TSTEPS 20
#define M 2
#define N 100
#endif

#ifdef SMALL_DATASET
#define TSTEPS 40
#define M 2
#define N 200
#endif

#ifdef MEDIUM_DATASET
#define TSTEPS 100
#define M 2
#define N 400
#endif

#ifdef LARGE_DATASET
#define TSTEPS 500
#define M 2
#define N 2000
#endif

#ifdef EXTRALARGE_DATASET
#define TSTEPS 200000
#define M 2
#define N 50000
#endif


#endif /* !(TSTEPS M N) */

#define _PB_TSTEPS POLYBENCH_LOOP_BOUND(TSTEPS, tsteps)
#define _PB_M POLYBENCH_LOOP_BOUND(M, m)
#define _PB_N POLYBENCH_LOOP_BOUND(N, n)


/* Default data type */
#if !defined(DATA_TYPE_IS_INT) && !defined(DATA_TYPE_IS_FLOAT)                 \
    && !defined(DATA_TYPE_IS_DOUBLE)
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
#define DATA_PRINTF_MODIFIER "%0.16f "
#define SCALAR_VAL(x) x##f
#define SQRT_FUN(x) sqrtf(x)
#define EXP_FUN(x) expf(x)
#define POW_FUN(x, y) powf(x, y)
#endif

#ifdef DATA_TYPE_IS_DOUBLE
#define DATA_TYPE double
#define DATA_PRINTF_MODIFIER "%0.16lf "
#define SCALAR_VAL(x) x
#define SQRT_FUN(x) sqrt(x)
#define EXP_FUN(x) exp(x)
#define POW_FUN(x, y) pow(x, y)
#endif

#endif /* !_HEAT_1D_H */
