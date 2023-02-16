#!/usr/bin/perl

# Visits every directory, calls make, and then executes the benchmark
# (Designed for making sure every kernel compiles/runs after modifications)
#
# Written by Tomofumi Yuki, 01/15 2015
#

my $TARGET_DIR = ".";

if ($#ARGV != 0 && $#ARGV != 1) {
   printf("usage perl run-all.pl target-dir [option] [output-file]\n");
   printf("the option: 1.Reliable performance test(default);2.Performance distribution test;3.Performance and Error test;4.LNLAMP test.\n");
   exit(1);
}



if ($#ARGV >= 0) {
   $TARGET_DIR = $ARGV[0];
}

my $OPTION = 1;
if ($#ARGV >= 1) {
   $OPTION = $ARGV[1];
}

my $OUTFILE = "";
if ($#ARGV == 2) {
   $OUTFILE = $ARGV[2];
}


my @categories = ('linear-algebra/blas',
                  'linear-algebra/kernels',
                  'linear-algebra/solvers',
                  'datamining',
                  'stencils',
                  'medley');


foreach $cat (@categories) {
   my $target = $TARGET_DIR.'/'.$cat;
   opendir DIR, $target or die "directory $target not found.\n";
   while (my $dir = readdir DIR) {
        next if ($dir=~'^\..*');
        next if (!(-d $target.'/'.$dir));

        my $kernel = $dir;
        my $targetDir = $target.'/'.$dir;  
        my $command = "";
        if ($OPTION == 1) {
            $command = "cd ../scripts; ./Reliable_perf_test.sh $targetDir $kernel;";
        }elsif($OPTION == 2) {
            $command = "cd ../scripts; ./performance_testing.sh $targetDir $kernel; ./get_performance_test_results.sh $kernel";
        }elsif($OPTION == 3) {
            $command = "cd ../scripts; ./experimental_tests.sh  $targetDir $kernel; ./get_experimental_test_result.sh $kernel";
        }elsif($OPTION == 4) {
            $command = "cd $targetDir; lnlamp $kernel.c";
        }else {
            # $command = "cd $targetDir; make clean; make; ./$kernel";
            printf("the error option!!!\n");
            exit(1);
        }              
           $command .= " 2>> $OUTFILE" if ($OUTFILE ne '');
        print($command."\n");
        system($command);
   }

   closedir DIR;
}

