#ifndef _2MM_H
#define _2MM_H



/* Default to SMALL_DATASET. */
#if !defined(MINI_DATASET) && !defined(SMALL_DATASET)                          \
    && !defined(MEDIUM_DATASET) && !defined(LARGE_DATASET)                     \
    && !defined(EXTRALARGE_DATASET)
#define SMALL_DATASET
#endif

#if !defined(SIZE_NI) && !defined(SIZE_NJ) && !defined(SIZE_NK)                \
    && !defined(SIZE_NL)
/* Define sample dataset sizes. */
#ifdef MINI_DATASET
#define SIZE_NI 16
#define SIZE_NJ 18
#define SIZE_NK 22
#define SIZE_NL 24
#endif

#ifdef SMALL_DATASET
#define SIZE_NI 40
#define SIZE_NJ 50
#define SIZE_NK 70
#define SIZE_NL 80
#endif

#ifdef MEDIUM_DATASET
#define SIZE_NI 180
#define SIZE_NJ 190
#define SIZE_NK 210
#define SIZE_NL 220
#endif

#ifdef LARGE_DATASET
#define SIZE_NI 800
#define SIZE_NJ 900
#define SIZE_NK 1100
#define SIZE_NL 1200
#endif

#ifdef EXTRALARGE_DATASET
#define SIZE_NI 1600
#define SIZE_NJ 1800
#define SIZE_NK 2200
#define SIZE_NL 2400
#endif


#endif /* !(SIZE_NI SIZE_NJ SIZE_NK SIZE_NL) */

#define _PB_SIZE_NI POLYBENCH_LOOP_BOUND(SIZE_NI, size_ni)
#define _PB_SIZE_NJ POLYBENCH_LOOP_BOUND(SIZE_NJ, size_nj)
#define _PB_SIZE_NK POLYBENCH_LOOP_BOUND(SIZE_NK, size_nk)
#define _PB_SIZE_NL POLYBENCH_LOOP_BOUND(SIZE_NL, size_nl)


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

#endif /* !_2MM_H */
