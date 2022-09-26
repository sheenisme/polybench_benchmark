#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 需要测试的函数名的数组
array=(fdtd-2d jacobi-1d jacobi-2d seidel-2d heat-3d 3d7pt 3d27pt fdtd-1d heat-1d heat-2d)

# 确认只含有一个参数
if [ $# -ne 1 ]; 
then
    echo "Usage:   ./auto_run_all_test_of_func.sh  funcname";
    echo "Example: ./auto_run_all_test_of_func.sh   3d27pt";
    exit 1;
fi
# 如果输入的参数不在数组中,那么直接退出
if [[ ! "${array[@]}"  =~ "${1}" ]]; 
then
    echo "@ERROR:  $1 not exists， please check."
    exit
fi

# 设置用户堆栈空间为8G
ulimit -s 8388608
echo "栈空间大小是:"
ulimit -a | grep "stack size"

# 别名
func=$1

# PAPI测试,确保实现了混合精度
# ./test_papi_of_func.sh $func

# 先测正确性（精度测试）
./test_correctness_of_func.sh $func

# 再测性能
./test_performance_of_func.sh $func > log/performance_log/${func}_perf.log

# 最后测一下编译时长和原始程序的执行时间，论文用
# ./test_compiler_times_of_func.sh $func 