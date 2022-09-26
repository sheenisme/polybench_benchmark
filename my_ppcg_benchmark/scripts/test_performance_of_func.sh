#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 验证输入参数是否合适
if [ $# -ne 1 ]; then
    echo "Usage:   ./test_performance_of_func.sh <func_name>";
    echo "Example: ./test_performance_of_func.sh  3d27pt ";
    exit 1;
fi;

# 别名
func=$1
################################################################################################
#  根据函数名，进行不同类型的测试，测试结果放至log/performance_test_result目录下                    #
################################################################################################
# 开始测试之前，先清空以前的测试日志 
now=$(date "+%Y-%m-%d__%H-%M")
mv log/performance_test_result/${func}_ppcg_double_performance  backup2/${func}_ppcg_double_performance_${now}_back.log
mv log/performance_test_result/${func}_ppcg_float_performance   backup2/${func}_ppcg_float_performance_${now}_back.log
mv log/performance_test_result/${func}_amp_performance          backup2/${func}_amp_performance_${now}_back.log

# 所有的函数 都需要测不分块和只分块的版本
# 不分块的版本
./test_performance_of_type.sh $func no_all regen

# # 只分块的版本
# ./test_performance_of_type.sh $func only_tile regen 4
# ./test_performance_of_type.sh $func only_tile regen 8
# ./test_performance_of_type.sh $func only_tile regen 16
# ./test_performance_of_type.sh $func only_tile regen 32
# ./test_performance_of_type.sh $func only_tile regen 64
# ./test_performance_of_type.sh $func only_tile regen 128
# ./test_performance_of_type.sh $func only_tile regen 256
# ./test_performance_of_type.sh $func only_tile regen 512
# ./test_performance_of_type.sh $func only_tile regen 1024
# ./test_performance_of_type.sh $func only_tile regen 2048
# ./test_performance_of_type.sh $func only_tile regen 4096
# ./test_performance_of_type.sh $func only_tile regen 8192
# ./test_performance_of_type.sh $func only_tile regen 16384

# # # ##################################################
# # # 暂时不开多线程测试，太慢了                         #
# # # ##################################################

# # 某些函数还需要测并行版本，下面全是开多线程的测试
# # 需要openmp测试的函数名的数组
# array=(heat-3d 3d7pt 3d27pt fdtd-1d heat-1d heat-2d)
# # if func is in ( heat-3d3d7pt 3d27pt fdtd-1d heat-1d heat-2d)， then test openmp 
# if [[ "${array[@]}"  =~ "${func}" ]]; then
#     # 只并行的版本
#     ./test_performance_of_type.sh $func only_par regen 1
#     ./test_performance_of_type.sh $func only_par no_regen 2
#     ./test_performance_of_type.sh $func only_par no_regen 4
#     ./test_performance_of_type.sh $func only_par no_regen 8
#     # ./test_performance_of_type.sh $func only_par no_regen 16
#     # ./test_performance_of_type.sh $func only_par no_regen 32
#     # ./test_performance_of_type.sh $func only_par no_regen 64


#     # 下面是分块+并行版本
#     # 分块大小：8
#     ./test_performance_of_type.sh $func all regen 8 1
#     ./test_performance_of_type.sh $func all no_regen 8 2
#     ./test_performance_of_type.sh $func all no_regen 8 4
#     ./test_performance_of_type.sh $func all no_regen 8 8
#     # ./test_performance_of_type.sh $func all no_regen 8 16
#     # ./test_performance_of_type.sh $func all no_regen 8 32
#     # ./test_performance_of_type.sh $func all no_regen 8 64


#     # 分块大小：16
#     ./test_performance_of_type.sh $func all regen 16 1
#     ./test_performance_of_type.sh $func all no_regen 16 2
#     ./test_performance_of_type.sh $func all no_regen 16 4
#     ./test_performance_of_type.sh $func all no_regen 16 8
#     # ./test_performance_of_type.sh $func all no_regen 16 16
#     # ./test_performance_of_type.sh $func all no_regen 16 32
#     # ./test_performance_of_type.sh $func all no_regen 16 64


#     # 分块大小：32
#     ./test_performance_of_type.sh $func all regen 32 1
#     ./test_performance_of_type.sh $func all no_regen 32 2
#     ./test_performance_of_type.sh $func all no_regen 32 4
#     ./test_performance_of_type.sh $func all no_regen 32 8
#     # ./test_performance_of_type.sh $func all no_regen 32 16
#     # ./test_performance_of_type.sh $func all no_regen 32 32
#     # ./test_performance_of_type.sh $func all no_regen 32 64


#     # 分块大小：64
#     ./test_performance_of_type.sh $func all regen 64 1
#     ./test_performance_of_type.sh $func all no_regen 64 2
#     ./test_performance_of_type.sh $func all no_regen 64 4
#     ./test_performance_of_type.sh $func all no_regen 64 8
#     # ./test_performance_of_type.sh $func all no_regen 64 16
#     # ./test_performance_of_type.sh $func all no_regen 64 32
#     # ./test_performance_of_type.sh $func all no_regen 64 64


#     # 分块大小：128
#     ./test_performance_of_type.sh $func all regen 128 1
#     ./test_performance_of_type.sh $func all no_regen 128 2
#     ./test_performance_of_type.sh $func all no_regen 128 4
#     ./test_performance_of_type.sh $func all no_regen 128 8
#     # ./test_performance_of_type.sh $func all no_regen 128 16
#     # ./test_performance_of_type.sh $func all no_regen 128 32
#     # ./test_performance_of_type.sh $func all no_regen 128 64


#     # 分块大小：256
#     ./test_performance_of_type.sh $func all regen 256 1
#     ./test_performance_of_type.sh $func all no_regen 256 2
#     ./test_performance_of_type.sh $func all no_regen 256 4
#     ./test_performance_of_type.sh $func all no_regen 256 8
#     # ./test_performance_of_type.sh $func all no_regen 256 16
#     # ./test_performance_of_type.sh $func all no_regen 256 32
#     # ./test_performance_of_type.sh $func all no_regen 256 64


#     # 分块大小：512
#     ./test_performance_of_type.sh $func all regen 512 1
#     ./test_performance_of_type.sh $func all no_regen 512 2
#     ./test_performance_of_type.sh $func all no_regen 512 4
#     ./test_performance_of_type.sh $func all no_regen 512 8
#     # ./test_performance_of_type.sh $func all no_regen 512 16
#     # ./test_performance_of_type.sh $func all no_regen 512 32
#     # ./test_performance_of_type.sh $func all no_regen 512 64


#     # 分块大小：1024
#     ./test_performance_of_type.sh $func all regen 1024 1
#     ./test_performance_of_type.sh $func all no_regen 1024 2
#     ./test_performance_of_type.sh $func all no_regen 1024 4
#     # ./test_performance_of_type.sh $func all no_regen 1024 8
#     # ./test_performance_of_type.sh $func all no_regen 1024 16
#     # ./test_performance_of_type.sh $func all no_regen 1024 32
#     # ./test_performance_of_type.sh $func all no_regen 1024 64


#     # 分块大小：2048
#     ./test_performance_of_type.sh $func all regen 2048 1
#     ./test_performance_of_type.sh $func all no_regen 2048 2
#     ./test_performance_of_type.sh $func all no_regen 2048 4
#     # ./test_performance_of_type.sh $func all no_regen 2048 8
#     # ./test_performance_of_type.sh $func all no_regen 2048 16
#     # ./test_performance_of_type.sh $func all no_regen 2048 32
#     # ./test_performance_of_type.sh $func all no_regen 2048 64

#     # 分块大小：4096
#     ./test_performance_of_type.sh $func all regen 4096 1
#     ./test_performance_of_type.sh $func all no_regen 4096 2
#     ./test_performance_of_type.sh $func all no_regen 4096 4
#     # ./test_performance_of_type.sh $func all no_regen 4096 8
#     # ./test_performance_of_type.sh $func all no_regen 4096 16
#     # ./test_performance_of_type.sh $func all no_regen 4096 32
#     # ./test_performance_of_type.sh $func all no_regen 4096 64


#     # 分块大小：8192
#     ./test_performance_of_type.sh $func all regen 8192 1
#     ./test_performance_of_type.sh $func all no_regen 8192 2
#     ./test_performance_of_type.sh $func all no_regen 8192 4
#     # ./test_performance_of_type.sh $func all no_regen 8192 8
#     # ./test_performance_of_type.sh $func all no_regen 8192 16
#     # ./test_performance_of_type.sh $func all no_regen 8192 32
#     # ./test_performance_of_type.sh $func all no_regen 8192 64
# fi
