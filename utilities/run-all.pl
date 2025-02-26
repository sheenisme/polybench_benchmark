#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'abs_path';
use XML::LibXML; # install XML cmd is: 'sudo apt-get install libxml-libxml-perl'

# ------------------------------------------------------------------------------
#  1) Two arguments are required:
#     - <target-dir>: The root directory to traverse
#     - <option-string>: Must be one of the following:
#         'all'
#         'all RATE=<number>'
#         '<tool-name>'
#         '<tool-name> RATE=<number>'
#        where <tool-name> can be any alphanumeric string (e.g., prectuner, scalehls)
#
#  2) An optional third argument to enable parallel execution:
#     - 'p', 'par', 'paral', or 'parallel' will enable parallel execution.
#  3) This script will traverse the subcategories and subdirectories under
#     <target-dir> and execute "make <option-string>" in each of them.
#  4) If <option-string> is 'fpga', the script will extract XML information
#     after running make and collect it into xml_summary.txt.
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
        "         '<tool-name>'\n" .
        "         '<tool-name> RATE=<number>'\n" .
        "       where <tool-name> can be any alphanumeric string (e.g., prectuner, scalehls)\n" .
        "       [parallel] is optional: 'p', 'par', 'paral', or 'parallel' to enable parallel execution.\n";
}

# Parse arguments
my $TARGET_DIR = $ARGV[0];
my $OPTION     = $ARGV[1];
my $PARALLEL   = $ARGV[2] // '';  # Check if 'parallel' argument is passed

# Check parallel argument format
if ($PARALLEL && $PARALLEL !~ /^(p|par|paral|parallel)$/i) {
    die "Error: Invalid parallel option '$PARALLEL'.\n" .
        "       Must be one of: 'p', 'par', 'paral', or 'parallel'\n";
}

# 1. Verify that <target-dir> exists
die "Error: '$TARGET_DIR' is not a valid directory.\n" unless (-d $TARGET_DIR);

# 2. Check whether <option-string> matches the allowed patterns:
#    'all', 'all RATE=<number>', or '<tool-name>', '<tool-name> RATE=<number>'
unless ($OPTION =~ /^(all|\w+)(?:\s+RATE=\d+)?$/) {
    die "Error: <option-string> must be one of the following:\n" .
        "       'all'\n" .
        "       'all RATE=<number>'\n" .
        "       '<tool-name>'\n" .
        "       '<tool-name> RATE=<number>'\n" .
        "       where <tool-name> can be any alphanumeric string\n" .
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

# Define tools that need to skip certain cases
my @skip_tools = ('scalehls', 'all');

# Define cases to skip for specific tools
my %skip_dirs;
if (grep { $OPTION =~ /^$_(?:\s+RATE=\d+)?$/ } @skip_tools) {
    %skip_dirs = map { $_ => 1 } qw(correlation cholesky gramschmidt durbin);
}

# 6. Parse RATE value if present
# Default RATE is 'ppcg'
my $RATE = 'ppcg';
# Initialize rate_value here to ensure it's always defined
my $rate_value = -1;  # Default to -1 for ppcg
if ($OPTION =~ /RATE=(\d+)/) {
    # If RATE=<number> is found, concatenate to '_amp_<number>'
    $RATE = 'amp_' . $1;
    $rate_value = int($1);  # Store rate value
}

# 7. Set up summary file path (changed to use absolute path from TARGET_DIR)
my $summary_file = abs_path("$TARGET_DIR/xml_summary.txt");

# Check if file exists to determine whether to write header
my $file_exists = -e $summary_file;
my $write_mode = $file_exists ? '>>' : '>';

# Open the summary file
open(my $sfh, $write_mode, $summary_file) or die "Cannot open '$summary_file' for writing: $!";

# Write header only if creating new file
if (!$file_exists) {
    my $header = sprintf("%-15s\t%5s\t%15s\t%15s\t%15s\t%15s\t%15s\t%15s\t%10s\n",
        "Benchmark", "RATE", "Latency(Syn)", "Latency(Sim)", "BRAM_18K", "DSP", "FF", "LUT", "URAM");
    print $sfh $header;
    my $separator = "-" x 131 . "\n";
    print $sfh $separator;
}

# Option determines if XML extraction is needed
my $need_xml = ($OPTION =~ /^(?:all|\d+)$/i) ? 0 : 1;

# 8. Traverse each category's subdirectory and run "make <option-string>"
foreach my $cat (@categories) {
    my $cat_path = "$TARGET_DIR/$cat";
    opendir(my $dh, $cat_path) or do {
        warn "Skipping '$cat_path': not found or cannot open.\n";
        next;
    };
    my @current_child_pids;  # Store child process PIDs

    while (my $subdir = readdir($dh)) {
        # Skip hidden directories (e.g., . and ..)
        next if ($subdir =~ /^\./);

        # Only check skip list if using tools that need skipping
        if (%skip_dirs && exists $skip_dirs{$subdir}) {
            my ($tool) = $OPTION =~ /^(\w+)/;  # Extract tool name
            print "Skipping directory '$subdir' as it's in the skip list for $tool.\n";
            next;
        }

        my $full_subdir_path = "$cat_path/$subdir";
        # Only handle directories
        next unless (-d $full_subdir_path);

        # If parallel execution is enabled, fork a new process
        if ($PARALLEL =~ /^(p|par|paral|parallel)$/i) {
            my $pid = fork();

            if ($pid) {
                # Parent process: Save the child process PID
                push @child_pids, $pid;
            } elsif ($pid == 0) {
                # Child process: Execute the command
                my $command = "cd $full_subdir_path && ulimit -s unlimited; make $OPTION";
                print "Executing: $command\n";
                my $exit_status = system($command);
                if ($exit_status != 0) {
                    warn "Command failed in '$full_subdir_path' with exit status $exit_status\n";
                }

                # If XML extraction is needed
                if ($need_xml) {
                    my $xml_dir = "syn_report_$RATE";
                    my $sim_dir = "sim_report_$RATE";
                    my $xml_file = "$full_subdir_path/$xml_dir/csynth.xml";
                    my $sim_file = "$full_subdir_path/$sim_dir/verilog/lat.rpt";
                    
                    # Check if XML file exists
                    if (-e $xml_file) {
                        eval {
                            # Set default simulation latency
                            my $sim_total_time = -1;
                            
                            # Only try to read sim file if it exists
                            if (-e $sim_file) {
                                open(my $fh, '<', $sim_file) or die "Cannot open file '$sim_file': $!";
                                while (my $line = <$fh>) {
                                    if ($line =~ /\$TOTAL_EXECUTE_TIME\s*=\s*"(\d+)"/) {
                                        $sim_total_time = $1;
                                        last;
                                    }
                                }
                                close($fh);
                            }

                            my $dom = XML::LibXML->load_xml(location => $xml_file);

                            # Get resource utilization info
                            my $resources_node = $dom->findnodes('//profile/AreaEstimates/Resources')->[0];
                            my $avail_resources_node = $dom->findnodes('//profile/AreaEstimates/AvailableResources')->[0];

                            if (!$resources_node || !$avail_resources_node) {
                                die "Cannot find resource information in XML file";
                            }

                            # Extract metrics and handle special values
                            my $latency = $dom->findvalue('//profile/PerformanceEstimates/SummaryOfOverallLatency/Worst-caseLatency');
                            if ($latency eq '' || $latency =~ /undef/) {
                                $latency = -1;
                            }

                            # Get resource utilization and calculate percentage
                            my ($bram, $bram_total, $bram_util) = (0, 0, 0);
                            my ($dsp, $dsp_total, $dsp_util) = (0, 0, 0);
                            my ($ff, $ff_total, $ff_util) = (0, 0, 0);
                            my ($lut, $lut_total, $lut_util) = (0, 0, 0);
                            my ($uram, $uram_total, $uram_util) = (0, 0, 0);

                            # Extract resource values with error checking
                            $bram = $resources_node->findvalue('./BRAM_18K') || -1;
                            $bram_total = $avail_resources_node->findvalue('./BRAM_18K') || 1;
                            $bram_util = $bram > 0 ? int(($bram / $bram_total) * 100) : 0;

                            $dsp = $resources_node->findvalue('./DSP') || -1;
                            $dsp_total = $avail_resources_node->findvalue('./DSP') || 1;
                            $dsp_util = $dsp > 0 ? int(($dsp / $dsp_total) * 100) : 0;

                            $ff = $resources_node->findvalue('./FF') || -1;
                            $ff_total = $avail_resources_node->findvalue('./FF') || 1;
                            $ff_util = $ff > 0 ? int(($ff / $ff_total) * 100) : 0;

                            $lut = $resources_node->findvalue('./LUT') || -1;
                            $lut_total = $avail_resources_node->findvalue('./LUT') || 1;
                            $lut_util = $lut > 0 ? int(($lut / $lut_total) * 100) : 0;

                            $uram = $resources_node->findvalue('./URAM') || -1;
                            $uram_total = $avail_resources_node->findvalue('./URAM') || 1;
                            $uram_util = $uram > 0 ? int(($uram / $uram_total) * 100) : 0;

                            # Format output with controlled field widths and utilization percentages
                            my $line = sprintf("%-15s\t%5d\t%15d\t%15d\t%8d (%3d%%)\t%8d (%3d%%)\t%8d (%3d%%)\t%8d (%3d%%)\t%4d (%3d%%)\n",
                                $subdir, $rate_value, $latency, $sim_total_time,
                                $bram, $bram_util,
                                $dsp, $dsp_util,
                                $ff, $ff_util,
                                $lut, $lut_util,
                                $uram, $uram_util);

                            # Write to file (use absolute path)
                            open(my $sfh_child, '+>>', $summary_file) or die "Cannot open '$summary_file' for appending: $!";
                            flock($sfh_child, 2);
                            print $sfh_child $line;
                            close($sfh_child);

                            # # Execute make clean after successful XML parsing
                            # my $clean_command = "cd $full_subdir_path && make clean";
                            # system($clean_command);
                            # if ($? != 0) {
                            #     warn "Warning: make clean failed in '$full_subdir_path' with status $?\n";
                            # }
                        };
                        if ($@) {
                            warn "Failed to parse XML file '$xml_file': $@\n";
                        }
                    } else {
                        warn "XML file '$xml_file' does not exist.\n";
                    }
                }

                exit 0;  # Child process exits after completion
            } else {
                die "Fork failed: $!\n";  # If fork fails
            }
        } else {
            # Sequential execution: Execute the command directly
            my $command = "cd $full_subdir_path && ulimit -s unlimited; make $OPTION";
            print "Executing: $command\n";
            my $exit_status = system($command);
            if ($exit_status != 0) {
                warn "Command failed in '$full_subdir_path' with exit status $exit_status\n";
            }

            # If XML extraction is needed
            if ($need_xml) {
                my $xml_dir = "syn_report_$RATE";
                my $sim_dir = "sim_report_$RATE";
                my $xml_file = "$full_subdir_path/$xml_dir/csynth.xml";
                my $sim_file = "$full_subdir_path/$sim_dir/verilog/lat.rpt";
                
                # Check if XML file exists
                if (-e $xml_file) {
                    eval {
                        # Set default simulation latency
                        my $sim_total_time = -1;
                        
                        # Only try to read sim file if it exists
                        if (-e $sim_file) {
                            open(my $fh, '<', $sim_file) or die "Cannot open file '$sim_file': $!";
                            while (my $line = <$fh>) {
                                if ($line =~ /\$TOTAL_EXECUTE_TIME\s*=\s*"(\d+)"/) {
                                    $sim_total_time = $1;
                                    last;
                                }
                            }
                            close($fh);
                        }

                        my $dom = XML::LibXML->load_xml(location => $xml_file);

                        # Get resource utilization info
                        my $resources_node = $dom->findnodes('//profile/AreaEstimates/Resources')->[0];
                        my $avail_resources_node = $dom->findnodes('//profile/AreaEstimates/AvailableResources')->[0];

                        if (!$resources_node || !$avail_resources_node) {
                            die "Cannot find resource information in XML file";
                        }

                        # Extract metrics and handle special values
                        my $latency = $dom->findvalue('//profile/PerformanceEstimates/SummaryOfOverallLatency/Worst-caseLatency');
                        if ($latency eq '' || $latency =~ /undef/) {
                            $latency = -1;
                        }

                        # Get resource utilization and calculate percentage
                        my ($bram, $bram_total, $bram_util) = (0, 0, 0);
                        my ($dsp, $dsp_total, $dsp_util) = (0, 0, 0);
                        my ($ff, $ff_total, $ff_util) = (0, 0, 0);
                        my ($lut, $lut_total, $lut_util) = (0, 0, 0);
                        my ($uram, $uram_total, $uram_util) = (0, 0, 0);

                        # Extract resource values with error checking
                        $bram = $resources_node->findvalue('./BRAM_18K') || -1;
                        $bram_total = $avail_resources_node->findvalue('./BRAM_18K') || 1;
                        $bram_util = $bram > 0 ? int(($bram / $bram_total) * 100) : 0;

                        $dsp = $resources_node->findvalue('./DSP') || -1;
                        $dsp_total = $avail_resources_node->findvalue('./DSP') || 1;
                        $dsp_util = $dsp > 0 ? int(($dsp / $dsp_total) * 100) : 0;

                        $ff = $resources_node->findvalue('./FF') || -1;
                        $ff_total = $avail_resources_node->findvalue('./FF') || 1;
                        $ff_util = $ff > 0 ? int(($ff / $ff_total) * 100) : 0;

                        $lut = $resources_node->findvalue('./LUT') || -1;
                        $lut_total = $avail_resources_node->findvalue('./LUT') || 1;
                        $lut_util = $lut > 0 ? int(($lut / $lut_total) * 100) : 0;

                        $uram = $resources_node->findvalue('./URAM') || -1;
                        $uram_total = $avail_resources_node->findvalue('./URAM') || 1;
                        $uram_util = $uram > 0 ? int(($uram / $uram_total) * 100) : 0;

                        # Format output with controlled field widths and utilization percentages
                        my $line = sprintf("%-15s\t%5d\t%15d\t%15d\t%8d (%3d%%)\t%8d (%3d%%)\t%8d (%3d%%)\t%8d (%3d%%)\t%4d (%3d%%)\n",
                            $subdir, $rate_value, $latency, $sim_total_time,
                            $bram, $bram_util,
                            $dsp, $dsp_util,
                            $ff, $ff_util,
                            $lut, $lut_util,
                            $uram, $uram_util);

                        # Write to file (use absolute path)
                        open(my $sfh_child, '+>>', $summary_file) or die "Cannot open '$summary_file' for appending: $!";
                        flock($sfh_child, 2);
                        print $sfh_child $line;
                        close($sfh_child);

                        # # Execute make clean after successful XML parsing
                        # my $clean_command = "cd $full_subdir_path && make clean";
                        # system($clean_command);
                        # if ($? != 0) {
                        #     warn "Warning: make clean failed in '$full_subdir_path' with status $?\n";
                        # }
                    };
                    if ($@) {
                        warn "Failed to parse XML file '$xml_file': $@\n";
                    }
                } else {
                    warn "XML file '$xml_file' does not exist.\n";
                }
            }
        }
    }
    closedir($dh);

    # Wait for all child processes to finish if parallel execution is enabled
    foreach my $pid (@child_pids) {
        waitpid($pid, 0);  # Wait for child process to finish
    }
}

close($sfh);  # Close the summary file
exit 0;
