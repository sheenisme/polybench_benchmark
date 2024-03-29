#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir



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
            lnlamp -a feautrier -t '{[1,4,8,16,32]}' ${benchname}.c
            echo "lnlamp -a feautrier -t {[1,4,8,16,32]} ${benchname}.c over! "
            ;;
        heat-3d)
            lnlamp -a feautrier -t '{[1,1,8,16,16]}' ${benchname}.c
            echo "lnlamp -a feautrier -t {[1,1,8,16,16]} ${benchname}.c over! "
            ;;
        correlation)
            lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c
            echo "lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c over! "
            ;;
        covariance)
            lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,8,8,8]}' ${benchname}.c
            echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,8,8,8]}' ${benchname}.c over! "
            ;;
        gramschmidt)
            lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -a feautrier -t '{[16,8,8,8,8]}' ${benchname}.c
            echo "lnlamp -a feautrier -t {[16,8,8,8,8]} ${benchname}.c over! "
            ;;
        lu)
            lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[64,64,64,64]}' ${benchname}.c
            echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[64,64,64,64]}' ${benchname}.c over! "
            ;;
        cholesky)
            lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,16,16,16]}' ${benchname}.c
            echo "lnlamp -i '--isl-schedule-max-coefficient=1 --isl-schedule-max-constant-term=0 ' -t '{[16,16,16,16,16]}' ${benchname}.c over! "
            ;;
        symm)
            lnlamp -t '{[256,256,256,256,256]}' ${benchname}.c
            echo "lnlamp -t '{[256,256,256,256,256]}' ${benchname}.c over! "
            ;;
        adi)
            lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c
            echo "lnlamp -t '{[8,8,8,8,8]}' ${benchname}.c over! "
            ;;
        *)
            lnlamp -t '{[1,4,8,16,32]}' ${benchname}.c
            echo "lnlamp -t '{[1,4,8,16,32]}' ${benchname}.c over! "
    esac
    echo ""

    # 返回测试脚本目录
    cd $workdir
done

# 返回测试脚本目录
cd $workdir
#  schedule + tile + mix
rm -rf build
rm -rf result-out
./taffo_collect-fe-stats.sh schedule_tile_mix



#  schedule + tile
# 准备
sed -n "s/_lnlamp.c/.c.ppcg.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/.c.ppcg.c/g" taffo_compiler.sh
rm -rf build
rm -rf result-out

./taffo_collect-fe-stats.sh   schedule_tile

# 复原
sed -n "s/.c.ppcg.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/.c.ppcg.c/_lnlamp.c/g" taffo_compiler.sh
# git restore taffo_compiler.sh



#  schedule + mix
# 准备
sed -n "s/_lnlamp.c/_lnlamp.c.no-tile.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/_lnlamp.c.no-tile.c/g" taffo_compiler.sh
rm -rf build
rm -rf result-out

./taffo_collect-fe-stats.sh schedule_mix

# 复原
sed -n "s/_lnlamp.c.no-tile.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c.no-tile.c/_lnlamp.c/g" taffo_compiler.sh



#  schedule
# 准备
sed -n "s/_lnlamp.c/.c.ppcg.no-tile.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/.c.ppcg.no-tile.c/g" taffo_compiler.sh
rm -rf build
rm -rf result-out

./taffo_collect-fe-stats.sh schedule

# 复原
sed -n "s/.c.ppcg.no-tile.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/.c.ppcg.no-tile.c/_lnlamp.c/g" taffo_compiler.sh



#  only mix
# 准备
sed -n "s/_lnlamp.c/_lnlamp.c.only-mix.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/_lnlamp.c.only-mix.c/g" taffo_compiler.sh
rm -rf build
rm -rf result-out

./taffo_collect-fe-stats.sh only-mix

# 复原
sed -n "s/_lnlamp.c.only-mix.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c.only-mix.c/_lnlamp.c/g" taffo_compiler.sh


echo "lnlamp vs taffo, over!"
# 返回测试脚本目录
cd $workdir