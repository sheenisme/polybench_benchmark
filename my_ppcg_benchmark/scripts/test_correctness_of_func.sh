#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 验证输入参数是否合适
if [ $# -ne 1 ]; then
    echo "Usage:   ./test_correctness_of_func.sh <func_name>";
    echo "Example: ./test_correctness_of_func.sh  3d27pt ";
    exit 1;
fi;

# 别名
line=$1

# 设置用户堆栈空间为8G
ulimit -s 8388608
# echo "用户区栈空间大小是:"
# ulimit -a | grep "stack size"

#########################################################################################################################
#  编译src目录下的代码，生成可执行文件，然后运行它，结果在output下，收集所有amp结果到final_result下,PAPI检测结果显示到屏幕上。  #
#  再然后调用correct_check下的检查脚本去检查它,检查结果在log/check/$line_check.log下                                       #
#########################################################################################################################
# 测试之前先生成不分块版本的代码
ppcg --target=c --no-automatic-mixed-precision ../src/${line}.c -o ${line}.ppcg.c
mv ${line}.ppcg.c ../src/
# echo "    生成ppcg代码并移动" ${line}.ppcg.c "完成!"

# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    ppcg --target=c -R $rate ../src/${line}.c -o ${line}_${rate}.amp_ppcg.c
    mv ${line}_${rate}.amp_ppcg.c ../src/
    # echo "重新生成amp代码并移动" ${line}.amp_ppcg.c "完成!"
done

# 编译src下的代码
CC=gcc 
CFLAGS="-O0 -DPOLYBENCH_USE_C99_PROTO"
CFLAGS_OPTION="-DPOLYBENCH_DUMP_ARRAYS"
######################################################################################################
# 千万注意，开启PAPI会影响结果！ # EXITFLAGS="-DPOLYBENCH_PAPI -lpapi"                                                                      #
######################################################################################################
EXITFLAGS=""
# echo "编译选项是: ${CC} ${CFLAGS} ${CFLAGS_OPTION} ...... ${EXITFLAGS}"

${CC} ${CFLAGS} ${CFLAGS_OPTION} -DNO_PENCIL_KILL -DDATA_TYPE_IS_DOUBLE=1 -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.c ${EXITFLAGS} -o ../obj/${line}_double.out 
# echo "编译" ${line}"（origion double） 完成!"

${CC} ${CFLAGS} ${CFLAGS_OPTION} -DNO_PENCIL_KILL -DDATA_TYPE_IS_FLOAT=1  -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.c ${EXITFLAGS} -o ../obj/${line}_float.out 
# echo "编译" ${line}"（origion float ） 完成!"

${CC} ${CFLAGS} ${CFLAGS_OPTION} -DDATA_TYPE_IS_DOUBLE=1 -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.ppcg.c ${EXITFLAGS} -o ../obj/${line}_ppcg_double.out 
# echo "编译" ${line}"（ppcg double） 完成!"

${CC} ${CFLAGS} ${CFLAGS_OPTION} -DDATA_TYPE_IS_FLOAT=1  -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.ppcg.c ${EXITFLAGS} -o ../obj/${line}_ppcg_float.out 
# echo "编译" ${line}"（ppcg float ） 完成!"

# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    ${CC} ${CFLAGS} ${CFLAGS_OPTION}  -I. -I../../utilities ../../utilities/polybench.c ../src/${line}_${rate}.amp_ppcg.c  ${EXITFLAGS} -o ../obj/${line}_${rate}_amp.out
    # echo "编译" ${line}_${rate}" （ amp ） 完成!"
done


# 运行
../obj/${line}_double.out 2> ../output/origion/${line}_double_result
echo "运行" ${line}"（origion double） 完成!"

../obj/${line}_float.out  2> ../output/origion/${line}_float_result
echo "运行" ${line}"（origion  float） 完成!"

../obj/${line}_ppcg_double.out 2> ../output/origion/${line}_ppcg_double_result
echo "运行" ${line}"（ppcg double） 完成!"

../obj/${line}_ppcg_float.out  2> ../output/origion/${line}_ppcg_float_result
echo "运行" ${line}"（ppcg  float） 完成!"

# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    ../obj/${line}_${rate}_amp.out 2> ../output/amp_ppcg/${line}_${rate}_result
    echo "运行" ${line}_${rate}" （ amp ） 完成!"
done

# # 获取AMP的结果到一个文件中，如果是大规模，太占磁盘，需要注释掉，因为确实没必要
# echo "" > final_result/${line}_amp_result
# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
# cat my_rate_list | while read rate
# do
#     # echo "AMP result is : " >> final_result/${line}_amp_result
#     cat ../output/amp_ppcg/${line}_${rate}_result >> final_result/${line}_amp_result
#     # echo "获取" ${line}_${rate}_result  "（ amp ） 完成!"
# done


# 调用correct_check下的正确检查脚本，进行检查
# echo "  check ${line} correctness result is :"   > log/check/${line}_check.log
bash ../correct_check/check_result_of_func.sh ${line} > log/check/${line}_check.log

echo "check over!"
