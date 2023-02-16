#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir

if [ $# -ne 1 ]; then
    echo "Usage:   ./get_experimental_test_result.sh <kernel>";
    echo "Example: ./get_experimental_test_result.sh  3d7pt  ";
    echo "Note:    the kernel_benchmark_result.log file must be in the directory of the \"./results/\".";
    exit 1;
fi;
kernel=$1
file=./results/${kernel}_benchmark_result.log
# echo $file
final_result_file=benchmark_result.log
# echo $final_result_file

cat $file >> $final_result_file;
