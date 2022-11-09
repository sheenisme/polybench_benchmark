#########################################################################
# File Name: one_click_start_test.sh
# Author:song guanghui(sheen song) 
# mail: sheensong@163.com
# Created Time: 2022年11月09日 星期三 20时20分57秒
# Description:  一键启动性能测试的脚本
#########################################################################
#!/bin/bash


# 删除历史结果
rm -f benchmark_result.log


perl header-gen.pl ../
perl makefile-gen.pl ../ -cfg
perl run-all.pl ../ > ../run.log 2>&1
# perl clean.pl ../