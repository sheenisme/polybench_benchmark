#!/bin/bash

# 输入和输出文件名
inputFile="benchmark_result_perf-Reliable.log"
outputFile="result_real.csv"

# 创建一个空的文件，用于存放处理后的结果
echo -n "" > $outputFile

# 获取文件中所有测试用例名字
cases=$(awk '{print $1}' $inputFile | sort | uniq)

# 遍历所有测试用例
for case in $cases
do
    # 获取ratio为100对应的运行时间，作为基准
    baseTime=$(awk -v casename=$case '$1==casename && $3==100 {print $NF}' $inputFile)

    # 获取当前测试用例下的所有测试数据行
    lines=$(grep -E "^$case " $inputFile)

    # 遍历所有行，计算性能收益并输出到结果文件
    echo "$case:" >> $outputFile
    echo "$lines" | while read line
    do
        # 提取比例和运行时间
        ratio=$(echo $line | awk '{print $3}')
        time=$(echo $line | awk '{print $NF}')

        # 计算性能收益
        gain=$(echo "$time - $baseTime" | bc)
        
        # 对小于1的小数进行处理，如果小于1，添加0
        str=$(echo $gain | awk  '{if($1 < 1 && $1 > -1) printf "%0.9f",$1; else print $1}')

        # 如果ratio是-1，1或者100, 则跳过此次循环
        if [ $ratio == -1 ] || [ $ratio == 1 ] || [ $ratio == 100 ]; then
             continue
        else
            # 输出结果
            echo "$ratio $str" >> $outputFile
        fi
    done
done