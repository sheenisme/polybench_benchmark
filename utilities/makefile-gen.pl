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
        my $utilityDir = $polybenchRoot.'utilities';

        open FILE, ">$file" or die "failed to open $file.";

print FILE << "EOF";
include $configFile

EXTRA_FLAGS=$extra_flags{$kernel}

RATE ?= 50

double: pre-ppcg $kernel-ppcg.c $kernel.h
	\${VERBOSE} \${CC} -o $kernel-ppcg-double.exe $kernel-ppcg.c \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLY_ARGS} -DDATA_TYPE_IS_DOUBLE=1 -I. -I$utilityDir $utilityDir/polybench.c \${EXTRA_FLAGS}

float: pre-ppcg $kernel-ppcg.c $kernel.h
	\${VERBOSE} \${CC} -o $kernel-ppcg-float.exe  $kernel-ppcg.c \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLY_ARGS} -DDATA_TYPE_IS_FLOAT=1  -I. -I$utilityDir $utilityDir/polybench.c \${EXTRA_FLAGS}

amp: pre-amp $kernel-amp_\${RATE}.c $kernel.h
	\${VERBOSE} \${CC} -o $kernel-amp_\${RATE}.exe $kernel-amp_\${RATE}.c \${CFLAGS} \${CC_OPENMP_FLAGS} \${POLY_ARGS} -I. -I$utilityDir $utilityDir/polybench.c \${EXTRA_FLAGS}

pre-amp: $kernel.c
	ppcg --target c \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} -R \${RATE} $kernel.c -o $kernel-amp_\${RATE}.c > /dev/null 2>&1

pre-ppcg:
	ppcg --target c \${PPCG_TILE_FLAGS} \${PPCG_OPENMP_FLAGS} --no-automatic-mixed-precision $kernel.c -o $kernel-ppcg.c > /dev/null 2>&1

clean:
	@ rm -f $kernel-*.exe
	@ rm -f $kernel-*.c
	@ rm -f ____tempfile_*.data.polybench
	@ rm -f avg_*.out
	@ rm -f ${kernel}_lnlamp.c
	@ rm -f lnlamp_predict_result.png
	@ rm -f lnlamp_temp_result.txt

EOF

        close FILE;
   }


   closedir DIR;
}

if ($GEN_CONFIG) {
open FILE, '>'.$TARGET_DIR.'/config.mk';

print FILE << "EOF";
CC=gcc
CFLAGS=-g -O3 
CC_OPENMP_FLAGS=
POLY_ARGS=-DPOLYBENCH_TIME -DPOLYBENCH_STACK_ARRAYS -DPOLYBENCH_USE_C99_PROTO
PPCG_TILE_FLAGS=
PPCG_OPENMP_FLAGS=
EOF

close FILE;

}

