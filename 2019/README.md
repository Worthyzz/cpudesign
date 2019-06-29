# 2019年课程安排

## 实验任务

必做：
1. 完成一个执行RISC-V的基本整数指令集RV32I的CPU设计（单周期实现）
2. 完成一个模拟RISC-V的基本整数指令集RV32I的模拟器设计

选做：
1. 完成一个执行RISC-V的基本整数指令集RV32I的CPU设计（流水线实现）
2. 完成一个模拟RISC-V的基本整数指令集RV32I的汇编器设计

## 实验要求

硬件设计采用VHDL或Verilog语言，软件设计采用C/C++或SystemC语言，其它语言例如MyHDL也可选。

实验报告采用markdown语言，或者直接上传PDF文档

实验最终提交所有代码和文档

## 实验组织

分组完成实验任务，但每个人的任务要不一样。例如2个人的组，那么1个人完成硬件设计，
1个人完成软件设计。4个人的组，那么硬件设计2个人，分别用VHDL和Verilog实现CPU，
另外2个人分别用C/C++和SystemC完成模拟器设计。6个人的组，就必须在选做任务中安排
人手了。

每个组选择一位同学做组长，负责注册github帐号，并将帐号通过课程QQ群告知教师。随后，
组长负责将本组代码和报告上传到[课程的github网站](https://github.com/luojike/cpudesign)的2019目录下。
请注意创建自己组的目录，以免与其它组混淆。

## 考核标准

考核分数综合出勤（10%）、模拟器代码（20%）、CPU代码（30%）、实验报告（40%）。

出勤分数根据出勤率，代码分数根据是否能编译运行，实现所需功能以及代码排版风格评分，实验报告根据
格式是否规范、条理是否清晰、文字是否通顺、数据记录和分析是否详尽评分。

## 参考资料

1. RISC-V官方指令集手册. [https://riscv.org/specifications/](https://riscv.org/specifications/).
2. RISC-V资源列表. [https://cnrv.io/resource](https://cnrv.io/resource).
3. 武汉聚芯和北京九天的蜂鸟E200系列处理器GitHub网页. [https://github.com/SI-RISCV/e200_opensource](https://github.com/SI-RISCV/e200_opensource).
