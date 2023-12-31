#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir

array=( 1 0.1 0.01 0.001 0.0001 0.00001 0.000001 )
for element in ${array[@]}
do
    err_thr="-e ${element}"

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
                lnlamp -a feautrier -t '{[1,4,8,16,32]}' ${benchname}.c ${err_thr}
                echo "lnlamp -a feautrier -t {[1,4,8,16,32]} ${benchname}.c ${err_thr} over! "
                ;;
            heat-3d)
                lnlamp -a feautrier -t '{[1,1,8,16,16]}' ${benchname}.c ${err_thr}
                echo "lnlamp -a feautrier -t {[1,1,8,16,16]} ${benchname}.c ${err_thr} over! "
                ;;
            correlation)
                lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${err_thr}
                echo "lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${err_thr} over! "
                ;;
            covariance)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,8,8,8]}' ${benchname}.c ${err_thr}
                echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,8,8,8]}' ${benchname}.c ${err_thr} over! "
                ;;
            gramschmidt)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -a feautrier -t '{[16,8,8,8,8]}' ${benchname}.c ${err_thr}
                echo "lnlamp -a feautrier -t {[16,8,8,8,8]} ${benchname}.c ${err_thr} over! "
                ;;
            lu)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[64,64,64,64]}' ${benchname}.c ${err_thr}
                echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[64,64,64,64]}' ${benchname}.c ${err_thr} over! "
                ;;
            cholesky)
                lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,16,16,16]}' ${benchname}.c ${err_thr}
                echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,16,16,16]}' ${benchname}.c ${err_thr} over! "
                ;;
            symm)
                lnlamp -t '{[256,256,256,256,256]}' ${benchname}.c ${err_thr}
                echo "lnlamp -t '{[256,256,256,256,256]}' ${benchname}.c ${err_thr} over! "
                ;;
            adi)
                lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${err_thr}
                echo "lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c ${err_thr} over! "
                ;;
            *)
                lnlamp -t '{[1,4,8,16,32]}' ${benchname}.c ${err_thr}
                echo "lnlamp -t '{[1,4,8,16,32]}' ${benchname}.c ${err_thr} over! "
        esac
        echo ""

        # 返回测试脚本目录
        cd $workdir
    done

    # 返回测试脚本目录
    cd $workdir
    rm -rf build
    rm -rf result-out

    err_thr=${err_thr// /-}
    ./taffo_collect-fe-stats.sh "temp_test_res_${err_thr}"

    echo "lnlamp ${err_thr} test, over!"
    # 返回测试脚本目录
    cd $workdir
done
