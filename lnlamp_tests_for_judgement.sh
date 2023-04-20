#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir

# 删除历史的测试结果
rm -f scripts/benchmark_result_perf-Reliable.log
rm -f scripts/benchmark_test.log
rm -f scripts/benchmark_mean_result.log
rm -f scripts/4D_Check.exe

# add makefile
cd utilities/
perl makefile-gen.pl ../ -cfg
cd $workdir


all_benchs=$(cat ./utilities/benchmark_list_judgement)
for bench in $all_benchs;
do
    benchdir=$(dirname $bench)
    benchname=$(basename $benchdir)
    # echo $benchdir " " $benchname
    # 进入脚本所在的目录进行测试
    cd $benchdir
    lnlamp -a no ${benchname}.c
    cd $workdir
    cd scripts
    ./Reliable_perf_test.sh ../$benchdir $benchname  >> benchmark_test.log 2>&1
    
    # 返回测试脚本目录
    cd $workdir
done

echo "lnlamp correct test, over!"
# 返回测试脚本目录
cd $workdir
