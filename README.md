This repository is a dedicated repository for testing of `PrecTuner`, which is mainly based on the polybench benchmark.

Replicating data from our paper:
===

Part1  Getting Started Guide
---

### step1 install `PrecTuner` 

```shell
# prepare
sudo apt update && sudo apt upgrade -y
sudo apt-get install gcc g++ git vim make bc python python3-pip
sudo apt install automake autoconf libtool pkg-config libgmp3-dev libyaml-dev libclang-dev llvm clang
pip install pandas numpy matplotlib

cd /home/sheen/
mkdir lnlamp-install
git clone https://github.com/sheenisme/lnlamp.git

cd lnlamp/
./get_submodules.sh 
./autogen.sh 
./configure --prefix=/home/sheen/lnlamp-install

make
make install
```

For further installation help please refer to: https://repo.or.cz/ppcg.git.

### step2 install `LLVM`

```shell
# prepare
sudo apt install cmake

cd /home/sheen/
git clone https://github.com/sheenisme/llvm-project.git

cd llvm-project/
mkdir llvm-install
git checkout origin/release/12.x
cmake -S ./llvm -B llvm-build -G "Unix Makefiles" -DCMAKE_BUILD_TYPE="Debug" -DLLVM_VERSION_MAJOR="12"  -DLLVM_TARGETS_TO_BUILD="X86" -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt;openmp;polly" -DLLVM_BUILD_LLVM_DYLIB=ON -DLLVM_LINK_LLVM_DYLIB=ON -DCMAKE_INSTALL_PREFIX=/home/sheen/llvm-project/llvm-install

cd llvm-build/
make -j2
make install
```

**Note:** this process requires a lot of hard drive space, so make sure you have plenty of space.

For further installation help please refer to: https://github.com/llvm/llvm-project.

### step3 install `LuIs`

```shell
cd /home/sheen/
git clone https://github.com/sheenisme/TAFFO.git

cd TAFFO/
mkdir taffo-install
export LLVM_DIR=/home/sheen/llvm-project/llvm-install
cmake -S . -B build -DTAFFO_BUILD_ORTOOLS=ON -DCMAKE_INSTALL_PREFIX=/home/sheen/TAFFO/taffo-install

cd build/
make -j2
sudo make install
```

**Note:** This process requires downloading a number of dependencies from `github`. If you have a poor internet connection or a timeout error, please run the `cmake -S . -B build -DTAFFO_BUILD_ORTOOLS=ON -DCMAKE_INSTALL_PREFIX=/home/sheen/TAFFO/taffo-install` command several times until it works.

For further installation help please refer to: https://github.com/TAFFO-org/TAFFO.

### step4 install `Pluto`

```shell
# prepare
sudo apt-get install flex bison texinfo

cd /home/sheen/
git clone https://github.com/sheenisme/pluto.git

cd pluto/
mkdir pluto-install
git submodule init 
git submodule update
./autogen.sh
./configure --prefix=/home/sheen/pluto/pluto-install

make
make install
```

For further installation help please refer to: https://github.com/bondhugula/pluto.

### step5 Configuring environment

```shell
# setting pluto
export PATH=/home/sheen/pluto/pluto-install/bin:$PATH

# setting LLVM and TAFFO
export LLVM_DIR=/home/sheen/llvm-project/llvm-install
export PATH=/home/sheen/llvm-project/llvm-install/bin:/home/sheen/TAFFO/taffo-install/bin:$PATH
export LD_LIBRARY_PATH=/home/sheen/TAFFO/taffo-install/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
export LD_LIBRARY_PATH=/home/sheen/llvm-project/llvm-install/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# setting prectuner
export PATH=/home/sheen/lnlamp-install/bin:$PATH
export LD_LIBRARY_PATH=/home/sheen/lnlamp-install/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# setting polybench
export CPATH=/usr/local/include:/home/sheen/lnlamp/polybench_benchmark/utilities:$CPATH
```

First add these code to `/home/sheen/.bashrc` , and then executing `source .bashrc`.

**Now all tools are installed.**

### Some of the problems that may be encountered:

- The following error was encountered when installing `PrecTuner` :

```
config.status: error: in `/home/sheen/ppcg':
config.status: error: Something went wrong bootstrapping makefile fragments
    for automatic dependency tracking.  If GNU make was not used, consider
    re-running the configure script with MAKE="gmake" (or whatever is
    necessary).  You can also try re-running configure with the
    '--disable-dependency-tracking' option to at least be able to build
    the package (albeit without support for automatic dependency tracking).
See `config.log' for more details
```

 Perhaps this can be solved by executing the `sudo apt install make` command.

- The following error was encountered when installing `PrecTuner` :

```
configure: error: in `/home/sheen/ppcg/isl/interface':
configure: error: C++ compiler cannot create executables
See `config.log' for more details
configure: error: ./configure failed for interface
configure: error: ./configure failed for isl
```

Perhaps this can be solved by executing the `sudo apt-get install gcc g++` command.

- The following error was encountered when installing `PrecTuner` :


```
checking whether /usr/lib/llvm-11/bin/clang can find standard include files... no
checking for xcode-select... no
configure: error: Cannot find xcode-select
configure: error: ./configure failed for interface
configure: error: ./configure failed for isl
```

Perhaps this can be solved by executing the `sudo apt install clang` command.

- The following error was encountered when installing `pluto` :

```
checking flex version... configure: error: flex not found. Version 2.5.35 or greater is required.
checking for clan/Makefile... no
configure: error: configure in clan/ failed
```

Perhaps this can be solved by executing the `sudo apt-get install flex` command.

- The following error was encountered when installing `pluto` :

```
checking bison version... configure: error: bison not found. Version 2.4 or greater is required.
checking for clan/Makefile... no
configure: error: configure in clan/ failed
```

Perhaps this can be solved by executing the  `sudo apt-get install bison` command. 

- The following error was encountered when installing `pluto` :

```
  MAKEINFO candl.info
/home/sheen/pluto/candl/autoconf/missing: line 81: makeinfo: command not found
WARNING: 'makeinfo' is missing on your system.
         You should only need it if you modified a '.texi' file, or
         any other file indirectly affecting the aspect of the manual.
         You might want to install the Texinfo package:
         <https://www.gnu.org/software/texinfo/>
         The spurious makeinfo call might also be the consequence of
         using a buggy 'make' (AIX, DU, IRIX), in which case you might
         want to install GNU make:
         <https://www.gnu.org/software/make/>
make[4]: *** [Makefile:487: candl.info] Error 127
```

Perhaps this can be solved by executing the `sudo apt-get install texinfo` command. 

Part2  Reproduced Results
---

### 1. Reproduced the Effects of Performance Prediction

The prediction results can be reproduced by executing the following command:

```shell
cd /home/sheen/lnlamp/polybench_benchmark/
nohup ./lnlamp_tests_for_judgement.sh &
```

These commands will generate files: `nohup.out, scripts/benchmark_result_perf-Reliable.log, scripts/benchmark_test.log, and scripts/benchmark_mean_result.log`. The `nohup.out` contains the execution log of the `PrecTuner` and its prediction results; `scripts/benchmark_mean_result.log` and `scripts/benchmark_test.log` is the log of the empirically executed; `scripts/benchmark_result_perf-Reliable.log` is the empirically executed results automatically collated by the script.

**Figure 10** is drawn using the data from the  `nohup.out`  and `scripts/benchmark_result_perf-Reliable.log` files.

### 2. Reproduced the Ablation Study of the Optimizations

The results can be reproduced by executing the following command:

```shell
cd /home/sheen/lnlamp/polybench_benchmark/
nohup ./lnlamp_tests_for_performance.sh &
```

These commands will generate folders: `only-mix`, `schedule`, `schedule_mix`, `schedule_tile`, `schedule_tile_mix`. The results of the respective executions are recorded in `vra.txt` for each of these folders. It should be noted that the last column in  `vra.txt` is the performance speedup, and that all the relevant data from the execution is stored in the `vra` folder. However, as the execution results are stored, these `vra` folders may take up a large amount of hard disk storage space(A folder of that requires 10G), so please delete these runtime data in time to ensure that your machine has sufficient storage space.

**Figure 11** is drawn using the data from the `vra.txt` of `only-mix`, `schedule`, `schedule_mix`, `schedule_tile`, `schedule_tile_mix` folders.

### 3. Reproduced the Compatibility with Error Budgets

The result for an error threshold of `0.1` can be obtained with the following command:

```shell
cd /home/sheen/lnlamp/polybench_benchmark/
nohup ./lnlamp_tests_for_performance_err-thr.sh &
```

These commands will generate file folders-`temp_test_res_-e-0.1` in order to obtain runtime result data(error and performance acceleration),and generate file -`nohup.out` ,which contains the execution log and results of runs at an error threshold of `0.1`. 

The sixth line of the `lnlamp_tests_for_performance_err-thr.sh` script is `err_thr="-e 0.1",` modify `0.1` to `1`, `0.01`,  `0.001`, `0.0001`, `0.00001`, `0.000001`, `0.0000001`, `0.000001` in turn to obtain the results shown in **Figure 13**.

### 4. Reproduced the Comparison with the State of the Art

#### (1) Reproduced the `PrecTuner` performance

The test in this section is the same as **Reproduced the Ablation Study of the Optimizations**, so the corresponding data can be obtained directly from the latter.

#### (2) Reproduced the `LuIs` performance

The results can be reproduced by executing the following command:

```shell
cd /home/sheen/TAFFO/test/polybench-c-4.2.1-beta/
export LLVM_DIR=/home/sheen/llvm-project/llvm-install
nohup ./collect-fe-stats.sh luis_test_res &
```

These commands will generate folder-`luis_test_res` in order to obtain runtime result data(error and performance acceleration),and generate file -`nohup.out` ,which contains the execution log.

The  `LuIs` performance speedup in the last column in  `luis_test_res/vra.txt`. It should be noted that the Relative error and Absolute error data of  `LuIs` is in  the file - `luis_test_res/vra.txt`.

#### (3) Reproduced the `Pluto` performance

The results can be reproduced by executing the following command:

```shell
cd /home/sheen/pluto/polybench_benchmark
nohup ./pluto_part_test.sh &
```

These commands will generate folder-`pluto_test_result` in order to obtain runtime result data(error and performance acceleration), and generate file -`nohup.out` ,which contains the execution log.

The `Pluto` performance speedup in the last column in  `pluto_test_result/vra.txt`. 

**So, Figure 12 can be drawn using these data. Meanwhile the error data in table2 are also available by these data. **

### 5. Reproduced the Scalability to Parallel Execution

#### (1) Reproduced the `PrecTuner` parallel execution

The results can be reproduced by executing the following command:

```shell
cd /home/sheen/lnlamp/polybench_benchmark/
nohup ./lnlamp_tests_for_performance_omp.sh &
```

These commands will generate folders: `omp_test_res_-o_2`, `omp_test_res_-o_4`, `omp_test_res_-o_8`. The results of the respective executions are recorded in `vra.txt` for each of these folders. 

#### (2) Reproduced the `Pluto` parallel execution

The results can be reproduced by executing the following command:

```shell
cd /home/sheen/pluto/polybench_benchmark
nohup ./pluto_part_test_omp.sh &
```

These commands will generate folders: `pluto_test_result_2`, `pluto_test_result_4`, `pluto_test_result_8`. The results of the respective executions are recorded in `vra.txt` for each of these folders. 

**So, Figure 14 can be drawn using these data. **

### 6. Automatic generation and cleaning of configuration information

In addition, there are a number of `perl` scripts for automated testing in the `/home/sheen/lnlamp/polybench_benchmark/utilities` ,which can be executed to achieve the appropriate functionality with the following commands:

```shell
perl header-gen.pl ../         # generates header in each directory.
perl makefile-gen.pl ../ -cfg  # generates make files in each directory.
perl clean.pl ../              # runs make clean in each directory and then removes Makefile.
```

### 7. Some of the problems that may be encountered

- If `prectuner` does not output any results or hints, then please use the `cd` command to go to the root directory where the source code is located and re-execute the command. If the same problem still occurs, then please follow the error hints in the log file generated in the source code directory (for example: `lnlamp_internal_usage.py.log`) to solve the corresponding errors. And, in general, you only need to install the corresponding package or tool according to the prompt.
- If you encountered `lnlamp: error: PPCG Codegen meets errors` errors, Then please execute the `PPCG CMD` command immediately after it and solve the corresponding problem according to the error or prompt message of the command.  Generally, the command takes the form of `ppcg --target c --no-automatic-mixed-precision  <input>.c` or `ppcg --target c -R 50 <input>.c` 
- If you encountered `fatal error: 'polybench.h' file not found` errors, then execute the  `export CPATH=/home/sheen/lnlamp/polybench_benchmark/utilities:$CPATH` command can solve this error.


- If  some error(such as 124 or 127) were encountered when executing `heat-3d` by  `pluto` , perhaps you can resolve any problems you may encounter by executing the following command:

```shell
# compiler again
/home/sheen/llvm-project/llvm-install/bin/clang -I./stencils/heat-3d -I./utilities -I./ -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS -DCONF_GOOD -DLARGE_DATASET -lm -O3 build/heat-3d.out.1.taffotmp.ll -o build/heat-3d.pluto.out

# run and get result
./taffo_run.sh --times=20
./taffo_validate.py > result.txt
```

Part3 Other Notes
---

In addition, we provide a `Dockerfile`([https://github.com/sheenisme/lnlamp/blob/master/Dockerfile](https://github.com/sheenisme/lnlamp/blob/master/Dockerfile)) file for quick installation, but this installation is not recommended given the instability of performance testing in virtual machines.


Part4 Polybench description
---

The following is the original author's description in polybench:

      * * * * * * * * * * * * * * *
      * PolyBench/C 4.2.1 (beta)  *
      * * * * * * * * * * * * * * *

      Copyright (c) 2011-2016 the Ohio State University.

      Contact:
         Louis-Noel Pouchet <pouchet@cse.ohio-state.edu>
         Tomofumi Yuki <tomofumi.yuki@inria.fr>


      PolyBench is a benchmark suite of 30 numerical computations with
      static control flow, extracted from operations in various application
      domains (linear algebra computations, image processing, physics
      simulation, dynamic programming, statistics, etc.). PolyBench features
      include:
      - A single file, tunable at compile-time, used for the kernel
        instrumentation. It performs extra operations such as cache flushing
        before the kernel execution, and can set real-time scheduling to
        prevent OS interference.
      - Non-null data initialization, and live-out data dump.
      - Syntactic constructs to prevent any dead code elimination on the kernel.
      - Parametric loop bounds in the kernels, for general-purpose implementation.
      - Clear kernel marking, using pragma-based delimiters.


      PolyBench is currently available in C and in Fortran:
      - See PolyBench/C 4.2.1 for the C version
      - See PolyBench/Fortran 1.0 for the Fortran version (based on PolyBench/C 3.2)

      Available benchmarks (PolyBench/C 4.2.1)

      Benchmark Description
      2mm  2 Matrix Multiplications (alpha * A * B * C + beta * D)
      3mm  3 Matrix Multiplications ((A*B)*(C*D))
      adi  Alternating Direction Implicit solver
      atax  Matrix Transpose and Vector Multiplication
      bicg  BiCG Sub Kernel of BiCGStab Linear Solver
      cholesky Cholesky Decomposition
      correlation Correlation Computation
      covariance Covariance Computation
      deriche  Edge detection filter
      doitgen  Multi-resolution analysis kernel (MADNESS)
      durbin  Toeplitz system solver
      fdtd-2d  2-D Finite Different Time Domain Kernel
      gemm  Matrix-multiply C=alpha.A.B+beta.C
      gemver  Vector Multiplication and Matrix Addition
      gesummv  Scalar, Vector and Matrix Multiplication
      gramschmidt Gram-Schmidt decomposition
      head-3d  Heat equation over 3D data domain
      jacobi-1D 1-D Jacobi stencil computation
      jacobi-2D 2-D Jacobi stencil computation
      lu  LU decomposition
      ludcmp  LU decomposition followed by Forward Substitution
      mvt  Matrix Vector Product and Transpose
      nussinov Dynamic programming algorithm for sequence alignment
      seidel  2-D Seidel stencil computation
      symm  Symmetric matrix-multiply
      syr2k  Symmetric rank-2k update
      syrk  Symmetric rank-k update
      trisolv  Triangular solver
      trmm  Triangular matrix-multiply


      See the end of the README for mailing lists, instructions to use
      PolyBench, etc.

      --------------------
      * New in 4.2.1-beta:
      --------------------
       - Fix a bug in PAPI support, introduced in 4.2
       - Support PAPI 5.4.x

      -------------
      * New in 4.2:
      -------------
       - Fixed a bug in syr2k.
       - Changed the data initialization function of several benchmarks.
       - Minor updates in the documentation and PolyBench API.

      -------------
      * New in 4.1:
      -------------
       - Added LICENSE.txt
       - Fixed minor issues with cholesky both in documentation and implementation.
         (Reported by François Gindraud)
       - Simplified the macros for switching between data types. Now users
         may specify DATA_TYPE_IS_XXX where XXX is one of FLOAT/DOUBLE/INT
         to change all macros associated with data types.

      -------------
      * New in 4.0a:
      -------------
       - Fixed a bug in jacobi-1d (Reported by Sven Verdoolaege)

      -------------
      * New in 4.0:
      -------------

      This update includes many changes. Please see CHANGELOG for detailed
      list of changes. Most of the benchmarks have been edited/modified by
      Tomofumi Yuki, thanks to the feedback we have received by PolyBench
      users for the past few years.

      - Three benchmarks are out: dynprog, reg-detect, fdtd-apml.
      - Three benchmarks are in: nussinov, deriche, heat-3d.
      - Jacobi-1D and Jacobi-2D perform two time steps in one time loop
        iteration alternating the source and target fields, to avoid the
        field copy statement.
      - Almost all benchmarks have been edited to ensure the computation
        result matches the mathematical specification of the operation.
      - A major effort on documentation and harmonization of problem sizes
        and data allocations schemes.

      * Important Note:
      -----------------

      PolyBench/C 3.2 kernels had numerous implementation errors making
      their outputs to not match what is expected from the mathematical
      specification of the operation. Many of them did not influence the
      program behavior (e.g., the number and type of operations, data
      dependences, and overall control-flow was similar to the corrected
      implementation), however, some had non-negligible impact. These are
      described below.

       - adi: There was an off-by-one error, which made back substitution
         part of a pass in ADI to not depend on the forward pass, making the
         program fully tilable.
      - syrk: A typo on the loop bounds made the iteration space rectangular
         instead of triangular. This has led to additional dependences and
         two times more operations than intended.
      - trmm: A typo on the loop bounds led to the wrong half of the matrix
         being used in the computation. This led to additional dependences,
         making it harder to parallelize this kernel.
      - lu: An innermost loop was missing for the operation to be valid on
         general matrices. This cause the kernel to perform about half the
         work compared to a general implementation of LU decomposition. The
         new implementation is the generic LU decomposition.

      In addition, some of the kernels used "high-footprint" memory allocation for
      easier parallelization, where variables used in accumulation were fully
      expanded. These variables were changed to only use a scalar.


      -------------
      * New in 3.2:
      -------------

      - Rename the package to PolyBench/C, to prepare for the upcoming
        PolyBench/Fortran and PolyBench/GPU.
      - Fixed a typo in polybench.h, causing compilation problems for 5D arrays.
      - Fixed minor typos in correlation, atax, cholesky, fdtd-2d.
      - Added an option to build the test suite with constant loop bounds
        (default is parametric loop bounds)

      -------------
      * New in 3.1:
      -------------

      - Fixed a typo in polybench.h, causing compilation problems for 3D arrays.
      - Set by default heap arrays, stack arrays are now optional.

      -------------
      * New in 3.0:
      -------------

      - Multiple dataset sizes are predefined. Each file comes now with a .h
        header file defining the dataset.
      - Support of heap-allocated arrays. It uses a single malloc for the
        entire array region, the data allocated is cast into a C99
        multidimensional array.
      - One benchmark is out: gauss_filter
      - One benchmark is in: floyd-warshall
      - PAPI support has been greatly improved; it also can report the
        counters on a specific core to be set by the user.



      ----------------
      * Mailing lists:
      ----------------

      ** polybench-announces@lists.sourceforge.net:
      ---------------------------------------------

      Announces about releases of PolyBench.

      ** polybench-discussion@lists.sourceforge.net:
      ----------------------------------------------

      General discussions reg. PolyBench.



      -----------------------
      * Available benchmarks:
      -----------------------

      See utilities/benchmark_list for paths to each files.
      See doc/polybench.pdf for detailed description of the algorithms.



      ------------------------------
      * Sample compilation commands:
      ------------------------------

      ** To compile a benchmark without any monitoring:
      -------------------------------------------------

      $> gcc -I utilities -I linear-algebra/kernels/atax utilities/polybench.c linear-algebra/kernels/atax/atax.c -o atax_base


      ** To compile a benchmark with execution time reporting:
      --------------------------------------------------------

      $> gcc -O3 -I utilities -I linear-algebra/kernels/atax utilities/polybench.c linear-algebra/kernels/atax/atax.c -DPOLYBENCH_TIME -o atax_time


      ** To generate the reference output of a benchmark:
      ---------------------------------------------------

      $> gcc -O0 -I utilities -I linear-algebra/kernels/atax utilities/polybench.c linear-algebra/kernels/atax/atax.c -DPOLYBENCH_DUMP_ARRAYS -o atax_ref
      $> ./atax_ref 2>atax_ref.out



      -------------------------
      * Some available options:
      -------------------------

      They are all passed as macro definitions during compilation time (e.g,
      -Dname_of_the_option).

      ** Typical options:
      -------------------

      - POLYBENCH_TIME: output execution time (gettimeofday) [default: off]

      - MINI_DATASET, SMALL_DATASET, MEDIUM_DATASET, LARGE_DATASET,
        EXTRALARGE_DATASET: set the dataset size to be used
        [default: STANDARD_DATASET]

      - POLYBENCH_DUMP_ARRAYS: dump all live-out arrays on stderr [default: off]

      - POLYBENCH_STACK_ARRAYS: use stack allocation instead of malloc [default: off]


      ** Options that may lead to better performance:
      -----------------------------------------------

      - POLYBENCH_USE_RESTRICT: Use restrict keyword to allow compilers to
        assume absence of aliasing. [default: off]

      - POLYBENCH_USE_SCALAR_LB: Use scalar loop bounds instead of parametric ones.
        [default: off]

      - POLYBENCH_PADDING_FACTOR: Pad all dimensions of all arrays by this
        value [default: 0]

      - POLYBENCH_INTER_ARRAY_PADDING_FACTOR: Offset the starting address of
        polybench arrays allocated on the heap (default) by a multiple of
        this value [default: 0]

      - POLYBENCH_USE_C99_PROTO: Use standard C99 prototype for the functions.
        [default: off]


      ** Timing/profiling options:
      ----------------------------

      - POLYBENCH_PAPI: turn on papi timing (see below).

      - POLYBENCH_CACHE_SIZE_KB: cache size to flush, in kB [default: 33MB]

      - POLYBENCH_NO_FLUSH_CACHE: don't flush the cache before calling the
        timer [default: flush the cache]

      - POLYBENCH_CYCLE_ACCURATE_TIMER: Use Time Stamp Counter to monitor
        the execution time of the kernel [default: off]

      - POLYBENCH_LINUX_FIFO_SCHEDULER: use FIFO real-time scheduler for the
        kernel execution, the program must be run as root, under linux only,
        and compiled with -lc [default: off]



      ---------------
      * PAPI support:
      ---------------

      ** To compile a benchmark with PAPI support:
      --------------------------------------------

      $> gcc -O3 -I utilities -I linear-algebra/kernels/atax utilities/polybench.c linear-algebra/kernels/atax/atax.c -DPOLYBENCH_PAPI -lpapi -o atax_papi


      ** To specify which counter(s) to monitor:
      ------------------------------------------

      Edit utilities/papi_counters.list, and add 1 line per event to
      monitor. Each line (including the last one) must finish with a ',' and
      both native and standard events are supported.

      The whole kernel is run one time per counter (no multiplexing) and
      there is no sampling being used for the counter value.



      ------------------------------
      * Accurate performance timing:
      ------------------------------

      With kernels that have an execution time in the orders of a few tens
      of milliseconds, it is critical to validate any performance number by
      repeating several times the experiment. A companion script is
      available to perform reasonable performance measurement of a PolyBench.

      $> gcc -O3 -I utilities -I linear-algebra/kernels/atax utilities/polybench.c linear-algebra/kernels/atax/atax.c -DPOLYBENCH_TIME -o atax_time
      $> ./utilities/time_benchmark.sh ./atax_time

      This script will run five times the benchmark (that must be a
      PolyBench compiled with -DPOLYBENCH_TIME), eliminate the two extremal
      times, and check that the deviation of the three remaining does not
      exceed a given threshold, set to 5%.

      It is also possible to use POLYBENCH_CYCLE_ACCURATE_TIMER to use the
      Time Stamp Counter instead of gettimeofday() to monitor the number of
      elapsed cycles.



      ----------------------------------------
      * Generating macro-free benchmark suite:
      ----------------------------------------

      (from the root of the archive:)
      $> PARGS="-I utilities -DPOLYBENCH_TIME";
      $> for i in `cat utilities/benchmark_list`; do perl utilities/create_cpped_version.pl $i "$PARGS"; done

      This create for each benchmark file 'xxx.c' a new file
      'xxx.preproc.c'. The PARGS variable in the above example can be set to
      the desired configuration, for instance to create a full C99 version
      (parametric arrays):

      $> PARGS="-I utilities he-DPOLYBENCH_USE_C99_PROTO";
      $> for i in `cat utilities/benchmark_list`; do perl utilities/create_cpped_version.pl $i "$PARGS"; done



      ------------------
      * Utility scripts:
      ------------------
      create_cpped_version.pl: Used in the above for generating macro free version.

      makefile-gen.pl: generates make files in each directory. Options are globally
                       configurable through config.mk at polybench root.
        header-gen.pl: refers to 'polybench.spec' file and generates header in
                       each directory. Allows default problem sizes and datatype to
                       be configured without going into each header file.

          run-all.pl: compiles and runs each kernel.
            clean.pl: runs make clean in each directory and then removes Makefile.
