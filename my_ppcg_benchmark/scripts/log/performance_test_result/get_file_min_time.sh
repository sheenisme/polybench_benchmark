#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir

cd $workdir



if test $1 != ""
then
    # 初始化一些参数
    line_index=0
    div=5
    min_time=99999999999999999.0

    while read line
    do
        line_index=`expr $line_index + 1`
        # echo "行索引是:"$line_index
        remainder=`expr $line_index % $div`
        if [ $remainder -eq 0 ]
        then
            # echo "行索引是:"$line_index
            time=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
            # echo "time是:" $time " min_time是:" $min_time
            if [ `echo "$time < $min_time"|bc`  -eq 1 ]
            then
                min_time=$time
                echo  "updated the min time is: " $min_time
            fi
        fi    
    done < $1
    echo "the min time is:" $min_time ", in all of" $line_index "lines of" $1 "file." >> min_perforamce.log
else
    echo "No such file or the address of it is error （the workdir is $workdir）! please check."
fi