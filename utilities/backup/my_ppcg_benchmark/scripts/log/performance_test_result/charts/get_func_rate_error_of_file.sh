#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir

# 去掉line中的'check/'左边的字符，'_check'右边的字符
func_name=$1
func_name=${func_name##*check/}	
func_name=${func_name%%_check*}
# echo "func_name is:" $func_name

if [ "$func_name" != "fdtd-2d" ] && [ $1 != "" ]
then
    # echo "进入非fdtd-2d分支."
    # 初始化一些参数
    line_index=0
    div=2
    error=0.0

    while read line
    do
        line_index=`expr $line_index + 1`
        # echo "行索引是:"$line_index
        remainder=`expr $line_index % $div`
        # 如果是前两百行
        if [ $line_index -le 200 ]
        then
            if [ $remainder -eq 1 ]
            then
                # echo "行索引是:"$line_index
                # 去掉line中的'Max diff'左边的字符，','右边的字符
                line=${line##*Max diff}
                # line=${line%%,*}
                error=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
                # echo $error
            elif [ $remainder -eq 0 ]
            then
                # echo "行索引是:"$line_index
                # 去掉line中的'of '左边的字符，'performance'右边的字符
                line=${line##*of }
                line=${line%% 完成*}
                echo $line $error
            fi 
        # 如果是最后的三行  
        elif [ $line_index -eq 201 ]
        then
            line=${line##*Max diff}
            error=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
            echo $func_name "100" $error
        elif [ $line_index -eq 202 ]
        then
            line=${line##*Max diff}
            error=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
            echo $func_name "-1" $error
        else
            echo -e "\c"
        fi 
    done < $1
# 如果是fdtd-2d
elif [ "$func_name" = "fdtd-2d" ]
then
    # echo "进入fdtd-2d分支."
    # 删除error更新的log日志文件
    rm -f fdtd-2d_max_error_updated.log
    # 初始化一些参数
    line_index=0
    new_div=4
    error=0.0
    max_error=-1.0

    while read line
    do
        line_index=`expr $line_index + 1`
        # echo "0. 行索引是:" $line_index
        remainder=`expr $line_index % $new_div`
        # 如果是前400行
        if [ $line_index -le 400 ]
        then
            if [ $remainder -gt 0 ]
            then
                # echo "1. 行索引是:   "$line_index
                # 去掉line中的'Max diff'左边的字符，','右边的字符
                line=${line##*Max diff}
                # line=${line%%,*}
                error=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
                # echo $error
                if [ `echo "$error > $max_error"|bc` -eq 1 ]
                then
                    max_error=$error
                    echo  "updated the max error is: " $max_error >> fdtd-2d_max_error_updated.log
                fi
            elif [ $remainder -eq 0 ]
            then
                # echo "2. 行索引是:"$line_index
                # 去掉line中的'of '左边的字符，'performance'右边的字符
                line=${line##*of }
                line=${line%% 完成*}
                echo $line $max_error
                max_error=-1.0
            fi 
        # 如果是最后的6行  
        elif [ $line_index -le 403 ]
        then
            line=${line##*Max diff}
            error=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
            if [ `echo "$error > $max_error"|bc` -eq 1 ]
            then
                max_error=$error
                echo  "updated the max error is: " $max_error >> fdtd-2d_max_error_updated.log
            fi
            # 如果是第403行
            if [ $line_index -eq 403 ]
            then
                echo $func_name "100" $max_error
                max_error=-1.0
            fi
        elif [ $line_index -le 406 ]
        then
            line=${line##*Max diff}
            error=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
            if [ `echo "$error > $max_error"|bc` -eq 1 ]
            then
                max_error=$error
                echo  "updated the max error is: " $max_error >> fdtd-2d_max_error_updated.log
            fi
            # 如果是第406行
            if [ $line_index -eq 406 ]
            then
                echo $func_name "-1" $max_error
                max_error=-1.0
            fi
        else
            echo -e "\c"
        fi 
    done < $1
else
    echo "No such file or the address of it is error (the workdir is $workdir)! please check."
fi