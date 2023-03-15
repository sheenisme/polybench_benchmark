#!/bin/bash
## 可靠的（用4d检验法去除可疑结果）性能测试的脚本,在run-all.pl中调用该脚本对测试用例进行逐个测试.
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir



if [ $# -ne 2 ]; then
    echo "Usage:   ./Reliable_perf_test.sh <target_dir> <kernel>";
    echo "Example: ./Reliable_perf_test.sh \"..//stencils/3d27pt\" 3d27pt";
    echo "Note: the file must be a Polybench program compiled with -DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS";
    exit 1;
fi;
target_dir=$1
kernel=$2
# 编译4D检验法程序,如果编译可以通过,则用4d检验法求均值(可以自动去掉偏差),否则,直接退出.
gcc -O3 $workdir/4d_check.c -o 4D_Check.exe > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "用4d检验法求均值(可以自动去掉偏差)的4d_check.c文件编译失败,请检查程序!!!"
    exit 1;
fi;



# 设置一些变量,方便后面调用.
## Maximal variance accepted between the 3 median runs for performance results.
## Here 10%
VARIANCE_ACCEPTED=5;
# init variance of test is 100 
VARIANCE_TEST=100;
# 设置测试性能时的频次
frequency=10
readonly frequency
result_file="$workdir/benchmark_result_perf-Reliable.log"
# echo $result_file
mean_log_file="$workdir/benchmark_mean_result.log"
# echo $mean_log_file
# 设置要测试的比例
my_rate_list="$workdir/my_rate_list"
# 设置用户堆栈空间为8G
ulimit -s 8388608
# echo "用户区栈空间大小是:"
# ulimit -a | grep "stack size"
# 设置绑定核心
TASKSET=""
which taskset > /dev/null
if [ $? -eq 0 ]; then
    TASKSET="taskset -c 1 "
fi
# echo "${TASKSET}"



# 计算执行时间的方差
compute_mean_exec_time()
{
    echo "[INFO] Running $frequency times $2 ..." >> ${mean_log_file};
    echo "[INFO] Maximal variance authorized on $frequency average runs: $VARIANCE_ACCEPTED%..." >> ${mean_log_file};
    
    file="$1";
    benchcomputed="$2";
    CHECK_TIME="$3";
    # 去掉$2中的'/'左边的字符，'.'右边的字符
    str=${2##*/};
    str=${str%%.*};

    cat "$file" > avg_${str}.out;
    expr="(0";
    while read n; do
	expr="$expr+$n";
    done < avg_${str}.out;
    time=`echo "scale=10;$expr)/10" | bc`;
    tmp=`echo "$time" | cut -d '.' -f 1`;
    if [ -z "$tmp" ]; then
	time="0$time";
    fi;
    # 拿到10份中间的数据结果
    val1=`cat avg_${str}.out | head -n 1`;
    val2=`cat avg_${str}.out | head -n 2 | tail -n 1`;
    val3=`cat avg_${str}.out | head -n 3 | tail -n 1`;
    val4=`cat avg_${str}.out | head -n 4 | tail -n 1`;
    val5=`cat avg_${str}.out | head -n 5 | tail -n 1`;
    val6=`cat avg_${str}.out | head -n 6 | tail -n 1`;
    val7=`cat avg_${str}.out | head -n 7 | tail -n 1`;
    val8=`cat avg_${str}.out | head -n 8 | tail -n 1`;
    val9=`cat avg_${str}.out | head -n 9 | tail -n 1`;
    val10=`cat avg_${str}.out | head -n 10 | tail -n 1`;
    
    # 判断数据是否是正的
    val11=`echo "a=$val1 - $time;if(0>a)a*=-1;a" | bc 2>&1`;
    test_err=`echo "$val11" | grep error`;
    if ! [ -z "$test_err" ]; then
	echo "[ERROR] Program output does not match expected single-line with time."    >> ${mean_log_file};
	echo "[ERROR] The program must be a PolyBench, compiled with -DPOLYBENCH_TIME"  >> ${mean_log_file};
	exit 1;
    fi;
    # 计算每份数据和平均值的差值的绝对值
    val12=`echo "a=$val2 - $time;if(0>a)a*=-1;a" | bc`;
    val13=`echo "a=$val3 - $time;if(0>a)a*=-1;a" | bc`;
    val14=`echo "a=$val4 - $time;if(0>a)a*=-1;a" | bc`;
    val15=`echo "a=$val5 - $time;if(0>a)a*=-1;a" | bc`;
    val16=`echo "a=$val6 - $time;if(0>a)a*=-1;a" | bc`;
    val17=`echo "a=$val7 - $time;if(0>a)a*=-1;a" | bc`;
    val18=`echo "a=$val8 - $time;if(0>a)a*=-1;a" | bc`;
    val19=`echo "a=$val9 - $time;if(0>a)a*=-1;a" | bc`;
    val20=`echo "a=$val10 - $time;if(0>a)a*=-1;a" | bc`;

    # 计算其中最大的偏差
    myvar=`echo "$val11 $val12 $val13" | awk '{ if ($1 > $2) { if ($1 > $3) print $1; else print $3; } else { if ($2 > $3) print $2; else print $3; } }'`;
    myvar=`echo "$myvar $val14 $val15" | awk '{ if ($1 > $2) { if ($1 > $3) print $1; else print $3; } else { if ($2 > $3) print $2; else print $3; } }'`;
    myvar=`echo "$myvar $val16 $val17" | awk '{ if ($1 > $2) { if ($1 > $3) print $1; else print $3; } else { if ($2 > $3) print $2; else print $3; } }'`;
    myvar=`echo "$myvar $val18 $val19" | awk '{ if ($1 > $2) { if ($1 > $3) print $1; else print $3; } else { if ($2 > $3) print $2; else print $3; } }'`;
    myvar=`echo "$myvar $val20" | awk '{ if ($1 > $2) { print $1; } else { print $2; } }'`;

    variance=`echo "scale=8;($myvar/$time)*100" | bc`;
    tmp=`echo "$variance" | cut -d '.' -f 1`;
    if [ -z "$tmp" ]; then
	variance="0$variance";
    fi;
    compvar=`echo "$variance $VARIANCE_ACCEPTED" | awk '{ if ($1 < $2) print "ok"; else print "error"; }'`;
    if [ "$compvar" = "error" ]; then
    echo "[WARNING] Variance is above thresold, unsafe performance measurement, => max deviation=$variance%, tolerance=$VARIANCE_ACCEPTED%"  >> ${mean_log_file};
	# echo "[WARNING] Variance is above thresold, unsafe performance measurement";
	# echo "        => max deviation=$variance%, tolerance=$VARIANCE_ACCEPTED%";
	WARNING_VARIANCE="$WARNING_VARIANCE\n$benchcomputed: max deviation=$variance%, tolerance=$VARIANCE_ACCEPTED%";
    else
	echo "[INFO] Maximal deviation from arithmetic mean of 10 average runs: $variance%"  >> ${mean_log_file};
    fi;
    PROCESSED_TIME="$time";
    VARIANCE_TEST="$variance";
    rm -f avg_${str}.out;
    
    echo "[INFO] Normalized time: $PROCESSED_TIME, 4D Check time: $CHECK_TIME" >> ${mean_log_file};
}



# 进入目录,先进行必要的清理
cd $target_dir;
# workdir_2=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir_2
# cd $workdir_2
# make clean;



# 测试低精度的性能和误差结果
make float;
# initial variance is 100 
VARIANCE_TEST=100;
while [ `echo "$VARIANCE_TEST > $VARIANCE_ACCEPTED" | bc` -eq 1 ] 
do
    $TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null  >  ____tempfile_time_all.float.txt || return $?
    $TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null  >> ____tempfile_time_all.float.txt || return $?
    $TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null  >> ____tempfile_time_all.float.txt || return $?
    $TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null  >> ____tempfile_time_all.float.txt || return $?
    for ((i=0; i<$frequency; i++))
    do
        $TASKSET ./${kernel}-ppcg-float.exe 2> /dev/null >> ____tempfile_time_all.float.txt || return $?
    done
    # 去掉两个最小的和两个最大的，对剩下的数据，用4d检验法求平均值
    temp_var=`expr $frequency + 2`;
    cat ____tempfile_time_all.float.txt | grep "[0-9]\+" | sort -n | head -n ${temp_var} | tail -n ${frequency} > ____tempfile_time.float.txt;
    float_time=`$workdir/4D_Check.exe  ____tempfile_time.float.txt`
    # 计算方差
    compute_mean_exec_time ____tempfile_time.float.txt ${kernel}-ppcg-float.exe " $float_time";
    # 删除临时文件
    rm ____tempfile_time_all.float.txt ____tempfile_time.float.txt
    unset temp_var
done
# 输出最终结果
echo ${kernel}	float	-1	${float_time} >> ${result_file};



# 测试混合精度的性能
cat $my_rate_list | while read rate
do  
    make amp RATE=${rate};
    # initial variance is 100 
    VARIANCE_TEST=100;
    while [ `echo "$VARIANCE_TEST > $VARIANCE_ACCEPTED" | bc` -eq 1 ] 
    do
        $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null  >  ____tempfile_time_all.amp.${rate}.txt || return $?
        $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null  >> ____tempfile_time_all.amp.${rate}.txt || return $?
        $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null  >> ____tempfile_time_all.amp.${rate}.txt || return $?
        $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null  >> ____tempfile_time_all.amp.${rate}.txt || return $?
        for ((i=0; i<$frequency; i++))
        do
            $TASKSET ./${kernel}-amp_${rate}.exe 2> /dev/null >> ____tempfile_time_all.amp.${rate}.txt || return $?
        done
        # 去掉两个最小的和两个最大的，对剩下的数据，用4d检验法求平均值
        temp_var=`expr $frequency + 2`;
        cat ____tempfile_time_all.amp.${rate}.txt | grep "[0-9]\+" | sort -n | head -n ${temp_var} | tail -n ${frequency} > ____tempfile_time.amp.${rate}.txt;
        amp_time=`$workdir/4D_Check.exe  ____tempfile_time.amp.${rate}.txt`
        # 计算方差
        compute_mean_exec_time ____tempfile_time.amp.${rate}.txt ${kernel}-amp_${rate}.exe " $amp_time";
        # 删除临时文件
        rm  ____tempfile_time_all.amp.${rate}.txt ____tempfile_time.amp.${rate}.txt
        unset temp_var
    done
    # 输出最终结果
    echo ${kernel}	amp	${rate}	${amp_time} >> ${result_file};
    unset amp_time
done



# 测试高精度的性能和baseline的结果
make double;
# initial variance is 100 
VARIANCE_TEST=100;
while [ `echo "$VARIANCE_TEST > $VARIANCE_ACCEPTED" | bc` -eq 1 ] 
do
    $TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null  >  ____tempfile_time_all.double.txt || return $?
    $TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null  >> ____tempfile_time_all.double.txt || return $?
    $TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null  >> ____tempfile_time_all.double.txt || return $?
    $TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null  >> ____tempfile_time_all.double.txt || return $?
    for ((i=0; i<$frequency; i++))
    do
        $TASKSET ./${kernel}-ppcg-double.exe 2> /dev/null >> ____tempfile_time_all.double.txt || return $?
    done
    # 去掉两个最小的和两个最大的，对剩下的数据，用4d检验法求平均值
    temp_var=`expr $frequency + 2`;
    cat ____tempfile_time_all.double.txt | grep "[0-9]\+" | sort -n | head -n ${temp_var} | tail -n ${frequency} > ____tempfile_time.double.txt;
    double_time=`$workdir/4D_Check.exe  ____tempfile_time.double.txt`
    # 计算方差
    compute_mean_exec_time ____tempfile_time.double.txt ${kernel}-ppcg-double.exe " $double_time";
    # 删除临时文件
    rm ____tempfile_time_all.double.txt ____tempfile_time.double.txt
    unset temp_var
done
# 输出最终结果
echo ${kernel}	double	100 ${double_time} >> ${result_file};



# 最后删除4D_Check.exe
rm $workdir/4D_Check.exe
