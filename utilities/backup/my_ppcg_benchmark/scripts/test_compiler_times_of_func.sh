#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 验证输入参数是否合适
if [ $# -ne 1 ]; then
    echo "Usage:   ./test_compiler_times_of_func.sh <func_name>";
    echo "Example: ./test_compiler_times_of_func.sh  3d7pt ";
    exit 1;
fi;

# 别名
line=$1

# 设置用户堆栈空间为8G
ulimit -s 8388608
# echo "用户区栈空间大小是:"
# ulimit -a | grep "stack size"

#########################################################################################################################
#  编译src目录下的代码，记录编译时长                                                                                       #
#########################################################################################################################
# 只测试不分块版本的代码的编译时长即可，因为循环分块是PPCG的功能，不是本文开发的功能。
# 使用 date +%s%N 可以获得一个纳秒级的unix时间戳(当前时间)
# 先初始化为0.0
time_original_sourced=0.0
for i in {1..10}
do
    start=`date +%s%N`
    ppcg --target=c --no-automatic-mixed-precision ../src/${line}.c -o ${line}_temp.ppcg.c
    end=`date +%s%N`
    time=$((($end-$start)/1000000))
    time_original_sourced=$(echo "cale=3; $time + $time_original_sourced" | bc)
    # echo -e "\n time_original_sourced test finish.\n"
    rm ${line}_temp.ppcg.c   
done
time_original_sourced=$(echo "scale=1; $time_original_sourced/10" | bc)

# 初始化time_amp为0
time_amp=0.0
# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    start=`date +%s%N`
    ppcg --target=c -R $rate ../src/${line}.c -o ${line}_${rate}_temp.amp_ppcg.c
    end=`date +%s%N`
    time=$((($end-$start)/1000000))
    time_amp=$(echo "cale=3; $time + $time_amp" | bc)  
    rm ${line}_${rate}_temp.amp_ppcg.c
done
time_amp=$(echo "scale=1; $time_amp/19" | bc)
# echo -e "\n float sourced test finish.\n"
echo "ppcg 编译时长是: $time_original_sourced 毫秒,我们的编译时长是: $time_amp 毫秒" 

# 将结果写入日志文件
echo "${line} 编译耗时以及源程序执行时间是：" >> log/performance_test_result/times_of_compile_original.log
echo "ppcg 编译时长是: $time_original_sourced 毫秒,我们的编译时长是: $time_amp 毫秒" >> log/performance_test_result/times_of_compile_original.log

#########################################################################################################################
#  论文中还需要原始程序的执行时间，所以还需要编译跑一下原始程序的执行时间                                                     #
#########################################################################################################################
# 编译的参数，一般保持不动
CC=gcc 
CFLAGS="-O2 -DPOLYBENCH_USE_C99_PROTO"
EXITFLAGS=""
CFLAGS_OPTION="-DPOLYBENCH_TIME"

${CC} ${CFLAGS} ${CFLAGS_OPTION} -DNO_PENCIL_KILL -DDATA_TYPE_IS_DOUBLE=1 -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.c ${EXITFLAGS} -o ../obj/${line}_double.out 
# echo "编译" ${line}"（origion double） 完成!"

${CC} ${CFLAGS} ${CFLAGS_OPTION} -DNO_PENCIL_KILL -DDATA_TYPE_IS_FLOAT=1  -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.c ${EXITFLAGS} -o ../obj/${line}_float.out 
# echo "编译" ${line}"（origion float ） 完成!"

# 跑起来吧，还将程序结果放置到对应的日志文件夹。
./time_benchmark_of_func.sh ../obj/${line}_double.out > ../output/origion/${line}_double_performance 2>&1
echo "运行" ${line}"(original double)  完成!" 

./time_benchmark_of_func.sh ../obj/${line}_float.out > ../output/origion/${line}_float_performance 2>&1
echo "运行" ${line}"(original float )  完成!"

# 获取原始程序耗时结果
cat ../output/origion/${line}_double_performance >> log/performance_test_result/times_of_compile_original.log
cat ../output/origion/${line}_float_performance >> log/performance_test_result/times_of_compile_original.log
echo "已将全部日志数据存放在log文件夹下, 程序即将退出, 感谢您的使用, 再见!"