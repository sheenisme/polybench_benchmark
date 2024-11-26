#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

// Lower bound A >= B >= C >= D
#ifndef A
#define A (7)
#endif

#ifndef B
#define B (5)
#endif

#ifndef C
#define C (3)
#endif

#ifndef D
#define D (2)
#endif

// Upper bound M <= N <= K <= L
#ifndef M
#define M (40)
#endif

#ifndef N
#define N (132)
#endif

#ifndef K
#define K (250)
#endif

#ifndef L
#define L (360)
#endif

int timeval_subtract(struct timeval *result, struct timeval *x, struct timeval *y)
{
    if (x->tv_usec < y->tv_usec)
    {
        int nsec = (y->tv_usec - x->tv_usec) / 1000000 + 1;

        y->tv_usec -= 1000000 * nsec;
        y->tv_sec += nsec;
    }

    if (x->tv_usec - y->tv_usec > 1000000)
    {
        int nsec = (x->tv_usec - y->tv_usec) / 1000000;

        y->tv_usec += 1000000 * nsec;
        y->tv_sec -= nsec;
    }

    result->tv_sec = x->tv_sec - y->tv_sec;
    result->tv_usec = x->tv_usec - y->tv_usec;

    return x->tv_sec < y->tv_sec;
}

/** Main program */
int main(int argc, char *argv[])
{
    int ts_return = -1;
    struct timeval start, end, result;
    double tdiff = 0.0;

    double a[M][N][K];
    double alpha = 3.131415926;

    unsigned long int upper = 0;
    unsigned long int lower = 0;
    unsigned long int total = 0;

    // Initialize arrays
    for (int t = 0; t < M; t++)
        for (int i = 0; i < N; i++)
            for (int j = 0; j < K; j++)
                a[t][i][j] = (i * j + 1.101) * (t + 1.1001) / 9.181716151;

    gettimeofday(&start, 0);
    {
#pragma scop
        for (int t = A; t < M; t++)
        {
            for (int i = 2 * t; i < 3 * t; i++)
            {
                for (int j = t; j < 5 * t; j++)
                {
                    a[t][i][j] = (a[t][i][j] + alpha) * alpha;
                    total++;
                }
            }
        }
#pragma endscop
    }
    gettimeofday(&end, 0);
    // print results
    // for (int t = 0; t < M; t++)
    //     for (int i = 0; i < N; i++)
    //         for (int j = 0; j < K; j++)
    //             printf("%lf\t", a[t][i][j]);
    // printf("\n");

    // calculate time difference
    ts_return = timeval_subtract(&result, &end, &start);
    tdiff = (double)(result.tv_sec + result.tv_usec * 1.0e-6);

    // print time difference (ms)
    printf("Time taken =  %7.5lfms\n", tdiff * 1.0e3);

    // print domain size of upper and lower
    printf("total is: %lu, upper count is : %lu, lower count is : %lu. \n", total, upper, lower);

    return 0;
}