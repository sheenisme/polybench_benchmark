#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'abs_path';

# ------------------------------------------------------------------------------
#  1) Two arguments are required:
#     - <target-dir>: The root directory to traverse
#     - <option-string>: Must be one of the following:
#         'all'
#         'all RATE=<number>'
#         'fpga'
#         'fpga RATE=<number>'
#
#  2) An optional third argument to enable parallel execution:
#     - 'p', 'par', 'paral', or 'parallel' will enable parallel execution.
#  3) This script will traverse the subcategories and subdirectories under
#     <target-dir> and execute "make <option-string>" in each of them.
# ------------------------------------------------------------------------------

# Declare the @child_pids array to store the PIDs of child processes
my @child_pids;

# Handle SIGINT (Ctrl+C) to terminate all child processes
$SIG{INT} = sub {
    print "Caught SIGINT. Terminating child processes...\n";
    
    # Kill all child processes (use 'KILL' to ensure immediate termination)
    foreach my $pid (@child_pids) {
        kill 'KILL', $pid;  # Send KILL signal to child processes
    }
    
    # Wait for all child processes to terminate
    foreach my $pid (@child_pids) {
        waitpid($pid, 0);  # Ensure that all child processes are cleaned up
    }

    exit 1;  # Exit the script after cleanup
};

# Check the number of arguments
if (@ARGV < 2) {
    die "Usage: perl $0 <target-dir> <option-string> [parallel]\n" .
        "       where <option-string> is one of the following:\n" .
        "         'all'\n" .
        "         'all RATE=<number>'\n" .
        "         'fpga'\n" .
        "         'fpga RATE=<number>'\n" .
        "       [parallel] is optional: 'p', 'par', 'paral', or 'parallel' to enable parallel execution.\n";
}

# Parse arguments
my $TARGET_DIR = $ARGV[0];
my $OPTION     = $ARGV[1];
my $PARALLEL   = $ARGV[2] // '';  # Check if 'parallel' argument is passed

# 1. Verify that <target-dir> exists
die "Error: '$TARGET_DIR' is not a valid directory.\n" unless (-d $TARGET_DIR);

# 2. Check whether <option-string> matches the allowed patterns:
#    'all', 'all RATE=<number>', 'fpga', 'fpga RATE=<number>'
unless ($OPTION =~ /^(all(?:\s+RATE=\d+)?|fpga(?:\s+RATE=\d+)?)$/) {
    die "Error: <option-string> must be one of the following:\n" .
        "       'all'\n" .
        "       'all RATE=<number>'\n" .
        "       'fpga'\n" .
        "       'fpga RATE=<number>'\n" .
        "       Given: '$OPTION'\n";
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

# Define some cases to skip
my %skip_dirs = map { $_ => 1 } qw(ludcmp);

# 6. Traverse each category's subdirectory and run "make <option-string>"
foreach my $cat (@categories) {
    my $cat_path = "$TARGET_DIR/$cat";
    opendir(my $dh, $cat_path) or do {
        warn "Skipping '$cat_path': not found or cannot open.\n";
        next;
    };
    my @child_pids;  # Store child process PIDs

    while (my $subdir = readdir($dh)) {
        # Skip hidden directories (e.g., . and ..)
        next if ($subdir =~ /^\./);

        # Skip directories in the skip list
        if (exists $skip_dirs{$subdir}) {
            print "Skipping directory '$subdir' as it's in the skip list.\n";
            next;
        }

        my $full_subdir_path = "$cat_path/$subdir";
        # Only handle directories
        next unless (-d $full_subdir_path);

        # If parallel execution is enabled (using relaxed condition), fork a new process
        if ($PARALLEL =~ /^(p|par|paral|parallel)$/i) {
            my $pid = fork();

            if ($pid) {
                # Parent process: Save the child process PID
                push @child_pids, $pid;
            } elsif ($pid == 0) {
                # Child process: Execute the command
                my $command = "cd $full_subdir_path && make $OPTION";
                print "Executing: $command\n";
                my $exit_status = system($command);
                if ($exit_status != 0) {
                    warn "Command failed in '$full_subdir_path' with exit status $exit_status\n";
                }
                exit 0;  # Child process exits after completion
            } else {
                die "Fork failed: $!\n";  # If fork fails
            }
        } else {
            # Sequential execution: Execute the command directly
            my $command = "cd $full_subdir_path && make $OPTION";
            print "Executing: $command\n";
            my $exit_status = system($command);
            if ($exit_status != 0) {
                warn "Command failed in '$full_subdir_path' with exit status $exit_status\n";
            }
        }
    }

    closedir $dh;

    # Parent process waits for all child processes to finish (if parallel execution)
    if ($PARALLEL =~ /^(p|par|paral|parallel)$/i) {
        foreach my $pid (@child_pids) {
            waitpid($pid, 0);
        }
    }
}

exit 0;
