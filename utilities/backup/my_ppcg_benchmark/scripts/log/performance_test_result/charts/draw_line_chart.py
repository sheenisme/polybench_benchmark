# -*- coding: utf-8 -*-#
# File_Name:     draw_line_chart.py
# Description:   分析结果，并画出来折线图片进行展示
# Author:        sheen song(宋广辉)
# Date:          2022/4/28
# import re
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


# 获取txt文件中的原始数据到'ndarray'
def reader_txt(file):
    with open(file) as f:
        data_txt = np.loadtxt(f, dtype='str', delimiter=" ", skiprows=0)  # 读取数据
        # print(data_txt, type(data_txt), len(data_txt))
    return data_txt


# 写'ndarray'数据到txt文件中
def writer_txt(file, nd_name):
    np.savetxt(file, nd_name, delimiter="\t", fmt="%s")


# AMP表现结果
def amp_show(data, error_data, figure_name):
    # 设置图片画布大小,(10,10)代表1000 * 1000 像素
    plt.figure(figsize=(80, 60))
    # 设置子图间距
    plt.subplots_adjust(left=None, bottom=None, right=None, top=None, wspace=None, hspace=None)
    # 初始化子图列表
    ax = []
    
    # 测试用例的名字
    func_name = ['3d27pt', '3d7pt', 'fdtd-1d', 'fdtd-2d', 'heat-1d', 'heat-2d', 'heat-3d', 'jacobi-1d', 'jacobi-2d', 'seidel-2d']
    for func_index in range(0, 10):
        # 生成5行2列，这是第 func_index + 1个图。用法：plt.subplot('行','列','编号')
        ax.append(plt.subplot(5, 2, func_index + 1))
        # 存放实际测试的数据
        x_data = []
        time_data = []
        max_error_data = []
        # 存放模型相关的时间
        double_time = 0.0
        float_time = 0.0
        zero_rate_time = 0.0
        model_data = []
        y_data = []
        # 添加性能实际测试的数据
        for rate in range(0, 102):
            # print(func_index,rate,str(data[func_index * 102 + rate][0]),int(data[func_index * 102 + rate][1]),float(data[func_index * 102 + rate][2]))
            # 设置断言，确保测试用例对应正确
            assert str(data[func_index * 102 + rate][0]) == func_name[func_index]
            # 设置断言，确保rate对应正确
            assert int(data[func_index * 102 + rate][1]) == rate - 1
            # 获取性能模型中需要的数据
            if rate == 0:
                float_time = float(data[func_index * 102 + rate][2])
            elif rate == 1:
                zero_rate_time = float(data[func_index * 102 + rate][2])
            elif rate == 101:
                double_time = float(data[func_index * 102 + rate][2])
            # 添加性能测试数据
            x_data.append(int(data[func_index * 102 + rate][1]))
            time_data.append(float(data[func_index * 102 + rate][2]))
        # 添加误差的测试数据
        for rate in range(0, 101):
            # print(func_index,error_data,str(error_data[func_index * 102 + rate][0]),int(error_data[func_index * 102 + rate][1]),float(error_data[func_index * 102 + rate][2]))
            # 设置断言，确保测试用例对应正确
            assert str(error_data[func_index * 102 + rate][0]) == func_name[func_index]
            # 设置断言，确保rate对应正确
            assert int(error_data[func_index * 102 + rate][1]) == rate - 1
            if(rate != 1):
                # 添加误差的测试数据
                max_error_data.append(float(error_data[func_index * 102 + rate][2]))
        # 计算性能模型预估的时间
        for model_rate in range(0,101):
            y_data.append(model_rate)
            model_data.append(((double_time-float_time)/100 * model_rate) + zero_rate_time)
		
        # 绘制曲线
        ax[func_index].plot(x_data, time_data, color='green', linestyle='-',label=func_name[func_index] + " time")
        ax[func_index].plot(y_data, model_data, color='red', linestyle='-',label=func_name[func_index] + " model predicted time")
        # 设置横坐标
        ax[func_index].set_xticks(x_data)
        # 给每一个测试用例的子图，设置坐标轴的名字和标题
        # ax[func_index].set_title('Result analysis of ' + func_name[func_index])
        ax[func_index].set_xlabel('Rate')
        ax[func_index].set_ylabel('Time taken (s)')
        # 显示图例
        ax[func_index].legend(loc=2)
        # 获取第二个坐标轴(误差的坐标轴)
        ax_2=ax[func_index].twinx()
        ax_2.plot(x_data[1:101], max_error_data, color='blue', linestyle='-',label=func_name[func_index] + " max error")
        ax_2.set_ylabel('Max error')
        ax_2.legend(loc=4)
    # 保存图片
    plt.savefig(fname=figure_name)
    # 显示图形
    # plt.show()
    print("Draw picture over!!!  \n")


# 主函数
if __name__ == '__main__':
    # 设置输入和输出数据集的文件名和结果分析的图片名
    in_file_name = 'performance_data_of_chart.txt'
    error_file_name = 'error_data_of_chart.txt'
    out_file_name = 'result_of_data_in_chart.csv'

    # 获取输入文件中的'ndarray'(多维数组)数据，并转换成'list'
    # io_txt_data = reader_txt(in_file_name).astype('str').tolist()
    io_txt_data = reader_txt(in_file_name).astype('str').tolist()
    # print("in_txt_data is :\n", io_txt_data, type(io_txt_data), len(io_txt_data))
    error_txt_data = reader_txt(error_file_name).astype('str').tolist()
    error_txt_data.sort(key=lambda i:(i[0],int(i[1])))
    # print("error_file_name is :\n", error_txt_data, type(error_txt_data), len(error_txt_data))

    # AMP表现结果
    amp_show(io_txt_data, error_txt_data, "performance_result.png")

    # 将数据写入到输出文件中
    writer_txt("performance_"+out_file_name, io_txt_data)
    writer_txt("error_"+out_file_name, error_txt_data)
    #   print("out_txt_data is : \n", io_txt_data, type(io_txt_data), len(io_txt_data))
