#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 验证输入参数是否合适
if [ $# -ne 1 ]; then
    echo "Usage:   ./check_result_of_func.sh <func_name>";
    echo "Example: ./check_result_of_func.sh   3d27pt ";
    exit 1;
fi;

# 设置用户堆栈空间为8G
ulimit -s 8388608
# echo "用户区栈空间大小是:"
# ulimit -a | grep "stack size"

# 别名
line=$1
#########################################################################################################################
#  编译目录下的check代码，生成可执行文件.然后运行他，默认收集所有结果到temp_result_all下，误差结果显示到屏幕上。                #
#########################################################################################################################
CC=gcc
CFLAGS="-O0 -DPOLYBENCH_DUMP_ARRAYS"

# 拷贝过来头文件，保证与src下的一致
cp ../src/${line}.h ./
cp ../scripts/my_rate_list ./

${CC} ${CFLAGS} ${CFLAGS_OPTION}  -I. -I../../utilities ../../utilities/polybench.c ${line}_check.c  -o ../obj/${line}_check.out
# echo "编译"  ${line}_check.c " 完成!"

# 太占磁盘空间了,大规模测试就不把amp的结果再集中到一个文件diff了
# echo "" > temp_result_all/${line}_check_all_output
# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    # ../obj/${line}_check.out ${rate} 2>> temp_result_all/${line}_check_all_output
    ../obj/${line}_check.out ${rate} 2> temp.txt
    echo "运行 check.out of "${line} ${rate}" 完成!"
done

# diff再核查一下，感觉没必要了，这部分大批量时太慢了。
# echo "diff" temp_result_all/${line}_check_all_output ../scripts/final_result/${line}_amp_result "（amp结果正确？）:"
# diff temp_result_all/${line}_check_all_output ../scripts/final_result/${line}_amp_result

# echo "diff" ../output/origion/${line}_double_result ../output/origion/${line}_ppcg_double_result "（ppcg结果正确？）:"
# diff ../output/origion/${line}_double_result ../output/origion/${line}_ppcg_double_result

# echo "diff over!"
echo ""
