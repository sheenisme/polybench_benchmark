#!/bin/bash

logFile="nohup.out"  #这个是你的日志文件路径，需要你替换成实际的文件名或路径
outputFile="result_predict.csv"

#使用grep的-P参数启用Perl兼容的正则表达式，并使用-o参数只输出匹配的部分
#使用的正则表达式根据你提供的字符串格式来编写
grep -Po "pi\(r\) = -?\d+\.\d+ \* r\^2 \+ -?\d+\.\d+ \* r \+ -?\d+\.\d+" $logFile > temp.txt

sed 's/r/x/g' temp.txt > $outputFile

rm temp.txt