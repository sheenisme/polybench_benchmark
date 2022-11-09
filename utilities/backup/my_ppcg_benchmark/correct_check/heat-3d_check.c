/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* heat-3d.c: this file is part of PolyBench/C */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "heat-3d.h"

/* Include correct-check header. */
#include "correct-check.h"

/*  */
static void print_array_d(int n, double POLYBENCH_3D(A, N, N, N, n, n, n)) {
    int i, j, k;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("A");
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            for (k = 0; k < n; k++) {
                if ((i * n * n + j * n + k) % 20 == 0)
                    fprintf(POLYBENCH_DUMP_TARGET, "\n");
                fprintf(POLYBENCH_DUMP_TARGET, "%0.10lf ", A[i][j][k]);
            }
    POLYBENCH_DUMP_END("A");
    POLYBENCH_DUMP_FINISH;
}

static void print_array_f(int n, float POLYBENCH_3D(A, N, N, N, n, n, n)) {
    int i, j, k;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("A");
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            for (k = 0; k < n; k++) {
                if ((i * n * n + j * n + k) % 20 == 0)
                    fprintf(POLYBENCH_DUMP_TARGET, "\n");
                fprintf(POLYBENCH_DUMP_TARGET, "%0.10f ", A[i][j][k]);
            }
    POLYBENCH_DUMP_END("A");
    POLYBENCH_DUMP_FINISH;
}

/* */
static void get_array_d(int n, double POLYBENCH_3D(A, N, N, N, n, n, n)) {
    int i, j, k, r;
    char temp;

    r = POLYBENCH_SKIP_START;
    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            for (k = 0; k < n; k++) {
                if ((i * n * n + j * n + k) % 20 == 0)
                    r = POLYBENCH_SKIP_LINE_SEPARATOR();
                r = fscanf(POLYBENCH_READ_TARGET, "%lf ", &A[i][j][k]);
            }
    r = POLYBENCH_SKIP_END(temp);
    r = POLYBENCH_SKIP_FINISH;
}

static void get_array_f(int n, float POLYBENCH_3D(A, N, N, N, n, n, n)) {
    int i, j, k, r;
    char temp;

    r = POLYBENCH_SKIP_START;
    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < n; i++)
        for (j = 0; j < n; j++)
            for (k = 0; k < n; k++) {
                if ((i * n * n + j * n + k) % 20 == 0)
                    r = POLYBENCH_SKIP_LINE_SEPARATOR();
                r = fscanf(POLYBENCH_READ_TARGET, "%f ", &A[i][j][k]);
            }
    r = POLYBENCH_SKIP_END(temp);
    r = POLYBENCH_SKIP_FINISH;
}

/*  */
static void check_array_d_d(int n, double POLYBENCH_3D(d, N, N, N, n, n, n),
                            double POLYBENCH_3D(a, N, N, N, n, n, n)) {
    // 计算误差所用的变量
    double maxDiff = -1.0000000000, sumDiff = 0.0, diff, meanDiff;
    int i, j, k, numDiff = 0;

    // 计算误差表现
    for (i = 0; i < n; i++) {
        for (j = 0; j < n; j++) {
            for (k = 0; k < n; k++) {
#ifdef RELATIVE_ERROR
                diff = fabs(d[i][j][k] - a[i][j][k]) / fabs(d[i][j][k]);
#else
                diff = fabs(d[i][j][k] - a[i][j][k]);
#endif // RELATIVE_ERROR
                if (diff > 0.0f) {
#ifdef DEBUG
                    printf("diff at [%d][%d][%d] = %.20f \n", i, j, k, diff);
#endif
                    numDiff++;
                    sumDiff += diff;
                }
                if (diff > maxDiff) {
                    maxDiff = diff;
                }
            }
        }
    }
    meanDiff = sumDiff / ((double)n * n * n);
    printf("Num diff  = %d,\t", numDiff);
    printf("Sum diff  = %.8f,\t", sumDiff);
    printf("Mean diff = %.8f,\t", meanDiff);
    printf("Max diff  = %.8f,\n", maxDiff);
}

static void check_array_d_f(int n, double POLYBENCH_3D(d, N, N, N, n, n, n),
                            float POLYBENCH_3D(f, N, N, N, n, n, n)) {
    // 计算误差所用的变量
    double maxDiff = -1.0000000000, sumDiff = 0.0, diff, meanDiff;
    int i, j, k, numDiff = 0;

    // 计算误差表现
    for (i = 0; i < n; i++) {
        for (j = 0; j < n; j++) {
            for (k = 0; k < n; k++) {
#ifdef RELATIVE_ERROR
                diff = fabs(d[i][j][k] - f[i][j][k]) / fabs(d[i][j][k]);
#else
                diff = fabs(d[i][j][k] - f[i][j][k]);
#endif // RELATIVE_ERROR
                if (diff > 0.0f) {
#ifdef DEBUG
                    printf("diff at [%d][%d][%d] = %.20f \n", i, j, k, diff);
#endif
                    numDiff++;
                    sumDiff += diff;
                }
                if (diff > maxDiff) {
                    maxDiff = diff;
                }
            }
        }
    }
    meanDiff = sumDiff / ((double)n * n * n);
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
    int n = N;

    /* Variable declaration/allocation. */
    POLYBENCH_3D_ARRAY_DECL(A_d, double, N, N, N, n, n, n);
    POLYBENCH_3D_ARRAY_DECL(A_a, double, N, N, N, n, n, n);
    POLYBENCH_3D_ARRAY_DECL(A_f, float, N, N, N, n, n, n);

    /* Double */
    if (!freopen("../output/origion/heat-3d_double_result", "r", stdin))
        printf("将文件重定向为标准输入失败!\n");
    get_array_d(n, POLYBENCH_ARRAY(A_d));
    // polybench_prevent_dce(print_array_d(n, POLYBENCH_ARRAY(A_d)));

    /* Float */
    if (!freopen("../output/origion/heat-3d_float_result", "r", stdin))
        printf("将文件重定向为标准输入失败!\n");
    get_array_f(n, POLYBENCH_ARRAY(A_f));
    // polybench_prevent_dce(print_array_f(n, POLYBENCH_ARRAY(A_f)));

    char amp_addr[50] = "../output/amp_ppcg/heat-3d_";
    strcat(amp_addr, argv[1]);
    strcat(amp_addr, "_result");
    // printf("amp_addr is : %s \n", amp_addr);
    /*  AMP  */
    if (!freopen(amp_addr, "r", stdin))
        printf("将文件重定向为标准输入失败!\n");
    get_array_d(n, POLYBENCH_ARRAY(A_a));
    polybench_prevent_dce(print_array_d(n, POLYBENCH_ARRAY(A_a)));

    /* Run check. */
    printf(" AMP  Correctness is ,\t");
    check_array_d_d(n, POLYBENCH_ARRAY(A_d), POLYBENCH_ARRAY(A_a));

#ifdef FLOAT_SHOW_STR
    if (!strcmp(argv[1], FLOAT_SHOW_STR)) {
        printf("Float Correctness is ,\t");
        check_array_d_f(n, POLYBENCH_ARRAY(A_d), POLYBENCH_ARRAY(A_f));
    }
#endif // FLOAT_SHOW_STR

    /* Be clean. */
    POLYBENCH_FREE_ARRAY(A_d);
    POLYBENCH_FREE_ARRAY(A_a);
    POLYBENCH_FREE_ARRAY(A_f);

    return 1;
}
