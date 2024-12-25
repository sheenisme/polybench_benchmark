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
		my $kernel_safe = $kernel;
		$kernel_safe =~ s/-/_/g;
        open FILE, ">$file" or die "failed to open $file.";

print FILE << "EOF";
KERNEL=$kernel

include $configFile

EXTRA_FLAGS=$extra_flags{$kernel}

RATE ?= 

# please set $utilityDir or $script_path in CPATH.
ifeq (\$(findstring $utilityDir,\$(CPATH)),)
CPATH := \$(CPATH):$utilityDir
export CPATH
endif

KERNEL_MODIFIED = \$(subst -,_,\$(KERNEL))
KERNEL_FUNC_SAFE_STR = \$(if \$(strip \$(RATE)),\$(KERNEL_MODIFIED)_amp_\$(RATE),\$(KERNEL_MODIFIED)_ppcg)
KERNEL_TMP_FILE_STR = \$(if \$(strip \$(RATE)),\$(KERNEL)_amp_\$(RATE),\$(KERNEL)_ppcg)

init:
ifeq (\$(strip \$(RATE)),)
	@ echo "[Step] Starting with ppcg"
else
	@ echo "[Step] Starting with RATE=\$(RATE)"
endif

get_cvariant: init ${kernel}.c
ifeq (\$(strip \$(RATE)),)
	@ echo "[Step] Generating PPCG version: \${KERNEL_TMP_FILE_STR}.c"
	\${PPCG} \${PPCG_TARGET} \${PPCG_SCHED_FLAGS} \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} --no-automatic-mixed-precision ${kernel}.c -o \${KERNEL_TMP_FILE_STR}.c > /dev/null 2>&1
else
	@ echo "[Step] Generating AMP version: \${KERNEL_TMP_FILE_STR}.c"
	\${PPCG} \${PPCG_TARGET} \${PPCG_SCHED_FLAGS} \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} -R \${RATE} ${kernel}.c -o \${KERNEL_TMP_FILE_STR}.c > /dev/null 2>&1
endif
	
clang2mlir: get_cvariant
	@ echo "[Step] Translating C to MLIR with cgeist..."
	\${CGEIST}  \${CGEIST_FLAGS} \${CGEIST_LIB} \${CGEIST_INC} -I$utilityDir \${KERNEL_TMP_FILE_STR}.c -o \${KERNEL_TMP_FILE_STR}.mlir

extract_kernel: clang2mlir
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
	' \${KERNEL_TMP_FILE_STR}.mlir > kernel_\${KERNEL_TMP_FILE_STR}.tmp.mlir

optimization: extract_kernel
	@ echo "[Step] Optimizing MLIR with scalehls-opt..."
	\${OPTIMIZER} \${OPTIMIZER_COMMON_FLAGS} \${OPTIMIZER_DATAFLOW_FLAGS} \${OPTIMIZER_PIPELINE_FLAGS} \${OPTIMIZER_OTHER_FLAGS} kernel_\${KERNEL_TMP_FILE_STR}.tmp.mlir -o kernel_\${KERNEL_TMP_FILE_STR}.mlir

translate: optimization
	@ echo "[Step] Translating MLIR to C++ with scalehls-translate..."
	\${TRANSLATE} \${TRANSLATE_FLAGS} \${PPCG_SCHED_FLAGS} kernel_\${KERNEL_TMP_FILE_STR}.mlir -o kernel_\${KERNEL_TMP_FILE_STR}.cpp

func_patch: translate
	@ echo "[Step] Patching C++ files to include test_${kernel}.h by sed command..."
	@ sed -i '/using namespace std;/i \\
#include "test_${kernel}.h"\\
' kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ sed -i 's/kernel_${kernel_safe}/kernel_\${KERNEL_FUNC_SAFE_STR}/g' kernel_\${KERNEL_TMP_FILE_STR}.cpp

cppGen: ${kernel}.c
	@ echo "[Step] Generating test_${kernel}.cpp with extern ${kernel}.c..."
	@ cp \${KERNEL_TMP_FILE_STR}.c test_${kernel}.cpp
	@ sed -i 's/${kernel}.h/test_${kernel}.h/g' test_${kernel}.cpp

hGen:
	@ echo "[Step] Generating test_${kernel}.h from ${kernel}.h & extracting kernel function prototypes..."
	@ cp ${kernel}.h test_${kernel}.h
	@ sed -n '/^.*kernel_[a-zA-Z0-9_-]* *(/,/)/p' kernel_\${KERNEL_TMP_FILE_STR}.cpp | sed '/{.*/d' | sed '\$\$s/\$\$/);/' > kernel_func.tmp
	@ sed -i "3a #include <ap_int.h>" test_${kernel}.h
	@ sed -i "4r kernel_func.tmp" test_${kernel}.h
	@ rm -f kernel_func.tmp

fpga: init func_patch cppGen hGen
ifeq (\$(strip \$(RATE)),)
	@ echo "[Step] Running end-to-end for PPCG..."
	\${VITIS_HLS} -f csynth.tcl | tee vitis_hls.log
else
	@ echo "[Step] Running end-to-end for \${RATE}..."
	@ sed -i 's/_ppcg/_amp_\${RATE}/g' csynth.tcl
	\${VITIS_HLS} -f csynth.tcl | tee vitis_hls.log
	@ sed -i 's/_amp_\${RATE}/_ppcg/g' csynth.tcl
endif
	@ rm -f \${KERNEL_TMP_FILE_STR}.c
	@ rm -f \${KERNEL_TMP_FILE_STR}.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.tmp.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ rm -f test_${kernel}.cpp
	@ rm -f test_${kernel}.h
	@ echo ">>> [all] Done."

baseline: func_patch
	@ echo "[Step] Compiling and running baseline version to check correctness..."
	\${VERBOSE} \${CC} \${KERNEL_TMP_FILE_STR}.c \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLYBENCH_FLAGS} -I. -I$utilityDir $utilityDir/polybench.c -o \${KERNEL_TMP_FILE_STR}.exe     \${EXTRA_FLAGS}
	./\${KERNEL_TMP_FILE_STR}.exe > \${KERNEL_TMP_FILE_STR}.out 2>&1

replace_kernel_call: func_patch cppGen hGen
	@ echo "[Step] Replacing Kernel function call by shell command..."
	@ cp kernel_\${KERNEL_TMP_FILE_STR}.cpp verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ cp test_${kernel}.h verify_test_${kernel}.h
	@ awk -v new_str="kernel_\${KERNEL_FUNC_SAFE_STR}" '/Run kernel/ {print; getline; gsub(/kernel_${kernel_safe}/, new_str); print; next} {print}' test_${kernel}.cpp > verify_test_${kernel}.cpp
	@ sed -i '4,4d'  verify_test_${kernel}.h
	@ sed -i '1,14d' verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ sed -i 's/ap_int<32>/int/g' verify_test_${kernel}.h
	@ sed -i 's/ap_int<32>/int/g' verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ sed -i 's/ap_int<8>/char/g' verify_test_${kernel}.h
	@ sed -i 's/ap_int<8>/char/g' verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ sed -i 's/test_${kernel}.h/verify_test_${kernel}.h/g' verify_test_${kernel}.cpp
	@ sed -i 's/test_${kernel}.h/verify_test_${kernel}.h/g' verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp
	
verify: baseline replace_kernel_call
	@ echo "[Step] Compiling and running generated version to check correctness..."
	\${VERBOSE} \${CPP} verify_test_${kernel}.cpp verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLYBENCH_FLAGS} -I. -I$utilityDir $utilityDir/polybench.cpp -o kernel_\${KERNEL_TMP_FILE_STR}.exe     \${EXTRA_FLAGS}
	./kernel_\${KERNEL_TMP_FILE_STR}.exe > kernel_\${KERNEL_TMP_FILE_STR}.out 2>&1

show_diff: verify
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ rm -f test_${kernel}.cpp
	@ rm -f test_${kernel}.h
	@ rm -f \${KERNEL_TMP_FILE_STR}.c
	@ rm -f \${KERNEL_TMP_FILE_STR}.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.tmp.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.mlir
	@ rm -f verify_test_${kernel}.cpp
	@ rm -f verify_test_${kernel}.h
	@ rm -f verify_kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.exe
	@ rm -f \${KERNEL_TMP_FILE_STR}.exe
	@ echo "[Step] Showing diff result..."
	diff kernel_\${KERNEL_TMP_FILE_STR}.out \${KERNEL_TMP_FILE_STR}.out || true

run_origin:
	@ echo "[Step] Compiling and running original version to check baseline..."
	\${VERBOSE} \${CC} $kernel.c -DNO_PENCIL_KILL \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLYBENCH_FLAGS} -I. -I$utilityDir $utilityDir/polybench.c -o ${kernel}_origon.exe     \${EXTRA_FLAGS}
	./${kernel}_origon.exe > ${kernel}_origon.out 2>&1

all: run_origin show_diff
ifeq (\$(strip \$(RATE)),)
	diff ${kernel}_origon.out \${KERNEL_TMP_FILE_STR}.out || true
endif
	@ rm -f ${kernel}_origon.out
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.out
	@ rm -f \${KERNEL_TMP_FILE_STR}.out
	@ rm -f ${kernel}_origon.exe
	@ rm -f \${KERNEL_TMP_FILE_STR}.exe
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.exe
	@ rm -f \${KERNEL_TMP_FILE_STR}.c
	@ rm -f \${KERNEL_TMP_FILE_STR}.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.tmp.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.mlir
	@ rm -f kernel_\${KERNEL_TMP_FILE_STR}.cpp
	@ rm -f test_${kernel}.cpp
	@ rm -f test_${kernel}.h
	@ echo ">>> [all] Done."

clean:
	@ echo "[Step] Cleaning up..."
	@ rm -f vitis_hls.log
	@ rm -rf hlsTest
	@ rm -rf report_ppcg
	@ rm -rf report_amp_*
	@ rm -f ${kernel}_origon.exe
	@ rm -f ${kernel}_amp_*.c
	@ rm -f ${kernel}_ppcg.c
	@ rm -f ${kernel}_amp_*.mlir
	@ rm -f ${kernel}_ppcg.mlir
	@ rm -f kernel_${kernel}_amp_*.tmp.mlir
	@ rm -f kernel_${kernel}_ppcg.tmp.mlir
	@ rm -f kernel_${kernel}_amp_*.mlir
	@ rm -f kernel_${kernel}_ppcg.mlir
	@ rm -f kernel_${kernel}_amp_*.cpp
	@ rm -f kernel_${kernel}_ppcg.cpp
	@ rm -f test_${kernel}.cpp
	@ rm -f test_${kernel}.h
	@ rm -f kernel_func.tmp
	@ rm -f verify_test_${kernel}.cpp
	@ rm -f verify_test_${kernel}.h
	@ rm -f verify_kernel_*.cpp
	@ rm -f *.log
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
open_project hlsTest

set_top kernel_${kernel_safe}_ppcg
# current path is: ${script_path}/../${key}/${kernel}/
add_files kernel_${kernel}_ppcg.cpp
add_files -tb test_${kernel}.cpp -cflags "-I${script_path} -DPOLYBENCH_STACK_ARRAYS -DNO_PENCIL_KILL -Wno-unknown-pragmas -Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"
add_files -tb test_${kernel}.h -cflags "-Wno-unknown-pragmas -Wno-unknown-pragmas" -csimflags "-Wno-unknown-pragmas"

open_solution "solution1" -flow_target vivado
set_part {xc7a100t-csg324-3}
create_clock -period 10 -name default
#source "./hlsTest/solution1/directives.tcl"

csynth_design

file copy -force ./hlsTest/solution1/syn/report ./report_ppcg

# Remove hlsTest directories
if { [file exists ./hlsTest] } {
    file delete -force ./hlsTest
} else {
    puts "Folder does not exist: ./hlsTest"
}

exit
EOF

		close SYNFILE;

   }


   closedir DIR;
}

if ($GEN_CONFIG) {
open FILE, '>'.$TARGET_DIR.'/config.mk';

print FILE << "EOF";
CC=gcc
CPP=g++
CFLAGS=-O3 
CC_OPENMP_FLAGS=
POLYBENCH_FLAGS=-DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS

PPCG=/home/guanghui/Workspace/lnlamp/install/bin/ppcg
PPCG_TARGET=--target c 
PPCG_TILE_FLAGS=
PPCG_OPENMP_FLAGS=

CGEIST=/home/guanghui/Workspace/MixPrecHLS/polygeist/build/bin/cgeist
CGEIST_FLAGS=-O0 -g -S -memref-fullrank
CGEIST_LIB=
CGEIST_INC=-I /usr/lib/gcc/x86_64-linux-gnu/12/include/

OPTIMIZER=/home/guanghui/Workspace/MixPrecHLS/build/bin/scalehls-opt
OPTIMIZER_COMMON_FLAGS=--scalehls-func-preprocess="top-func=kernel_\${KERNEL}"
OPTIMIZER_DATAFLOW_FLAGS=
OPTIMIZER_PIPELINE_FLAGS=
OPTIMIZER_OTHER_FLAGS=--canonicalize --cse

TRANSLATE=/home/guanghui/Workspace/MixPrecHLS/build/bin/scalehls-translate
TRANSLATE_FLAGS=-scalehls-emit-hlscpp

VITIS_HLS=/shared/Xilinx/Vitis_HLS/2022.2/bin/vitis_hls
EOF

close FILE;

}

