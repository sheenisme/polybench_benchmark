#!/bin/bash

# -DMEDIUM_DATASET：指定中等规模的数据集。
# -DPOLYBENCH_TIME：输出执行时间（gettimeofday）（即指定对程序进行计时）。
# -DPOLYBENCH_USE_SCALAR_LB：使用标量循环边界而不是参数循环边界。
# -DPOLYBENCH_DUMP_ARRAYS：将所有实时数组转储到stderr（即指定打印结果）
PARGS="-I utilities -DMEDIUM_DATASET -DPOLYBENCH_TIME -DPOLYBENCH_USE_SCALAR_LB -DPOLYBENCH_DUMP_ARRAYS";

for i in `cat utilities/benchmark_list`; 
do 
    perl utilities/create_cpped_version.pl $i "$PARGS";
done