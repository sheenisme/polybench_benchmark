#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir

if [ $# -ne 1 ]; then
    echo "Usage:   ./get_performance_test_results.sh <kernel>";
    echo "Example: ./get_performance_test_results.sh  3d7pt  ";
    echo "Note:    the kernel_benchmark_result.log file must be in the directory of the \"./results/\".";
    exit 1;
fi;
kernel=$1
file=./results/${kernel}_benchmark_result.log
# echo $file
final_result_file=benchmark_result_perf—dist.log
# echo $final_result_file


# 初始化一些参数
line_index=0
div=5


# 遍历file的每一行
while read line
do
    line_index=`expr $line_index + 1`
    # echo "行索引是:"$line_index
    remainder=`expr $line_index % $div`
    if [ $remainder -eq 0 ]
    then
        # echo "行索引是:"$line_index
        time=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
        echo $time          >> $final_result_file
    elif [ $remainder -eq 1 ]
    then
        echo -e $line "\c"  >> $final_result_file
    fi    
done < $file
