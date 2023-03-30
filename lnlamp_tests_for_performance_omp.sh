#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir

# 设置编译脚本
sed -n "s/OMPSET=\" \"/OMPSET=\"-fopenmp\"/p" taffo_compiler.sh
sed -i "s/OMPSET=\" \"/OMPSET=\"-fopenmp\"/g" taffo_compiler.sh



array=( 2 4 8 )
for element in ${array[@]}
do
    omp_set="-o ${element}"
    rate_set=(1 12 25 37 50 62 75 87 99)
    # 先将run的脚本设置成对应的核数
    sed -n "s/OMP_NUM_THREADS=1/OMP_NUM_THREADS=${element}/p" taffo_run.sh
    sed -i "s/OMP_NUM_THREADS=1/OMP_NUM_THREADS=${element}/g" taffo_run.sh

    # 调用lnlamp
    all_benchs=$(cat ./utilities/benchmark_list_performance)
    for bench in $all_benchs;
    do
        benchdir=$(dirname $bench)
        benchname=$(basename $benchdir)
        # echo $benchdir " " $benchname
        # 进入测试用例的目录进行测试
        cd $benchdir

        # 根据测试用例，选择不同的调度算法
        case "${benchname}" in
            seidel-2d|jacobi-2d|fdtd-2d|trmm|doitgen|gemm|2mm|3mm)
                lnlamp -a feautrier -t '{[1,4,8,16,32]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -a feautrier -t {[1,4,8,16,32]} ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            heat-3d)
                lnlamp -a feautrier -t '{[1,1,8,16,16]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -a feautrier -t {[1,1,8,16,16]} ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            correlation)
                lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"; 
                echo "lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            covariance)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,8,8,8]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,8,8,8]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            gramschmidt)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -a feautrier -t '{[16,8,8,8,8]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -a feautrier -t {[16,8,8,8,8]} ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            lu)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[64,64,64,64]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[64,64,64,64]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            cholesky)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,16,16,16]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,16,16,16]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            symm)
                lnlamp -t '{[256,256,256,256,256]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -t '{[256,256,256,256,256]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            adi)
                lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
                ;;
            *)
                lnlamp -t '{[1,4,8,16,32]}' ${benchname}.c ${omp_set} -r "$(echo ${rate_set[*]})"
                echo "lnlamp -t '{[1,4,8,16,32]}' ${benchname}.c ${omp_set} -r \"$(echo ${rate_set[*]})\" over! "
        esac
        echo ""

        # 返回测试脚本目录
        cd $workdir
    done

    # 返回测试脚本目录
    cd $workdir
    rm -rf build
    rm -rf result-out

    omp_set=${omp_set// /_}
    # echo ${omp_set}
    
    # 编译获取误差和性能加速比
    ./taffo_collect-fe-stats.sh "omp_test_res_${omp_set}"
    
    # echo "omp_test_res_${omp_set}"
    echo "lnlamp temp test, over!"

    # 进行清理
    cd $workdir
    cd utilities/
    perl clean.pl ../
    perl makefile-gen.pl ../  -cfg

    # 返回测试脚本目录
    cd $workdir



    # 重置run的脚本
    sed -n "s/OMP_NUM_THREADS=${element}/OMP_NUM_THREADS=1/p" taffo_run.sh
    sed -i "s/OMP_NUM_THREADS=${element}/OMP_NUM_THREADS=1/g" taffo_run.sh
done



# 复原编译脚本
sed -n "s/OMPSET=\"-fopenmp\"/OMPSET=\" \"/p" taffo_compiler.sh
sed -i "s/OMPSET=\"-fopenmp\"/OMPSET=\" \"/g" taffo_compiler.sh
