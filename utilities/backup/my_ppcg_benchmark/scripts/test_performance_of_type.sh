#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir


if [ $# -lt 3 ]; then
    echo "Usage:   ./test_performance_of_type.sh  funcname  type  gen_type  tile-size amp-rate";
    echo "Example: ./test_performance_of_type.sh  heat-3d   all    regen      128        1 ";
    exit 1;
fi

# 别名
line=$1
echo "now will test $line(funcname), the options is $2(type)、$3(regen_or_not)、$4(tile-size or omp-threads[when only paral])、$5(omp-threads or not)"
# 设置用户堆栈空间为8G
ulimit -s 8388608
echo "用户区栈空间大小是:"
ulimit -a | grep "stack size"


if test $2 == "no_all"
then
    # PPCG的参数
    OPENMP=''
    TIlE=''

    # 编译的参数
    CC=gcc 

    # 运行时参数
    export OMP_NUM_THREADS=0
elif test $2 == "only_tile"
then
    # PPCG的参数
    OPENMP=''
    TILE='--tile --tile-size='$4

    # 编译的参数
    CC=gcc 

    # 运行时参数
    export OMP_NUM_THREADS=0
elif test $2 == "only_par"
then
    # PPCG的参数
    OPENMP='--openmp'
    TILE=''

    # 编译的参数
    CC='gcc -fopenmp'

    # 运行时参数
    export OMP_NUM_THREADS=$4
elif test $2 == "all"
then
    # PPCG的参数
    # OPENMP=''
    # TIlE=''
    OPENMP='--openmp'
    TILE='--tile --tile-size='$4

    # 编译的参数
    CC='gcc -fopenmp'
    # CC=gcc 

    # 运行时参数
    export OMP_NUM_THREADS=$5
else
    echo "第二个参数出错，请检查!"
fi


# 编译的参数，一般保持不动
CFLAGS="-O0 -DPOLYBENCH_USE_C99_PROTO"
# EXITFLAGS="-DPOLYBENCH_PAPI -lpapi"
EXITFLAGS=""
# CFLAGS_OPTION="-DPOLYBENCH_TIME -DPOLYBENCH_CYCLE_ACCURATE_TIMER"
CFLAGS_OPTION="-DPOLYBENCH_TIME"


if test $3 != "no_regen"
then
    echo "下面开始重新生成代码并编译, tile is: ${TILE}, omp is: ${OPENMP}"
    ################################################################################################
    #  使用ppcg重新生成代码,并将AMP代码移动到src测试目录下                                            #
    ################################################################################################
    ppcg --target=c ${TILE} --no-automatic-mixed-precision ${OPENMP} ../src/${line}.c -o ${line}.ppcg.c
    mv ${line}.ppcg.c ../src/
    echo "    生成ppcg代码并移动" ${line}.ppcg.c "完成!"
    
    # for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
    cat my_rate_list | while read rate
    do
        ppcg --target=c ${TILE} -R $rate ${OPENMP} ../src/${line}.c -o ${line}_${rate}.amp_ppcg.c
        mv ${line}_${rate}.amp_ppcg.c ../src/
        echo "重新生成amp代码并移动" ${line}.amp_ppcg.c "完成!"
    done


    #########################################################################################################################
    #  编译src目录下的代码，生成可执行文件                                                                                     #
    #  ${VERBOSE} ${CC} -o gemm gemm.c ${CFLAGS} -I. -I../../../utilities ../../../utilities/polybench.c ${EXTRA_FLAGS}     #
    #########################################################################################################################
    echo ""
    echo "下面开始重新编译,编译选项是: ${CC} ${CFLAGS} ${CFLAGS_OPTION} ...... ${EXITFLAGS}"

    ${CC} ${CFLAGS} ${CFLAGS_OPTION} -DNO_PENCIL_KILL -DDATA_TYPE_IS_DOUBLE=1 -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.ppcg.c ${EXITFLAGS} -o ../obj/${line}_ppcg_double.out 
    echo "编译" ${line}"（ppcg double） 完成!"

    ${CC} ${CFLAGS} ${CFLAGS_OPTION} -DNO_PENCIL_KILL -DDATA_TYPE_IS_FLOAT=1  -I. -I../../utilities ../../utilities/polybench.c ../src/${line}.ppcg.c ${EXITFLAGS} -o ../obj/${line}_ppcg_float.out 
    echo "编译" ${line}"（ppcg float ） 完成!"

    # for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
    cat my_rate_list | while read rate
    do
        ${CC} ${CFLAGS} ${CFLAGS_OPTION}  -I. -I../../utilities ../../utilities/polybench.c ../src/${line}_${rate}.amp_ppcg.c  ${EXITFLAGS} -o ../obj/${line}_${rate}_amp.out
        echo "编译" ${line}_${rate}" （ amp ） 完成!"
    done
else
    echo "不需要重新生成代码和编译代码! "
fi


#########################################################################################################################
#  用time_benchmark_of_func.sh 运行src目录下的可执行文件，获取性能结果                                                     #
#########################################################################################################################
echo ""
temp=`echo  ${TILE} | tr -cd "[0-9]" `
# str=`echo 'tile-'$temp'_omp-'$OMP_NUM_THREADS`
echo '下面开始运行, 分块大小是: '$temp', 线程数是: '$OMP_NUM_THREADS

./time_benchmark_of_func.sh ../obj/${line}_ppcg_double.out > ../output/origion/${line}_ppcg_double_performance 2>&1
echo "运行" ${line}"（ppcg double） 完成!"

./time_benchmark_of_func.sh ../obj/${line}_ppcg_float.out > ../output/origion/${line}_ppcg_float_performance 2>&1
echo "运行" ${line}"（ppcg float ） 完成!"

# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    ./time_benchmark_of_func.sh ../obj/${line}_${rate}_amp.out > ../output/amp_ppcg/${line}_${rate}_performance 2>&1
    echo "运行" ${line}_${rate}" （ amp ） 完成!"
done


#########################################################################################################################
#  获取ouput下面的性能信息                                                                                               #
#########################################################################################################################
# today=$(date "+%Y-%m-%d")
today='performance_test_result'

echo "when tile($temp) omp($OMP_NUM_THREADS), the ppcg ${line} double performance is : " >> log/${today}/${line}_ppcg_double_performance
cat ../output/origion/${line}_ppcg_double_performance >> log/${today}/${line}_ppcg_double_performance
# echo "获取" ${line}_performance "（ppcg double） 完成!"

echo "when tile($temp) omp($OMP_NUM_THREADS), the ppcg ${line} float  performance is : " >> log/${today}/${line}_ppcg_float_performance
cat ../output/origion/${line}_ppcg_float_performance  >> log/${today}/${line}_ppcg_float_performance
# echo "获取" ${line}_performance "（ppcg float ） 完成!" 

# for rate in 5 10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95
cat my_rate_list | while read rate
do
    echo "when tile($temp) omp($OMP_NUM_THREADS), the AMP ${line} ${rate} performance is : " >> log/${today}/${line}_amp_performance
    cat ../output/amp_ppcg/${line}_${rate}_performance >> log/${today}/${line}_amp_performance
    # echo "获取" ${line}_${rate}_performance "（ ppcg amp ） 完成!"
done
