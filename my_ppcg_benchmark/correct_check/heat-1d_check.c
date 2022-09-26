/*
 * Discretized 2D heat equation stencil with non periodic boundary conditions
 * Adapted from Pochoir test bench
 *
 * Irshad Pananilath: irshad@csa.iisc.ernet.in
 */
/* heat-1d.c: this file is part of PolyBench/C, which is extend by sheen song*/

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "heat-1d.h"

/* Include correct-check header . */
#include "correct-check.h"

/*  */
static void print_array_d(int n, int m, double POLYBENCH_2D(A, M, N, m, n)) {
    int i;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("A");
    for (i = 0; i < n; i++) {
        if (i % 20 == 0)
            fprintf(POLYBENCH_DUMP_TARGET, "\n");
        fprintf(POLYBENCH_DUMP_TARGET, "%0.10lf ", A[(_PB_TSTEPS - 1) % 2][i]);
    }
    POLYBENCH_DUMP_END("A");
    POLYBENCH_DUMP_FINISH;
}

static void print_array_f(int n, int m, float POLYBENCH_2D(A, M, N, m, n)) {
    int i;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("A");
    for (i = 0; i < n; i++) {
        if (i % 20 == 0)
            fprintf(POLYBENCH_DUMP_TARGET, "\n");
        fprintf(POLYBENCH_DUMP_TARGET, "%0.10f ", A[(_PB_TSTEPS - 1) % 2][i]);
    }
    POLYBENCH_DUMP_END("A");
    POLYBENCH_DUMP_FINISH;
}

/* */
static void get_array_d(int n, int m, double POLYBENCH_2D(A, M, N, m, n)) {
    int i, r;
    char temp;

    r = POLYBENCH_SKIP_START;
    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < n; i++) {
        if (i % 20 == 0)
            r = POLYBENCH_SKIP_LINE_SEPARATOR();
        r = fscanf(POLYBENCH_READ_TARGET, "%lf", &A[(_PB_TSTEPS - 1) % 2][i]);
    }
    r = POLYBENCH_SKIP_END(temp);
    r = POLYBENCH_SKIP_FINISH;
}

static void get_array_f(int n, int m, float POLYBENCH_2D(A, M, N, m, n)) {
    int i, r;
    char temp;

    r = POLYBENCH_SKIP_START;
    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < n; i++) {
        if (i % 20 == 0)
            r = POLYBENCH_SKIP_LINE_SEPARATOR();
        r = fscanf(POLYBENCH_READ_TARGET, "%f", &A[(_PB_TSTEPS - 1) % 2][i]);
    }
    r = POLYBENCH_SKIP_END(temp);
    r = POLYBENCH_SKIP_FINISH;
}

/*   */
static void check_array_d_d(int n, int m, double POLYBENCH_2D(d, M, N, m, n),
                            double POLYBENCH_2D(a, M, N, m, n)) {
    // 计算误差所用的变量
    double maxDiff = -1.0000000000, sumDiff = 0.0, diff, meanDiff;
    int numDiff = 0;

    // 计算误差表现
    for (int i = 0; i < n; i++) {
#ifdef RELATIVE_ERROR
        diff = fabs(d[(_PB_TSTEPS - 1) % 2][i] - a[(_PB_TSTEPS - 1) % 2][i]) / fabs(d[(_PB_TSTEPS - 1) % 2][i]);
#else
        diff = fabs(d[(_PB_TSTEPS - 1) % 2][i] - a[(_PB_TSTEPS - 1) % 2][i]);
#endif // RELATIVE_ERROR
        if (diff > 0.0f) {
#ifdef DEBUG
            printf("diff at [%d] = %.20f \n", i, diff);
#endif
            numDiff++;
            sumDiff += diff;
        }
        if (diff > maxDiff) {
            maxDiff = diff;
        }
    }
    meanDiff = sumDiff / ((double)n);
    printf("Num diff  = %d,\t", numDiff);
    printf("Sum diff  = %.8f,\t", sumDiff);
    printf("Mean diff = %.8f,\t", meanDiff);
    printf("Max diff  = %.8f,\n", maxDiff);
}

static void check_array_d_f(int n, int m, double POLYBENCH_2D(d, M, N, m, n),
                            float POLYBENCH_2D(f, M, N, m, n)) {
    // 计算误差所用的变量
    double maxDiff = -1.0000000000, sumDiff = 0.0, diff, meanDiff;
    int numDiff = 0;

    // 计算误差表现
    for (int i = 0; i < n; i++) {
#ifdef RELATIVE_ERROR
        diff = fabs(d[(_PB_TSTEPS - 1) % 2][i] - f[(_PB_TSTEPS - 1) % 2][i]) / fabs(d[(_PB_TSTEPS - 1) % 2][i]);
#else
        diff = fabs(d[(_PB_TSTEPS - 1) % 2][i] - f[(_PB_TSTEPS - 1) % 2][i]);
#endif // RELATIVE_ERROR
        if (diff > 0.0f) {
#ifdef DEBUG
            printf("diff at [%d] = %.20f \n", i, diff);
#endif
            numDiff++;
            sumDiff += diff;
        }
        if (diff > maxDiff) {
            maxDiff = diff;
        }
    }
    meanDiff = sumDiff / ((double)n);
    printf("Num diff  = %d,\t", numDiff);
    printf("Sum diff  = %.8f,\t", sumDiff);
    printf("Mean diff = %.8f,\t", meanDiff);
    printf("Max diff  = %.8f,\n", maxDiff);
}

int main(int argc, char **argv) {
    if (argc != 2) {
        printf("@ERROR:\n       the argc is not 2, please check!");
        return 0;
    }

    /* Retrieve problem size. */
    int tsteps = TSTEPS;
    int m = M;
    int n = N;

    /* Variable declaration/allocation. */
    POLYBENCH_2D_ARRAY_DECL(A_d, double, M, N, m, n);
    POLYBENCH_2D_ARRAY_DECL(A_a, double, M, N, m, n);
    POLYBENCH_2D_ARRAY_DECL(A_f, float, M, N, m, n);

    /* Double */
    if (!freopen("../output/origion/heat-1d_double_result", "r", stdin))
        printf("将文件重定向为标准输入失败!\n");
    get_array_d(n, m, POLYBENCH_ARRAY(A_d));
    // polybench_prevent_dce(print_array_d(n, m, POLYBENCH_ARRAY(A_d)));

    /* Float */
    if (!freopen("../output/origion/heat-1d_float_result", "r", stdin))
        printf("将文件重定向为标准输入失败!\n");
    get_array_f(n, m, POLYBENCH_ARRAY(A_f));
    // polybench_prevent_dce(print_array_f(n, m, POLYBENCH_ARRAY(A_f)));

    char amp_addr[50] = "../output/amp_ppcg/heat-1d_";
    strcat(amp_addr, argv[1]);
    strcat(amp_addr, "_result");
    // printf("amp_addr is : %s \n", amp_addr);
    /* AMP */
    if (!freopen(amp_addr, "r", stdin))
        printf("将文件重定向为标准输入失败!\n");
    get_array_d(n, m, POLYBENCH_ARRAY(A_a));
    polybench_prevent_dce(print_array_d(n, m, POLYBENCH_ARRAY(A_a)));

    /* Run check. */
    printf(" AMP  Correctness is ,\t");
    check_array_d_d(n, m, POLYBENCH_ARRAY(A_d), POLYBENCH_ARRAY(A_a));

#ifdef FLOAT_SHOW_STR
    if (!strcmp(argv[1], FLOAT_SHOW_STR)) {
        printf("Float Correctness is ,\t");
        check_array_d_f(n, m, POLYBENCH_ARRAY(A_d), POLYBENCH_ARRAY(A_f));
    }
#endif // FLOAT_SHOW_STR

    /* Be clean. */
    POLYBENCH_FREE_ARRAY(A_d);
    POLYBENCH_FREE_ARRAY(A_a);
    POLYBENCH_FREE_ARRAY(A_f);

    return 1;
}
