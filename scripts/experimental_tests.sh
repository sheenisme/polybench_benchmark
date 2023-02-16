#!/bin/bash
## 性能+误差 测试的脚本,在run-all.pl中调用该脚本对测试用例进行逐个测试.
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir



if [ $# -ne 2 ]; then
    echo "Usage: ./experimental_tests.sh <target_dir> <kernel>";
    echo "Example: ./experimental_tests.sh \"..//stencils/3d27pt\" 3d27pt";
    echo "Note: the file must be a Polybench program compiled with -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS";
    exit 1;
fi;
target_dir=$1
kernel=$2
# 编译4D检验法程序,如果编译可以通过,则用4d检验法求均值(可以自动去掉偏差),否则,直接退出.
gcc -O3 $workdir/4d_check.c -o 4d_check.exe > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "用4d检验法求均值(可以自动去掉偏差)的4d_check.c文件编译失败,请检查程序!!!"
    exit 1;
fi;



# 设置一些变量,方便后面调用.
# 设置测试性能时的频次
frequency=10
readonly frequency
result_file="$workdir/results/${kernel}_benchmark_result.log"
# echo $result_file
my_rate_list="$workdir/my_rate_list"
# 先删除之前的历史文件
rm -f ${result_file}
# 设置用户堆栈空间为8G
ulimit -s 8388608
# echo "用户区栈空间大小是:"
# ulimit -a | grep "stack size"
# 设置绑定核心
TASKSET=""
which taskset > /dev/null
if [ $? -eq 0 ]; then
    TASKSET="taskset -c 0 "
fi

# 进入目录,先进行必要的清理
cd $target_dir;
# workdir_2=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir_2
# cd $workdir_2
make clean;


# 测试高精度的性能和baseline的结果
make double;
$TASKSET ./${kernel}-ppcg-double.exe 2> ____tempfile_data.double.csv  >  ____tempfile_time_all.double.txt || return $?
$TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null                     >> ____tempfile_time_all.double.txt || return $?
$TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null                     >> ____tempfile_time_all.double.txt || return $?
$TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null                     >> ____tempfile_time_all.double.txt || return $?
for ((i=0; i<$frequency; i++))
do
    $TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null >> ____tempfile_time_all.double.txt || return $?
done
# 去掉两个最小的和两个最大的，对剩下的数据，用4d检验法求平均值
temp_var=`expr $frequency + 2`;
cat ____tempfile_time_all.double.txt | grep "[0-9]\+" | sort -n | head -n ${temp_var} | tail -n ${frequency} > ____tempfile_time.double.txt;
double_time=`$workdir/4d_check.exe  ____tempfile_time.double.txt`
# echo $double_time
# rm ____tempfile_time.double.txt
rm ____tempfile_time_all.double.txt
unset temp_var


# 测试低精度的性能和误差结果
make float;
$TASKSET ./${kernel}-ppcg-float.exe 2> ____tempfile_data.float.csv   >  ____tempfile_time_all.float.txt || return $?
$TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null                     >> ____tempfile_time_all.float.txt || return $?
$TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null                     >> ____tempfile_time_all.float.txt || return $?
$TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null                     >> ____tempfile_time_all.float.txt || return $?
for ((i=0; i<$frequency; i++))
do
    $TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null >> ____tempfile_time_all.float.txt || return $?
done
# 去掉两个最小的和两个最大的，对剩下的数据，用4d检验法求平均值
temp_var=`expr $frequency + 2`;
cat ____tempfile_time_all.float.txt | grep "[0-9]\+" | sort -n | head -n ${temp_var} | tail -n ${frequency} > ____tempfile_time.float.txt;
float_time=`$workdir/4d_check.exe  ____tempfile_time.float.txt`
float_error=`$workdir/check_error_loss.sh ____tempfile_data.double.csv ____tempfile_data.float.csv`
echo ${kernel}	float	-1  ${float_time}   ${float_error}  >> ${result_file};
# rm ____tempfile_time.float.txt ____tempfile_data.float.csv
rm ____tempfile_time_all.float.txt 
unset temp_var


# 测试混合精度的性能
cat $my_rate_list | while read rate
do  
    make amp RATE=${rate}
    $TASKSET ./${kernel}-amp_${rate}.exe 2> ____tempfile_data.amp.${rate}.csv  >  ____tempfile_time_all.amp.${rate}.txt || return $?
    $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null                          >> ____tempfile_time_all.amp.${rate}.txt || return $?
    $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null                          >> ____tempfile_time_all.amp.${rate}.txt || return $?
    $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null                          >> ____tempfile_time_all.amp.${rate}.txt || return $?
    for ((i=0; i<$frequency; i++))
    do
        $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null >> ____tempfile_time_all.amp.${rate}.txt || return $?
    done
    # 去掉两个最小的和两个最大的，对剩下的数据，用4d检验法求平均值
    temp_var=`expr $frequency + 2`;
    cat ____tempfile_time_all.amp.${rate}.txt | grep "[0-9]\+" | sort -n | head -n ${temp_var} | tail -n ${frequency} > ____tempfile_time.amp.${rate}.txt;
    amp_time=`$workdir/4d_check.exe  ____tempfile_time.amp.${rate}.txt`
    amp_error=`$workdir/check_error_loss.sh ____tempfile_data.double.csv ____tempfile_data.amp.${rate}.csv`
    echo ${kernel}	amp ${rate} ${amp_time} ${amp_error}  >> ${result_file};
    rm ____tempfile_time.amp.${rate}.txt ____tempfile_data.amp.${rate}.csv
    rm  ____tempfile_time_all.amp.${rate}.txt 
    unset temp_var amp_time amp_error
done

# 最后输出double的时间,删除误差基线的数据和4d_check.exe
echo ${kernel}	double	100 ${double_time}  "error cout: 0, error sum: 0, error mean: 0, error max: 0." >> ${result_file};
rm ____tempfile_data.double.csv
rm $workdir/4d_check.exe
