#!/usr/bin/perl

# Generates Makefile for each benchmark in polybench
# Expects to be executed from root folder of polybench
#
# Written by Tomofumi Yuki, 11/21 2014
#

my $GEN_CONFIG = 0;
my $TARGET_DIR = ".";

if ($#ARGV !=0 && $#ARGV != 1) {
   printf("usage perl makefile-gen.pl output-dir [-cfg]\n");
   printf("  -cfg option generates config.mk in the output-dir.\n");
   exit(1);
}



foreach my $arg (@ARGV) {
   if ($arg =~ /-cfg/) {
      $GEN_CONFIG = 1;
   } elsif (!($arg =~ /^-/)) {
      $TARGET_DIR = $arg;
   }
}


my %categories = (
   'linear-algebra/blas' => 3,
   'linear-algebra/kernels' => 3,
   'linear-algebra/solvers' => 3,
   'datamining' => 2,
   'stencils' => 2,
   'medley' => 2
);

my %extra_flags = (
   'cholesky' => '-lm',
   'gramschmidt' => '-lm',
   'correlation' => '-lm',
   'deriche' => '-lm'
);

# get abs_path of the script
use Cwd 'abs_path';
my $script_path = abs_path($0);
$script_path =~ s/\/[^\/]+$//;

foreach $key (keys %categories) {
   my $target = $TARGET_DIR.'/'.$key;
   opendir DIR, $target or die "directory $target not found.\n";
   while (my $dir = readdir DIR) {
        next if ($dir=~'^\..*');
        next if (!(-d $target.'/'.$dir));

	my $kernel = $dir;
        my $file = $target.'/'.$dir.'/Makefile';
		my $csynthFile = $target.'/'.$dir.'/csynth.tcl';
        my $polybenchRoot = '../'x$categories{$key};
        my $configFile = $polybenchRoot.'config.mk';
		my $jsonConfigFile = $polybenchRoot.'config.json';
        my $utilityDir = $polybenchRoot.'utilities'; 

        open FILE, ">$file" or die "failed to open $file.";

print FILE << "EOF";
KERNEL=$kernel

include $configFile

EXTRA_FLAGS=$extra_flags{$kernel}

RATE ?= 50

# please set $utilityDir or $script_path in CPATH.
ifeq (\$(findstring $utilityDir,\$(CPATH)),)
CPATH := \$(CPATH):$utilityDir
export CPATH
endif

get-amp: ${kernel}.c
	@ echo "[Step] Generating AMP version: ${kernel}-amp-\${RATE}.c"
	\${PPCG} \${PPCG_TARGET} \${PPCG_SCHED_FLAGS} \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} -R \${RATE} ${kernel}.c -o ${kernel}-amp-\${RATE}.c > /dev/null 2>&1

get-ppcg:
	@ echo "[Step] Generating PPCG version: ${kernel}-ppcg.c"
	\${PPCG} \${PPCG_TARGET} \${PPCG_SCHED_FLAGS} \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} --no-automatic-mixed-precision ${kernel}.c -o ${kernel}-ppcg.c > /dev/null 2>&1

clang2mlir: get-ppcg get-amp
	@ echo "[Step] Translating C to MLIR with cgeist..."
	\${CGEIST}  \${CGEIST_FLAGS} \${CGEIST_LIB} \${CGEIST_INC} -I$utilityDir ${kernel}-amp-\${RATE}.c -o ${kernel}-amp-\${RATE}.mlir
	\${CGEIST}  \${CGEIST_FLAGS} \${CGEIST_LIB} \${CGEIST_INC} -I$utilityDir ${kernel}-ppcg.c -o ${kernel}-ppcg.mlir

extract-kernel: clang2mlir
	@ echo "[Step] Extracting kernel function(s) from MLIR by awk command..."
	\@awk '\\
		BEGIN { inside_block = 0; keep_header = 1; } \\
		/^[ \\t]*module/ { \\
			keep_header = 0; \\
		} \\
		keep_header { \\
			print; \\
			next; \\
		} \\
		/func.*\@kernel_/ { \\
			inside_block = 1; \\
			print; \\
			next; \\
		} \\
		inside_block { \\
			print; \\
			if (/return/ && \$\$0 ~ /\\}\\\$\$\/) { \\
				inside_block = 0; \\
				next; \\
			} \\
			if (/return/) { \\
				inside_block = 2; \\
			} \\
			if (inside_block == 2 && /\\}/) { \\
				inside_block = 0; \\
			} \\
		} \\
	' ${kernel}-amp-\${RATE}.mlir > kernel_${kernel}-amp-\${RATE}.tmp.mlir
	\@awk '\\
		BEGIN { inside_block = 0; keep_header = 1; } \\
		/^[ \\t]*module/ { \\
			keep_header = 0; \\
		} \\
		keep_header { \\
			print; \\
			next; \\
		} \\
		/func.*\@kernel_/ { \\
			inside_block = 1; \\
			print; \\
			next; \\
		} \\
		inside_block { \\
			print; \\
			if (/return/ && \$\$0 ~ /\\}\\\$\$\/) { \\
				inside_block = 0; \\
				next; \\
			} \\
			if (/return/) { \\
				inside_block = 2; \\
			} \\
			if (inside_block == 2 && /\\}/) { \\
				inside_block = 0; \\
			} \\
		} \\
	' ${kernel}-ppcg.mlir > kernel_${kernel}-ppcg.tmp.mlir

optimization: extract-kernel
	@ echo "[Step] Optimizing MLIR with scalehls-opt..."
	\${OPTIMIZER} \${OPTIMIZER_COMMON_FLAGS} \${OPTIMIZER_DATAFLOW_FLAGS} \${OPTIMIZER_PIPELINE_FLAGS} \${OPTIMIZER_OTHER_FLAGS} kernel_${kernel}-amp-\${RATE}.tmp.mlir -o kernel_${kernel}-amp-\${RATE}.mlir
	\${OPTIMIZER} \${OPTIMIZER_COMMON_FLAGS} \${OPTIMIZER_DATAFLOW_FLAGS} \${OPTIMIZER_PIPELINE_FLAGS} \${OPTIMIZER_OTHER_FLAGS} kernel_${kernel}-ppcg.tmp.mlir -o kernel_${kernel}-ppcg.mlir

translate: optimization
	@ echo "[Step] Translating MLIR to C++ with scalehls-translate..."
	\${TRANSLATE} \${TRANSLATE_FLAGS} \${PPCG_SCHED_FLAGS} kernel_${kernel}-amp-\${RATE}.mlir -o kernel_${kernel}-amp-\${RATE}.cpp
	\${TRANSLATE} \${TRANSLATE_FLAGS} \${PPCG_SCHED_FLAGS} kernel_${kernel}-ppcg.mlir         -o kernel_${kernel}-ppcg.cpp

testfix: translate
	@ echo "[Step] Patching C++ files to include test_${kernel}.h by sed command..."
	@ sed -i '/using namespace std;/i \\
#include "test_${kernel}.h"\\
' kernel_${kernel}-amp-\${RATE}.cpp
	@ sed -i '/using namespace std;/i \\
#include "test_${kernel}.h"\\
' kernel_${kernel}-ppcg.cpp
	@ sed -i 's/\\bkernel_${kernel}\\b/kernel_${kernel}_amp_\${RATE}/g' kernel_${kernel}-amp-\${RATE}.cpp
	@ sed -i 's/\\bkernel_${kernel}\\b/kernel_${kernel}_ppcg/g' kernel_${kernel}-ppcg.cpp

cppGen: ${kernel}.c
	@ echo "[Step] Generating test_${kernel}.cpp with extern ${kernel}.c..."
	@ cp ${kernel}.c test_${kernel}.cpp
	@ sed -i 's/${kernel}.h/test_${kernel}.h/g' test_${kernel}.cpp

hGen:
	@ echo "[Step] Generating test_${kernel}.h from ${kernel}.h & extracting kernel function prototypes..."
	@ cp ${kernel}.h test_${kernel}.h
	@ sed -n '/^.*kernel_[a-zA-Z0-9_]* *(/,/)/p' kernel_${kernel}-ppcg.cpp | sed '/{.*/d' | sed '\$\$s/\$\$/);/' > ppcg_kernel_func.tmp
	@ sed -n '/^.*kernel_[a-zA-Z0-9_]* *(/,/)/p' kernel_${kernel}-amp-\${RATE}.cpp | sed '/{.*/d' | sed '\$\$s/\$\$/);/' > amp-\${RATE}_kernel_func.tmp
	@ sed -i "3a #include <ap_int.h>" test_${kernel}.h
	@ sed -i "4r amp-\${RATE}_kernel_func.tmp" test_${kernel}.h
	@ sed -i "4r ppcg_kernel_func.tmp" test_${kernel}.h
	@ rm -f ppcg_kernel_func.tmp amp-\${RATE}_kernel_func.tmp

run_origin:
	@ echo "[Step] Compiling and running original version to check baseline..."
	\${VERBOSE} \${CC} $kernel.c -DNO_PENCIL_KILL \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLYBENCH_FLAGS} -I. -I$utilityDir $utilityDir/polybench.c -o $kernel-origon.exe     \${EXTRA_FLAGS}
	./$kernel-origon.exe

all: testfix cppGen hGen run_origin
	@ rm -f ${kernel}-origon.exe
	@ rm -f ${kernel}-amp-\${RATE}.c
	@ rm -f ${kernel}-ppcg.c
	@ rm -f ${kernel}-amp-\${RATE}.mlir
	@ rm -f ${kernel}-ppcg.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.tmp.mlir
	@ rm -f kernel_${kernel}-ppcg.tmp.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.mlir
	@ rm -f kernel_${kernel}-ppcg.mlir
	@ echo ">>> [all] Done."

clean:
	@ echo "[Step] Cleaning up..."
	@ rm -f csynth.tcl
	@ rm -f ${kernel}-origon.exe
	@ rm -f ${kernel}-amp-\${RATE}.c
	@ rm -f ${kernel}-ppcg.c
	@ rm -f ${kernel}-amp-\${RATE}.mlir
	@ rm -f ${kernel}-ppcg.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.tmp.mlir
	@ rm -f kernel_${kernel}-ppcg.tmp.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.mlir
	@ rm -f kernel_${kernel}-ppcg.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.cpp
	@ rm -f kernel_${kernel}-ppcg.cpp
	@ rm -f test_${kernel}.cpp
	@ rm -f test_${kernel}.h
	@ rm -f ppcg_kernel_func.tmp
	@ rm -f amp-\${RATE}_kernel_func.tmp
	@ rm -f *.tmp
	@ rm -f *.exe
	@ rm -f *.out
	@ rm -f __tmp_*
	@ rm -f avg_*.out
	@ rm -f ____tempfile_time*.txt
	@ rm -f ____tempfile_*
	@ rm -f *.mlir
EOF

        close FILE;

		open SYNFILE, ">$csynthFile" or die "failed to open $csynthFile.";
print SYNFILE << "EOF";
open_project hlsTest-1
set_top kernel_${kernel}_ppcg
add_files ${script_path}/../${key}/${kernel}/kernel_${kernel}-ppcg.cpp
add_files -tb ${script_path}/../${key}/${kernel}/test_${kernel}.cpp -cflags "-I${script_path} -DPOLYBENCH_STACK_ARRAYS -DNO_PENCIL_KILL -Wno-unknown-pragmas -Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"
add_files -tb ${script_path}/../${key}/${kernel}/test_${kernel}.h -cflags "-Wno-unknown-pragmas -Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"
open_solution "solution1" -flow_target vivado
set_part {xc7a100t-csg324-3}
create_clock -period 10 -name default
#source "./hlsTest-1/solution1/directives.tcl"
csynth_design
EOF

		close SYNFILE;

   }


   closedir DIR;
}

if ($GEN_CONFIG) {
open FILE, '>'.$TARGET_DIR.'/config.mk';

print FILE << "EOF";
CC=gcc
CFLAGS=-O3 
CC_OPENMP_FLAGS=
POLYBENCH_FLAGS=-DPOLYBENCH_TIME -DPOLYBENCH_STACK_ARRAYS

PPCG=/data/dagongcheng/sheensong-test/lnlamp/lnlamp-install/bin/ppcg
PPCG_TARGET=--target c 
PPCG_TILE_FLAGS=
PPCG_OPENMP_FLAGS=

CGEIST=/data/dagongcheng/sheensong-test/hlsProject/mixPrecHLS/polygeist/build/bin/cgeist
CGEIST_FLAGS=-O0 -g -S -memref-fullrank
CGEIST_LIB=
CGEIST_INC=-I /usr/lib/gcc/x86_64-linux-gnu/12/include/

OPTIMIZER=/data/dagongcheng/sheensong-test/hlsProject/mixPrecHLS/build/bin/scalehls-opt
OPTIMIZER_COMMON_FLAGS=--scalehls-func-preprocess="top-func=kernel_\${KERNEL}"
OPTIMIZER_DATAFLOW_FLAGS=
OPTIMIZER_PIPELINE_FLAGS=--scalehls-func-pipelining="target-func=kernel_\${KERNEL}"
OPTIMIZER_OTHER_FLAGS=--canonicalize --cse

TRANSLATE=/data/dagongcheng/sheensong-test/hlsProject/mixPrecHLS/build/bin/scalehls-translate
TRANSLATE_FLAGS=-scalehls-emit-hlscpp
EOF

close FILE;

}

