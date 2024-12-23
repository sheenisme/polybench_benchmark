#!/usr/bin/perl

# Visits every directory, calls make, and then executes the benchmark
# (Designed for making sure every kernel compiles/runs after modifications)
#
# Written by Tomofumi Yuki, 01/15 2015
#

my $TARGET_DIR = ".";

if ($#ARGV != 0 && $#ARGV != 1) {
   printf("usage perl run-all.pl target-dir [option] [output-file]\n");
   printf("the option: 1.run all cases; 2.run origin and clean.\n");
   exit(1);
}


# parse arguments
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

# set CPATH
use Cwd 'abs_path';
my $script_path = abs_path($0);
$script_path =~ s/\/[^\/]+$//;
if (defined $ENV{CPATH}) {
    $ENV{CPATH} .= ":$script_path";
} else {
    $ENV{CPATH} = $script_path;
}

# set stack size
my $runSets = "ulimit -s unlimited";
print($runSets."\n");
system($runSets);

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
            $command = "cd $targetDir; make clean; make all;";
        }else{
            $command = "cd $targetDir; make run_origin; make clean;";
        }
        $command .= " 2>> $OUTFILE" if ($OUTFILE ne '');
        print($command."\n");
        system($command);
   }

   closedir DIR;
}

