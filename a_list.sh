#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir



# 先调用lnlamp生成所有需要的代码
cd utilities;
perl run-all.pl ../ 4 > ../big_tile-128_lnlamp-run-0225.log 2>&1        
cd ..;



#  schedule + tile + mix
cd $workdir
mkdir schedule_tile_mix
./taffo_collect-fe-stats.sh schedule_tile_mix       



#  schedule + tile
# 准备
sed -n "s/_lnlamp.c/.c.ppcg.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/.c.ppcg.c/g" taffo_compiler.sh

mkdir schedule_tile
./taffo_collect-fe-stats.sh schedule_tile       

# 复原
sed -n "s/.c.ppcg.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/.c.ppcg.c/_lnlamp.c/g" taffo_compiler.sh
# git restore taffo_compiler.sh



#  schedule + mix
# 准备
sed -n "s/_lnlamp.c/_lnlamp.c.no-tile.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/_lnlamp.c.no-tile.c/g" taffo_compiler.sh

mkdir schedule_mix
./taffo_collect-fe-stats.sh schedule_mix     

# 复原
sed -n "s/_lnlamp.c.no-tile.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c.no-tile.c/_lnlamp.c/g" taffo_compiler.sh
# git restore taffo_compiler.sh




#  schedule
# 准备
sed -n "s/_lnlamp.c/.c.ppcg.no-tile.c/p" taffo_compiler.sh
sed -i "s/_lnlamp.c/.c.ppcg.no-tile.c/g" taffo_compiler.sh

mkdir schedule
./taffo_collect-fe-stats.sh schedule  

# 复原
sed -n "s/.c.ppcg.no-tile.c/_lnlamp.c/p" taffo_compiler.sh
sed -i "s/.c.ppcg.no-tile.c/_lnlamp.c/g" taffo_compiler.sh
# git restore taffo_compiler.sh