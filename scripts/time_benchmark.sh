#!/bin/sh
## time_benchmark.sh for  in /Users/pouchet
##
## Made by Louis-Noel Pouchet
## Contact: <pouchet@cse.ohio-state.edu>
##
## Started on  Sat Oct 29 00:03:48 2011 Louis-Noel Pouchet
## Last update Fri Apr 22 15:39:13 2016 Louis-Noel Pouchet
##

## Maximal variance accepted between the 3 median runs for performance results.
## Here 5%
VARIANCE_ACCEPTED=10;

if [ $# -ne 1 ]; then
    echo "Usage: ./time_benchmarh.sh <binary_name>";
    echo "Example: ./time_benchmarh.sh \"./a.out\"";
    echo "Note: the file must be a Polybench program compiled with -DPOLYBENCH_TIME";
    exit 1;
fi;


compute_mean_exec_time()
{
    file="$1";
    benchcomputed="$2";
    # 去掉$2中的'/'左边的字符，'.'右边的字符
    str=${2##*/}
    str=${str%%.*}

    cat "$file" | grep "[0-9]\+" | sort -n | head -n 12 | tail -n 10 > avg_${str}.out;
    expr="(0";
    while read n; do
	expr="$expr+$n";
    done < avg_${str}.out;
    time=`echo "scale=10;$expr)/10" | bc`;
    tmp=`echo "$time" | cut -d '.' -f 1`;
    if [ -z "$tmp" ]; then
	time="0$time";
    fi;
    # 拿到8份中间的数据结果
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
	echo "[ERROR] Program output does not match expected single-line with time.";
	echo "[ERROR] The program must be a PolyBench, compiled with -DPOLYBENCH_TIME";
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
    echo "[WARNING] Variance is above thresold, unsafe performance measurement, => max deviation=$variance%, tolerance=$VARIANCE_ACCEPTED%";
	# echo "[WARNING] Variance is above thresold, unsafe performance measurement";
	# echo "        => max deviation=$variance%, tolerance=$VARIANCE_ACCEPTED%";
	WARNING_VARIANCE="$WARNING_VARIANCE\n$benchcomputed: max deviation=$variance%, tolerance=$VARIANCE_ACCEPTED%";
    else
	echo "[INFO] Maximal deviation from arithmetic mean of 10 average runs: $variance%";
    fi;
    PROCESSED_TIME="$time";
    rm -f avg_${str}.out;
}

echo "[INFO] Running 14 times $1..."
echo "[INFO] Maximal variance authorized on 10 average runs: $VARIANCE_ACCEPTED%...";

# 去掉$1中的'/'左边的字符，'.'右边的字符
str=${1##*/}
str=${str%%.*}

# 跑14次,去掉2个最低和最高值,然后求平均值
$1 > ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;
$1 >> ____tempfile_${str}.data.polybench;

compute_mean_exec_time "____tempfile_${str}.data.polybench" "$1";
echo "[INFO] Normalized time: $PROCESSED_TIME";
rm -f ____tempfile_${str}.data.polybench;
