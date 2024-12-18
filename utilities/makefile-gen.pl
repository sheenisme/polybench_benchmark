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

foreach $key (keys %categories) {
   my $target = $TARGET_DIR.'/'.$key;
   opendir DIR, $target or die "directory $target not found.\n";
   while (my $dir = readdir DIR) {
        next if ($dir=~'^\..*');
        next if (!(-d $target.'/'.$dir));

	my $kernel = $dir;
        my $file = $target.'/'.$dir.'/Makefile';
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

get-amp: ${kernel}.c
	\${PPCG} \${PPCG_TARGET} \${PPCG_SCHED_FLAGS} \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} -R \${RATE} ${kernel}.c -o ${kernel}-amp-\${RATE}.c > /dev/null 2>&1

get-ppcg:
	\${PPCG} \${PPCG_TARGET} \${PPCG_SCHED_FLAGS} \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} --no-automatic-mixed-precision ${kernel}.c -o ${kernel}-ppcg.c > /dev/null 2>&1

clang2mlir: get-ppcg get-amp
	\${CGEIST}  \${CGEIST_FLAGS} \${CGEIST_LIB} \${CGEIST_INC} -I$utilityDir ${kernel}-amp-\${RATE}.c > ${kernel}-amp-\${RATE}.mlir
	\${CGEIST}  \${CGEIST_FLAGS} \${CGEIST_LIB} \${CGEIST_INC} -I$utilityDir ${kernel}-ppcg.c > ${kernel}-ppcg.mlir

extract-kernel: clang2mlir
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
	\${OPTIMIZER} \${OPTIMIZER_COMMON_FLAGS} \${OPTIMIZER_DATAFLOW_FLAGS} \${OPTIMIZER_PIPELINE_FLAGS} \${OPTIMIZER_OTHER_FLAGS} kernel_${kernel}-amp-\${RATE}.tmp.mlir > kernel_${kernel}-amp-\${RATE}.mlir
	\${OPTIMIZER} \${OPTIMIZER_COMMON_FLAGS} \${OPTIMIZER_DATAFLOW_FLAGS} \${OPTIMIZER_PIPELINE_FLAGS} \${OPTIMIZER_OTHER_FLAGS} kernel_${kernel}-ppcg.tmp.mlir > kernel_${kernel}-ppcg.mlir

translate: optimization
	\${TRANSLATE} \${TRANSLATE_FLAGS} \${PPCG_SCHED_FLAGS} kernel_${kernel}-amp-\${RATE}.mlir > kernel_${kernel}-amp-\${RATE}.c
	\${TRANSLATE} \${TRANSLATE_FLAGS} \${PPCG_SCHED_FLAGS} kernel_${kernel}-ppcg.mlir > kernel_${kernel}-ppcg.c

testfix: translate
	@ sed -i '1i#include "${kernel}.h"' kernel_${kernel}-amp-\${RATE}.c
	@ sed -i '1i#include "${kernel}.h"' kernel_${kernel}-ppcg.c
	@ sed -i 's/\\bkernel_${kernel}\\b/kernel_${kernel}_amp_\${RATE}/g' kernel_${kernel}-amp-\${RATE}.c
	@ sed -i 's/\\bkernel_${kernel}\\b/kernel_${kernel}_ppcg/g' kernel_${kernel}-ppcg.c

all: testfix
	@ rm -f ${kernel}-amp-\${RATE}.c
	@ rm -f ${kernel}-ppcg.c
	@ rm -f ${kernel}-amp-\${RATE}.mlir
	@ rm -f ${kernel}-ppcg.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.tmp.mlir
	@ rm -f kernel_${kernel}-ppcg.tmp.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.mlir
	@ rm -f kernel_${kernel}-ppcg.mlir
	@ echo 

clean:
	@ rm -f ${kernel}-amp-\${RATE}.c
	@ rm -f ${kernel}-ppcg.c
	@ rm -f ${kernel}-amp-\${RATE}.mlir
	@ rm -f ${kernel}-ppcg.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.tmp.mlir
	@ rm -f kernel_${kernel}-ppcg.tmp.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.mlir
	@ rm -f kernel_${kernel}-ppcg.mlir
	@ rm -f kernel_${kernel}-amp-\${RATE}.c
	@ rm -f kernel_${kernel}-ppcg.c
	@ rm -f *.exe
	@ rm -f *.out
	@ rm -f __tmp_*
	@ rm -f avg_*.out
	@ rm -f ____tempfile_time*.txt
	@ rm -f ____tempfile_*
	@ rm -f *.mlir
EOF

        close FILE;
   }


   closedir DIR;
}

if ($GEN_CONFIG) {
open FILE, '>'.$TARGET_DIR.'/config.mk';

print FILE << "EOF";
CC=/home/sheen/llvm-project/llvm-install/bin/clang
CFLAGS=-O3 
CC_OPENMP_FLAGS=
POLYBENCH_FLAGS=-DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS

PPCG=/data/dagongcheng/sheensong-test/lnlamp/lnlamp-install/bin/ppcg
PPCG_TARGET=--target c 
PPCG_TILE_FLAGS=
PPCG_OPENMP_FLAGS=

CGEIST=/data/dagongcheng/sheensong-test/hlsProject/mixPrecHLS/polygeist/build/bin/cgeist
CGEIST_FLAGS=-O0 -g -S -memref-fullrank -raise-scf-to-affine
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

