#!/bin/sh
## 性能测试脚本,在run-all.pl中调用该脚本对测试用例进行逐个测试.
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir


if [ $# -ne 2 ]; then
    echo "Usage: ./performance_testing.sh <target_dir> <kernel>";
    echo "Example: ./performance_testing.sh \"..//stencils/3d27pt\" 3d27pt";
    echo "Note: the file must be a Polybench program compiled with -DPOLYBENCH_TIME";
    exit 1;
fi;
target_dir=$1
kernel=$2


# 设置一些变量,方便后面调用.
run_time_benchmark="bash $workdir/time_benchmark.sh"
# echo $run_time_benchmark
result_file="$workdir/benchmark_result.log"
# echo $result_file
my_rate_list="$workdir/my_rate_list"


# 设置用户堆栈空间为8G
ulimit -s 8388608
# echo "用户区栈空间大小是:"
# ulimit -a | grep "stack size"


# 进入目录,先进行必要的清理
cd $target_dir;
# workdir_2=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir_2
# cd $workdir_2
make clean;

# 测试低精度的性能
make float;
echo ${kernel} float 0                  >> ${result_file};
${run_time_benchmark} ./${kernel}-ppcg-float.exe       >> ${result_file};

# 测试混合精度的性能
cat $my_rate_list | while read rate
do
    make amp RATE=${rate};
    echo ${kernel} lnlamp ${rate}      >> ${result_file};
    ${run_time_benchmark} ./${kernel}-amp_${rate}.exe   >> ${result_file};
done

# 测试高精度的性能
make double;
echo ${kernel} double 100               >> ${result_file};
${run_time_benchmark} ./${kernel}-ppcg-double.exe       >> ${result_file};