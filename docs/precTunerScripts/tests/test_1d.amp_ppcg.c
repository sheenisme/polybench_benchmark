#include <assert.h>
#include <stdio.h>
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
#define M (128)
#endif

#ifndef N
#define N (132)
#endif

#ifndef K
#define K (140)
#endif

#ifndef L
#define L (149)
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

    double a[M];
    double alpha = 3.131415926;

    unsigned long int upper = 0;
    unsigned long int lower = 0;
    unsigned long int total = 0;

    // Initialize arrays
    for (int i = 0; i < M; i++)
        a[i] = i * 1.0 / 3.1314;

    gettimeofday(&start, 0);
    {
        /* ppcg generated CPU code with AMP */
        
        float amp_lower_a[61];
        float amp_lower_alpha;
        unsigned long amp_lower_total;
        {
          for (int c0 = 7; c0 <= 67; c0 += 1)
            a[c0] += alpha;
          for (int c0 = 7; c0 <= 67; c0 += 1)
            total++;
          // amp_kernel
          // amp_lower
          {
            for (int c0 = 0; c0 <= 60; c0 += 1)
              amp_lower_a[c0] = (float)a[c0 + 67];
            amp_lower_alpha = (float)alpha;
            amp_lower_total = (unsigned long)total;
            for (int c0 = 67; c0 <= 127; c0 += 1)
              amp_lower_a[c0 - 67] += amp_lower_alpha;
            for (int c0 = 67; c0 <= 127; c0 += 1)
              amp_lower_total++;
            total = (unsigned long)amp_lower_total;
            for (int c0 = 0; c0 <= 60; c0 += 1)
              a[c0 + 67] = (double)amp_lower_a[c0];
          }
        }
    }
    gettimeofday(&end, 0);
    // print results
    // for (int i = 0; i < M; i++)
    //     printf("%lf\t", a[i]);
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