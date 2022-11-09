#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir

# 验证输入参数是否合适
if [ $# -ne 1 ]; then
    echo "Usage:   ./run_all_dim_test.sh <rate>";
    echo "Example: ./run_all_dim_test.sh 50    ";
    exit 1;
fi;
rate=$1

rm -f run_result.log

# 设置堆栈空间为8G
ulimit -s 8388608
echo "用户区栈空间大小是:"
ulimit -a | grep "stack size"

# for element in `ls test_?d.c test_?d_?.c test_?d_??.c test_?d_???.c`
for element in `ls test_1d.c test_2d_?.c test_3d_?.c test_3d_??.c test_4d_?.c test_4d_???.c test_4d_??.c`
# for element in `ls test_4d_??.c  test_4d_???.c`
do
    name=${element%%.*}
    echo $name $rate 'start ....'
    # 生成混合精度代码
    ppcg --target c -R ${rate} ${name}.c -o ${name}_${rate}.amp_ppcg.c > /dev/null 2>&1
    # 插入计数器
    ./insert_size_count.sh ${name}_${rate}.amp_ppcg.c > /dev/null 2>&1
    # 编译
    gcc -g -O0 ${name}_${rate}.amp_ppcg.c -o ${name}_${rate}.out
    gcc -g -O0 ${name}.c -o ${name}_origion.out
    # 执行
    ./${name}_${rate}.out
    ./${name}_origion.out
    # ./${name}_${rate}.out   >> run_result.log 2>&1

    # 删除临时的中间文件。
    rm -f ${name}_${rate}.amp_ppcg.c
    rm -f ${name}_${rate}.out
    rm -f ${name}_origion.out
    echo $name $rate 'over!'
    echo 
    echo 
done