#ifndef POLYBENCH_CORRECT_CHECK_H
#define POLYBENCH_CORRECT_CHECK_H

#include <math.h>
#include <stdlib.h>

#define POLYBENCH_READ_TARGET stdin
#define POLYBENCH_SKIP_START \
    fscanf(POLYBENCH_READ_TARGET, "==BEGIN DUMP_ARRAYS==\n")
#define POLYBENCH_SKIP_FINISH \
    fscanf(POLYBENCH_READ_TARGET, "==END   DUMP_ARRAYS==\n")
#define POLYBENCH_SKIP_BEGIN(s) \
    fscanf(POLYBENCH_READ_TARGET, "begin dump: %s", &s)
#define POLYBENCH_SKIP_END(s) \
    fscanf(POLYBENCH_READ_TARGET, "\nend   dump: %s\n", &s)
#define POLYBENCH_SKIP_LINE_SEPARATOR() fscanf(POLYBENCH_DUMP_TARGET, "\n")

#define DATA_SCANF_MODIFIER(x)         \
    (typeof(x) == typeof(double)       \
         ? "%lf"                       \
         : (typeof(x) == typeof(float) \
                ? "%f"                 \
                : (typeof(x) == typeof(int) ? "%d" : "%s")))

/* Default Error type is ABSOLUTE_ERROR */
#ifdef USE_RELATIVE_ERROR_TYPE
#define RELATIVE_ERROR
#endif

/* Defalt show Float error result only once*/
#define FLOAT_SHOW_STR "100"

#endif