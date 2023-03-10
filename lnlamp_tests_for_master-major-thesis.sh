#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir

# 删除历史的测试结果
rm -f scripts/benchmark_result_perf-Reliable.log
rm -f scripts/lnlamp_correct_part_test.log
rm -f scripts/4D_Check.exe
# 要求：config.mk和lnlamp中编译器为gcc，且设置POLYBENCH_C99_PROTO，并且其过程中不设置循环分块，使用默认的isl调度算法，进行多次测试方可。



all_benchs=$(cat ./utilities/benchmark_list)
for bench in $all_benchs;
do
    benchdir=$(dirname $bench)
    benchname=$(basename $benchdir)
    # echo $benchdir " " $benchname
    # 进入脚本所在的目录进行测试
    cd $benchdir
    lnlamp ${benchname}.c
    cd $workdir
    cd scripts
    ./Reliable_perf_test.sh ../$benchdir $benchname  >> lnlamp_correct_part_test.log 2>&1
    
    # 返回测试脚本目录
    cd $workdir
done

echo "lnlamp correct test, over!"
# 返回测试脚本目录
cd $workdir