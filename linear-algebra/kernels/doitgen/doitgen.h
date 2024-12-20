#ifndef _DOITGEN_H
#define _DOITGEN_H



/* Default to SMALL_DATASET. */
#if !defined(MINI_DATASET) && !defined(SMALL_DATASET)                          \
    && !defined(MEDIUM_DATASET) && !defined(LARGE_DATASET)                     \
    && !defined(EXTRALARGE_DATASET)
#define SMALL_DATASET
#endif

#if !defined(SIZE_NQ) && !defined(SIZE_NR) && !defined(SIZE_NP)
/* Define sample dataset sizes. */
#ifdef MINI_DATASET
#define SIZE_NQ 8
#define SIZE_NR 10
#define SIZE_NP 12
#endif

#ifdef SMALL_DATASET
#define SIZE_NQ 20
#define SIZE_NR 25
#define SIZE_NP 30
#endif

#ifdef MEDIUM_DATASET
#define SIZE_NQ 40
#define SIZE_NR 50
#define SIZE_NP 60
#endif

#ifdef LARGE_DATASET
#define SIZE_NQ 140
#define SIZE_NR 150
#define SIZE_NP 160
#endif

#ifdef EXTRALARGE_DATASET
#define SIZE_NQ 220
#define SIZE_NR 250
#define SIZE_NP 270
#endif


#endif /* !(SIZE_NQ SIZE_NR SIZE_NP) */

#define _PB_SIZE_NQ POLYBENCH_LOOP_BOUND(SIZE_NQ, size_nq)
#define _PB_SIZE_NR POLYBENCH_LOOP_BOUND(SIZE_NR, size_nr)
#define _PB_SIZE_NP POLYBENCH_LOOP_BOUND(SIZE_NP, size_np)


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

#endif /* !_DOITGEN_H */
