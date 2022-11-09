#########################################################################
# File Name: a_list_script_to_run_all_tests.sh
# Author:song guanghui(sheen song) 
# mail: sheensong@163.com
# Created Time: 2022年03月27日 星期日 22时50分14秒
# Description:  一次性全部测完
#########################################################################
#!/bin/bash
# 备份上一次的结果
now=$(date "+%Y-%m-%d__%H-%M")
# mv log/performance_test_result/times_of_compile_original.log  backup/times_of_compile_${now}.log 

./auto_run_all_test_of_func.sh 3d7pt
./auto_run_all_test_of_func.sh 3d27pt

./auto_run_all_test_of_func.sh fdtd-1d
./auto_run_all_test_of_func.sh fdtd-2d

./auto_run_all_test_of_func.sh heat-1d
./auto_run_all_test_of_func.sh heat-2d
./auto_run_all_test_of_func.sh heat-3d

./auto_run_all_test_of_func.sh jacobi-1d
./auto_run_all_test_of_func.sh jacobi-2d
./auto_run_all_test_of_func.sh seidel-2d

# 获取结果
./getting_all_log_and_result.sh