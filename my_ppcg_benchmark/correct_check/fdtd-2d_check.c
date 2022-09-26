/**
 * This version is stamped on May 10, 2016
 *
 * Contact:
 *   Louis-Noel Pouchet <pouchet.ohio-state.edu>
 *   Tomofumi Yuki <tomofumi.yuki.fr>
 *
 * Web address: http://polybench.sourceforge.net
 */
/* fdtd-2d.c: this file is part of PolyBench/C */

#include <math.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Include polybench common header. */
#include <polybench.h>

/* Include benchmark-specific header. */
#include "fdtd-2d.h"

/* Include correct-check header . */
#include "correct-check.h"

/*  */
static void print_array_d(int nx, int ny,
                          DATA_TYPE POLYBENCH_2D(ex, NX, NY, nx, ny),
                          DATA_TYPE POLYBENCH_2D(ey, NX, NY, nx, ny),
                          DATA_TYPE POLYBENCH_2D(hz, NX, NY, nx, ny)) {
    int i, j;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("ex");
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                fprintf(POLYBENCH_DUMP_TARGET, "\n");
            fprintf(POLYBENCH_DUMP_TARGET, "%0.10lf ", ex[i][j]);
        }
    POLYBENCH_DUMP_END("ex");
    POLYBENCH_DUMP_FINISH;

    POLYBENCH_DUMP_BEGIN("ey");
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                fprintf(POLYBENCH_DUMP_TARGET, "\n");
            fprintf(POLYBENCH_DUMP_TARGET, "%0.10lf ", ey[i][j]);
        }
    POLYBENCH_DUMP_END("ey");

    POLYBENCH_DUMP_BEGIN("hz");
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                fprintf(POLYBENCH_DUMP_TARGET, "\n");
            fprintf(POLYBENCH_DUMP_TARGET, "%0.10lf ", hz[i][j]);
        }
    POLYBENCH_DUMP_END("hz");
}

static void print_array_f(int nx, int ny,
                          float POLYBENCH_2D(ex, NX, NY, nx, ny),
                          float POLYBENCH_2D(ey, NX, NY, nx, ny),
                          float POLYBENCH_2D(hz, NX, NY, nx, ny)) {
    int i, j;

    POLYBENCH_DUMP_START;
    POLYBENCH_DUMP_BEGIN("ex");
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                fprintf(POLYBENCH_DUMP_TARGET, "\n");
            fprintf(POLYBENCH_DUMP_TARGET, "%0.10f ", ex[i][j]);
        }
    POLYBENCH_DUMP_END("ex");
    POLYBENCH_DUMP_FINISH;

    POLYBENCH_DUMP_BEGIN("ey");
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                fprintf(POLYBENCH_DUMP_TARGET, "\n");
            fprintf(POLYBENCH_DUMP_TARGET, "%0.10f ", ey[i][j]);
        }
    POLYBENCH_DUMP_END("ey");

    POLYBENCH_DUMP_BEGIN("hz");
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                fprintf(POLYBENCH_DUMP_TARGET, "\n");
            fprintf(POLYBENCH_DUMP_TARGET, "%0.10f ", hz[i][j]);
        }
    POLYBENCH_DUMP_END("hz");
}

/* */
static void get_array_d(int nx, int ny, double POLYBENCH_2D(ex, NX, NY, nx, ny),
                        double POLYBENCH_2D(ey, NX, NY, nx, ny),
                        double POLYBENCH_2D(hz, NX, NY, nx, ny)) {
    int i, j, r;
    char temp;

    r = POLYBENCH_SKIP_START;
    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                r = POLYBENCH_SKIP_LINE_SEPARATOR();
            r = fscanf(POLYBENCH_READ_TARGET, "%lf", &ex[i][j]);
        }
    r = POLYBENCH_SKIP_END(temp);
    r = POLYBENCH_SKIP_FINISH;

    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                r = POLYBENCH_SKIP_LINE_SEPARATOR();
            r = fscanf(POLYBENCH_READ_TARGET, "%lf", &ey[i][j]);
        }
    r = POLYBENCH_SKIP_END(temp);

    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                r = POLYBENCH_SKIP_LINE_SEPARATOR();
            r = fscanf(POLYBENCH_READ_TARGET, "%lf", &hz[i][j]);
        }
    r = POLYBENCH_SKIP_END(temp);
}

static void get_array_f(int nx, int ny, float POLYBENCH_2D(ex, NX, NY, nx, ny),
                        float POLYBENCH_2D(ey, NX, NY, nx, ny),
                        float POLYBENCH_2D(hz, NX, NY, nx, ny)) {
    int i, j, r;
    char temp;

    r = POLYBENCH_SKIP_START;
    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                r = POLYBENCH_SKIP_LINE_SEPARATOR();
            r = fscanf(POLYBENCH_READ_TARGET, "%f", &ex[i][j]);
        }
    r = POLYBENCH_SKIP_END(temp);
    r = POLYBENCH_SKIP_FINISH;

    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                r = POLYBENCH_SKIP_LINE_SEPARATOR();
            r = fscanf(POLYBENCH_READ_TARGET, "%f", &ey[i][j]);
        }
    r = POLYBENCH_SKIP_END(temp);

    r = POLYBENCH_SKIP_BEGIN(temp);
    for (i = 0; i < nx; i++)
        for (j = 0; j < ny; j++) {
            if ((i * nx + j) % 20 == 0)
                r = POLYBENCH_SKIP_LINE_SEPARATOR();
            r = fscanf(POLYBENCH_READ_TARGET, "%f", &hz[i][j]);
        }
    r = POLYBENCH_SKIP_END(temp);
}

/*   */
static void check_array_d_d(int nx, int ny,
                            double POLYBENCH_2D(d, NX, NY, nx, ny),
                            double POLYBENCH_2D(a, NX, NY, nx, ny)) {
    // 计算误差所用的变量
    double maxDiff = -1.0000000000, sumDiff = 0.0, diff, meanDiff;
    int i, j, numDiff = 0;

    // 计算误差表现
    for (i = 0; i < nx; i++) {
        for (j = 0; j < ny; j++) {
#ifdef RELATIVE_ERROR
            diff = fabs(d[i][j] - a[i][j]) / fabs(d[i][j]);
#else
            diff = fabs(d[i][j] - a[i][j]);
#endif // RELATIVE_ERROR
            if (diff > 0.0f) {
#ifdef DEBUG
                printf("diff at [%d][%d] = %.20f \n", i, j, diff);
#endif
                numDiff++;
                sumDiff += diff;
            }
            if (diff > maxDiff) {
                maxDiff = diff;
            }
        }
    }
    meanDiff = sumDiff / ((double)nx * ny);
    printf("Num diff  = %d,\t", numDiff);
    printf("Sum diff  = %.8f,\t", sumDiff);
    printf("Mean diff = %.8f,\t", meanDiff);
    printf("Max diff  = %.8f,\n", maxDiff);
}

static void check_array_d_f(int nx, int ny,
                            double POLYBENCH_2D(d, NX, NY, nx, ny),
                            float POLYBENCH_2D(f, NX, NY, nx, ny)) {
    // 计算误差所用的变量
    double maxDiff = -1.0000000000, sumDiff = 0.0, diff, meanDiff;
    int i, j, numDiff = 0;

    // 计算误差表现
    for (i = 0; i < nx; i++) {
        for (j = 0; j < ny; j++) {
#ifdef RELATIVE_ERROR
            diff = fabs(d[i][j] - f[i][j]) / fabs(d[i][j]);
#else
            diff = fabs(d[i][j] - f[i][j]);
#endif // RELATIVE_ERROR
            if (diff > 0.0f) {
#ifdef DEBUG
                printf("diff at [%d][%d] = %.20f \n", i, j, diff);
#endif
                numDiff++;
                sumDiff += diff;
            }
            if (diff > maxDiff) {
                maxDiff = diff;
            }
        }
    }
    meanDiff = sumDiff / ((double)nx * ny);
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
    int nx = NX;
    int ny = NY;

    /* Variable declaration/allocation. */
    POLYBENCH_2D_ARRAY_DECL(ex_d, double, NX, NY, nx, ny);
    POLYBENCH_2D_ARRAY_DECL(ey_d, double, NX, NY, nx, ny);
    POLYBENCH_2D_ARRAY_DECL(hz_d, double, NX, NY, nx, ny);

    POLYBENCH_2D_ARRAY_DECL(ex_a, double, NX, NY, nx, ny);
    POLYBENCH_2D_ARRAY_DECL(ey_a, double, NX, NY, nx, ny);
    POLYBENCH_2D_ARRAY_DECL(hz_a, double, NX, NY, nx, ny);

    POLYBENCH_2D_ARRAY_DECL(ex_f, float, NX, NY, nx, ny);
    POLYBENCH_2D_ARRAY_DECL(ey_f, float, NX, NY, nx, ny);
    POLYBENCH_2D_ARRAY_DECL(hz_f, float, NX, NY, nx, ny);

    /* Double */
    if (!freopen("../output/origion/fdtd-2d_double_result", "r", stdin))
        printf("将文件重定向为标准输入失败! \n");
    get_array_d(nx, ny, POLYBENCH_ARRAY(ex_d), POLYBENCH_ARRAY(ey_d), POLYBENCH_ARRAY(hz_d));
    // polybench_prevent_dce(print_array_d(nx, ny, POLYBENCH_ARRAY(ex_d), POLYBENCH_ARRAY(ey_d), POLYBENCH_ARRAY(hz_d)));

    /* Float */
    if (!freopen("../output/origion/fdtd-2d_float_result", "r", stdin))
        printf("将文件重定向为标准输入失败! \n");
    get_array_f(nx, ny, POLYBENCH_ARRAY(ex_f), POLYBENCH_ARRAY(ey_f), POLYBENCH_ARRAY(hz_f));
    // polybench_prevent_dce(print_array_f(nx, ny, POLYBENCH_ARRAY(ex_f), POLYBENCH_ARRAY(ey_f), POLYBENCH_ARRAY(hz_f)));

    char amp_addr[50] = "../output/amp_ppcg/fdtd-2d_";
    strcat(amp_addr, argv[1]);
    strcat(amp_addr, "_result");
    // printf("amp_addr is : %s \n", amp_addr);
    /* AMP */
    if (!freopen(amp_addr, "r", stdin))
        printf("将文件重定向为标准输入失败! \n");
    get_array_d(nx, ny, POLYBENCH_ARRAY(ex_a), POLYBENCH_ARRAY(ey_a), POLYBENCH_ARRAY(hz_a));
    polybench_prevent_dce(print_array_d(nx, ny, POLYBENCH_ARRAY(ex_a), POLYBENCH_ARRAY(ey_a), POLYBENCH_ARRAY(hz_a)));

    /* Run check. */
    printf(" AMP  Correctness is ,\t");
    printf("Array(ex) result,\t");
    check_array_d_d(nx, ny, POLYBENCH_ARRAY(ex_d), POLYBENCH_ARRAY(ex_a));
    printf(" AMP  Correctness is ,\t");
    printf("Array(ey) result,\t");
    check_array_d_d(nx, ny, POLYBENCH_ARRAY(ey_d), POLYBENCH_ARRAY(ey_a));
    printf(" AMP  Correctness is ,\t");
    printf("Array(hz) result,\t");
    check_array_d_d(nx, ny, POLYBENCH_ARRAY(hz_d), POLYBENCH_ARRAY(hz_a));

#ifdef FLOAT_SHOW_STR
    if (!strcmp(argv[1], FLOAT_SHOW_STR)) {
        printf("Float Correctness is ,\t");
        printf("Array(ex) result,\t");
        check_array_d_f(nx, ny, POLYBENCH_ARRAY(ex_d), POLYBENCH_ARRAY(ex_f));
        printf("Float Correctness is ,\t");
        printf("Array(ey) result,\t");
        check_array_d_f(nx, ny, POLYBENCH_ARRAY(ey_d), POLYBENCH_ARRAY(ey_f));
        printf("Float Correctness is ,\t");
        printf("Array(hz) result,\t");
        check_array_d_f(nx, ny, POLYBENCH_ARRAY(hz_d), POLYBENCH_ARRAY(hz_f));
    }
#endif // FLOAT_SHOW_STR

    /* Be clean. */
    POLYBENCH_FREE_ARRAY(ex_d);
    POLYBENCH_FREE_ARRAY(ey_d);
    POLYBENCH_FREE_ARRAY(hz_d);

    POLYBENCH_FREE_ARRAY(ex_a);
    POLYBENCH_FREE_ARRAY(ey_a);
    POLYBENCH_FREE_ARRAY(hz_a);

    POLYBENCH_FREE_ARRAY(ex_f);
    POLYBENCH_FREE_ARRAY(ey_f);
    POLYBENCH_FREE_ARRAY(hz_f);

    return 1;
}
