a_list_script_to_run_all_test.sh  单线程跑全部脚本
auto_run_all_test_of_func.sh      需要参数函数名(jacobi-1d等)，会跑该函数的全部测试
get_all_log_and_result.sh         获取全部日志和结果

Check.log             是误差测试的结果
Min_performance.log   是性能测试的结果


###### 原始测试案例有：fdtd-2d jacobi-1d jacobi-2d seidel-2d heat-3d
已全部测完，并备份到backup2/下面
heat-3d    1000 * 200^3           200^3 * 2                     < 2^24 elements 
fdtd-2d    3072 * 2048 * 2557     2048 * 2557  * 3 + 3072       < 2^24 elements
seidel-2d  2048 * 1024^2          1024^2                        = 2^20 elements
jacobi-2d  2048 * 2048^2          2048^2 * 2                    = 2^23 elements
jacobi-1d  81920 * 20480          20480 * 2                     < 2^16 elements


###### 新增的测试案例有：fdtd-1d heat-1d heat-2d 3d7pt 3d27pt
3d7pt      1200 * 128^3           128^3 * 2
3d27pt      800 * 128^3           128^3 * 2
fdtd-1d    100000 * 10240         10240 * 2
heat-1d    100000 * 10240         10240 * 2
heat-2d    8000 * 1024^2          1024^2 * 2


### note:
之前的测试脚本在useless_scripts下面，现在只需要auto_run_all_test_of_func.sh + 函数名即可进行测试。
time_benchmark.sh是跑五次，去掉最低和最高，剩下的三个求平均即为最终结果。