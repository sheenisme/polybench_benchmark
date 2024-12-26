#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'abs_path';

# ------------------------------------------------------------------------------
#  1) Two arguments are required:
#     - <target-dir>: The root directory to traverse
#     - <option-string>: Must be "ppcg" "all" or "amp RATE=<number>"
#
#  2) No third argument is accepted; the output-file option has been removed.
#
#  3) This script will traverse the subcategories and subdirectories under
#     <target-dir> and execute "make <option-string>" in each of them.
# ------------------------------------------------------------------------------

# Check the number of arguments
if (@ARGV < 2) {
    die "Usage: perl $0 <target-dir> <option-string>\n" .
        "       where <option-string> is either:\n" .
        "         'ppcg' or 'amp RATE=<number>'\n";
}

# Parse arguments
my $TARGET_DIR = $ARGV[0];
my $OPTION     = $ARGV[1];

# 1. Verify that <target-dir> exists
die "Error: '$TARGET_DIR' is not a valid directory.\n" unless (-d $TARGET_DIR);

# 2. Check whether <option-string> matches the pattern "ppcg" or "amp RATE=<number>"
#    Regex explanation:
#       ^ppcg$              => matches "ppcg"
#       ^amp\s+RATE=\d+$    => matches "amp RATE=<number>"
unless ($OPTION =~ /^(ppcg|all|amp\s+RATE=\d+)$/) {
    die "Error: <option-string> must be 'ppcg' 'all' or 'amp RATE=<number>'. Given: '$OPTION'\n";
}

# 3. Define the categories (subdirectories) to traverse
my @categories = (
    'linear-algebra/blas',
    'linear-algebra/kernels',
    'linear-algebra/solvers',
    'datamining',
    'stencils',
    'medley'
);

# 4. Set CPATH to include the script's directory
my $script_path = abs_path($0);
$script_path =~ s/\/[^\/]+$//;  # Remove the script name, keep the directory
if (defined $ENV{CPATH}) {
    $ENV{CPATH} .= ":$script_path";
} else {
    $ENV{CPATH} = $script_path;
}

# 5. Set the stack size to unlimited
my $runSets = "ulimit -s unlimited;";
print "$runSets\n";
system($runSets);

# 6. Traverse each category's subdirectory and run "make <option-string>"
foreach my $cat (@categories) {
    my $cat_path = "$TARGET_DIR/$cat";
    opendir(my $dh, $cat_path) or do {
        warn "Skipping '$cat_path': not found or cannot open.\n";
        next;
    };
    while (my $subdir = readdir($dh)) {
        # Skip hidden directories (e.g., . and ..)
        next if ($subdir =~ /^\./);
        
        my $full_subdir_path = "$cat_path/$subdir";
        # Only handle directories
        next unless (-d $full_subdir_path);

        my $command = "cd $full_subdir_path; make $OPTION";

        print("$command\n");
        system($command);
    }
    closedir $dh;
}

exit 0;

