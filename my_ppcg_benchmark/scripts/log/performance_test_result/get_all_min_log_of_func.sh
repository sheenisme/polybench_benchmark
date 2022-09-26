#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 需要测试的函数名的数组
array=(fdtd-2d jacobi-1d jacobi-2d seidel-2d heat-3d 3d7pt 3d27pt fdtd-1d heat-1d heat-2d)

# 确认只含有一个参数
if [ $# -ne 1 ]; 
then
    echo "Usage:   ./get_all_min_log_of_func.sh funcname";
    echo "Example: ./get_all_min_log_of_func.sh  3d27pt ";
    exit 1;
fi
# 如果输入的参数不在数组中,那么直接退出
if [[ ! "${array[@]}"  =~ "${1}" ]]; 
then
    echo "@ERROR:  $1 not exists， please check.【get_all_min_log_of_func.sh】"
    exit
fi

# 别名
func=$1

./get_file_min_time.sh ${func}_amp_performance 
./get_file_min_time.sh ${func}_ppcg_double_performance 
./get_file_min_time.sh ${func}_ppcg_float_performance 