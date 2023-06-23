#!/bin/bash
workdir=$(cd `dirname $0`; pwd)
# echo "当前的工作路径是:" $workdir
cd $workdir



cuda_timing_add(){
    file=$1

    # 插入开始计时的代码
    grep -n "cudaCheckReturn(cudaMemcpy(dev_"  $file | tail -1 > _____tmp_1
    line_no=`cat _____tmp_1 | awk  -F':' '{print $1}'`
    rm -f _____tmp_1
    #line_no=`expr $line_no + 1`;
    # echo $line_no
    sed -i "${line_no}a\    cudaEvent_t start, stop;\n    float esp_time_gpu;\n    cudaEventCreate(&start);\n    cudaEventCreate(&stop);\n    cudaEventRecord(start, 0); // start" $file

    # 插入结束计时的代码
    grep -n "cudaCheckKernel()"  $file | tail -1 > _____tmp_2
    line_no=`cat _____tmp_2 | awk  -F':' '{print $1}'`
    rm -f _____tmp_2
    line_no=`expr $line_no + 1`;
    # echo $line_no
    sed -i "${line_no}a\    cudaEventRecord(stop, 0); // stop\n    cudaEventSynchronize(stop);\n    cudaEventElapsedTime(&esp_time_gpu, start, stop);" $file

    # 插入打印计时的代码
    grep -n "cudaCheckReturn(cudaFree"  $file | tail -1 > _____tmp_3
    line_no=`cat _____tmp_3 | awk  -F':' '{print $1}'`
    rm -f _____tmp_3
    # line_no=`expr $line_no + 1`;
    # echo $line_no
    sed -i ''${line_no}'a\    printf("GPU kernel time: %f ms,\\tCPU time: ", esp_time_gpu);\n    cudaDeviceReset();' $file
}


all_benchs=$(cat ./utilities/benchmark_list_performance_cuda)
for bench in $all_benchs;
do
    benchdir=$(dirname $bench)
    kernel=$(basename $benchdir)
    # echo $kernel " " $benchname
    # 进入测试用例的目录进行测试
    cd $benchdir

    array=(0 1 5 10 20 30 40 50 60 70 80 90 95 99)
    for rate in ${array[@]}
    do
        make amp RATE=$rate > /dev/null 2>&1; 
        ppcg ${kernel}-amp_${rate}.c;
        cuda_timing_add ${kernel}-amp_${rate}_host.cu;
        nvcc ${kernel}-amp_${rate}_host.cu ${kernel}-amp_${rate}_kernel.cu /home/sheen/lnlamp/polybench_benchmark/utilities/polybench.cu -DPOLYBENCH_TIME -DPOLYBENCH_STACK_ARRAYS -O3 -o cuda_amp_${rate}.out 2> /dev/null;

        echo "${kernel},${rate}:"
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
        ./cuda_amp_${rate}.out
    done


    make double;
    ppcg ${kernel}.c;
    cuda_timing_add ${kernel}_host.cu;
    nvcc ${kernel}_host.cu ${kernel}_kernel.cu /home/sheen/lnlamp/polybench_benchmark/utilities/polybench.cu -DPOLYBENCH_TIME -DPOLYBENCH_STACK_ARRAYS -O3 -o cuda_ppcg.out 2> /dev/null;

    echo "${kernel},PPCG:"
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out
    ./cuda_ppcg.out

    # 返回测试脚本目录
    cd $workdir
done

