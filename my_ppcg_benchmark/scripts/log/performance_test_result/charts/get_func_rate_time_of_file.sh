#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
# cd $workdir

if test $1 != ""
then
    # 初始化一些参数
    line_index=0
    div=5

    while read line
    do
        line_index=`expr $line_index + 1`
        # echo "行索引是:"$line_index
        remainder=`expr $line_index % $div`
        if [ $remainder -eq 0 ]
        then
            # echo "行索引是:"$line_index
            time=`echo ${line} | sed -ne 's/[^0-9]*\([0-9]*\.[0-9]*\)[^0-9]*/\1/p'`
            echo $time
        elif [ $remainder -eq 1 ]
        then
            # 如果是第六行，即是纯float
			if [ $line_index -eq 1 ]
			then
                # 去掉line中的'ppcg'左边的字符，'float'右边的字符
            	line=${line##*ppcg}
                line=${line%% float *}
                # rate=`echo ${line} | tr -cd "[0-9]" `
                echo -e $line "-1 \c"
            else
                # echo "行索引是:"$line_index
                # 去掉line中的'AMP'左边的字符，'performance'右边的字符
                line=${line##*AMP}
                line=${line%%performance*}
                # rate=`echo ${line} | tr -cd "[0-9]" `
                echo -e $line "\c"
            fi
        fi    
    done < $1
else
    echo "No such file or the address of it is error (the workdir is $workdir)! please check."
fi