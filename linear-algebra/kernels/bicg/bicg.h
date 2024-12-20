#ifndef _BICG_H
#define _BICG_H



/* Default to SMALL_DATASET. */
#if !defined(MINI_DATASET) && !defined(SMALL_DATASET)                          \
    && !defined(MEDIUM_DATASET) && !defined(LARGE_DATASET)                     \
    && !defined(EXTRALARGE_DATASET)
#define SMALL_DATASET
#endif

#if !defined(SIZE_M) && !defined(SIZE_N)
/* Define sample dataset sizes. */
#ifdef MINI_DATASET
#define SIZE_M 38
#define SIZE_N 42
#endif

#ifdef SMALL_DATASET
#define SIZE_M 116
#define SIZE_N 124
#endif

#ifdef MEDIUM_DATASET
#define SIZE_M 390
#define SIZE_N 410
#endif

#ifdef LARGE_DATASET
#define SIZE_M 1900
#define SIZE_N 2100
#endif

#ifdef EXTRALARGE_DATASET
#define SIZE_M 1800
#define SIZE_N 2200
#endif


#endif /* !(SIZE_M SIZE_N) */

#define _PB_SIZE_M POLYBENCH_LOOP_BOUND(SIZE_M, size_m)
#define _PB_SIZE_N POLYBENCH_LOOP_BOUND(SIZE_N, size_n)


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

#endif /* !_BICG_H */
