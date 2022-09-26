#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir

# 先删除之前的性能数据
rm -f performance_data_of_chart.txt
rm -f performance_result_of_data_in_chart.csv
rm -f performance_result.png
# 获取性能数据
for func in 3d27pt 3d7pt fdtd-1d fdtd-2d heat-1d heat-2d heat-3d jacobi-1d jacobi-2d seidel-2d 
do
    cat ../${func}_ppcg_float_performance > ${func}_all_performance
    cat ../${func}_amp_performance >> ${func}_all_performance
    ./get_func_rate_time_of_file.sh ${func}_all_performance >> performance_data_of_chart.txt
    # 删除临时的文件
    rm -f ${func}_all_performance
done

# 先删除之前的误差数据
rm -f error_data_of_chart.txt
rm -f error_result_of_data_in_chart.csv
# 获取误差数据
for func in 3d27pt 3d7pt fdtd-1d fdtd-2d heat-1d heat-2d heat-3d jacobi-1d jacobi-2d seidel-2d
do
    ./get_func_rate_error_of_file.sh ../../check/${func}_check.log >> error_data_of_chart.txt
done

# 画图
python3 draw_line_chart.py 

# 将误差数据复制到申威平台测试数据集那里
cp error_data_of_chart.txt ../../../../temp_tests/sw_test_data/error_data_of_chart.txt
