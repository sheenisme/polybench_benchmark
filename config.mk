CC=gcc
CPP=g++
CFLAGS=-O3 
CC_OPENMP_FLAGS=
POLYBENCH_FLAGS=-DPOLYBENCH_TIME -DPOLYBENCH_DUMP_ARRAYS -DPOLYBENCH_STACK_ARRAYS

PPCG=/home/guanghui/Workspace/lnlamp/install/bin/ppcg
PPCG_TARGET=--target c 
PPCG_TILE_FLAGS=
PPCG_OPENMP_FLAGS=

CGEIST=/home/guanghui/Workspace/MixPrecHLS/polygeist/build/bin/cgeist
CGEIST_FLAGS=-O0 -g -S -memref-fullrank
CGEIST_LIB=
CGEIST_INC=-I /usr/lib/gcc/x86_64-linux-gnu/12/include/

OPTIMIZER=/home/guanghui/Workspace/MixPrecHLS/build/bin/scalehls-opt
OPTIMIZER_COMMON_FLAGS=--scalehls-func-preprocess="top-func=kernel_${KERNEL}"
OPTIMIZER_DATAFLOW_FLAGS=
OPTIMIZER_PIPELINE_FLAGS=
OPTIMIZER_OTHER_FLAGS=--canonicalize --cse

TRANSLATE=/home/guanghui/Workspace/MixPrecHLS/build/bin/scalehls-translate
TRANSLATE_FLAGS=-scalehls-emit-hlscpp

VITIS_HLS=/shared/Xilinx/Vitis_HLS/2022.2/bin/vitis_hls
