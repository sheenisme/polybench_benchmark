#ifndef _GEMM_H
#define _GEMM_H



/* Default to SMALL_DATASET. */
#if !defined(MINI_DATASET) && !defined(SMALL_DATASET)                          \
    && !defined(MEDIUM_DATASET) && !defined(LARGE_DATASET)                     \
    && !defined(EXTRALARGE_DATASET)
#define SMALL_DATASET
#endif

#if !defined(SIZE_NI) && !defined(SIZE_NJ) && !defined(SIZE_NK)
/* Define sample dataset sizes. */
#ifdef MINI_DATASET
#define SIZE_NI 20
#define SIZE_NJ 25
#define SIZE_NK 30
#endif

#ifdef SMALL_DATASET
#define SIZE_NI 60
#define SIZE_NJ 70
#define SIZE_NK 80
#endif

#ifdef MEDIUM_DATASET
#define SIZE_NI 200
#define SIZE_NJ 220
#define SIZE_NK 240
#endif

#ifdef LARGE_DATASET
#define SIZE_NI 1000
#define SIZE_NJ 1100
#define SIZE_NK 1200
#endif

#ifdef EXTRALARGE_DATASET
#define SIZE_NI 2000
#define SIZE_NJ 2300
#define SIZE_NK 2600
#endif


#endif /* !(SIZE_NI SIZE_NJ SIZE_NK) */

#define _PB_SIZE_NI POLYBENCH_LOOP_BOUND(SIZE_NI, size_ni)
#define _PB_SIZE_NJ POLYBENCH_LOOP_BOUND(SIZE_NJ, size_nj)
#define _PB_SIZE_NK POLYBENCH_LOOP_BOUND(SIZE_NK, size_nk)


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

#endif /* !_GEMM_H */
