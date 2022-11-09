#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 备份上一次的结果
now=$(date "+%Y-%m-%d__%H-%M")
# mv Papi_result.log     backup2/Papi_result_${now}.log
mv Check_result.log    backup2/Check_result_${now}.log
mv Min_perforamce.log  backup2/Min_perforamce_${now}.log
mv Performance_result.png backup2/Performance_result_${now}.png

# 删除之前的数据
rm log/performance_test_result/min_perforamce.log
# 一次获取所有日志到log根目录下
for func in fdtd-2d jacobi-1d jacobi-2d seidel-2d heat-3d 3d7pt 3d27pt fdtd-1d heat-1d heat-2d
# for func in 3d7pt 3d27pt fdtd-1d heat-1d heat-2d
do
    cat log/check/${func}_check.log >> Check_result.log
    # cat log/papi/${func}_papi.log  >>  Papi_result.log

    bash log/performance_test_result/get_all_min_log_of_func.sh  ${func}
done
cp log/performance_test_result/min_perforamce.log  Min_perforamce.log
# echo "" >> Min_perforamce.log
# cat log/performance_test_result/times_of_compile_original.log >> Min_perforamce.log

# 获取rate的性能结果图
bash log/performance_test_result/charts/get_all_date_of_chart.sh
cp log/performance_test_result/charts/performance_result.png Performance_result.png