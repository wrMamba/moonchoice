# 参考、许可及数值验证

MoonChoice是原创MoonBit实现，不是对某个库的源码翻译。数学方法非原创；没有使用上游代码或测试数据冒充原创内容。

- [pymcdm](https://github.com/kotbaton/pymcdm)，MIT。审阅TOPSIS、VIKOR、PROMETHEE II数学行为；开发期用精确版本1.3.1作为独立计算器。测试矩阵由本项目确定性构造，非上游fixture。运行时不依赖Python或pymcdm。
- [MoonBit core](https://github.com/moonbitlang/core)，Apache-2.0，工具链运行时依赖（debug/math/json等），不把其代码复制计入项目规模。
- 相邻MoonBit项目仅作查重，许可和功能边界见duplicate-check；无其代码纳入发行包。

## 再生成对照

隔离Python环境安装 `pymcdm==1.3.1`（其numpy/scipy等依赖仅开发期），运行 `python scripts/generate_reference.py`，再运行 `moon fmt && moon test`。脚本构造24个无常量列的混合收益/成本矩阵，对照TOPSIS minmax、VIKOR v=0.5、PROMETHEE usual的分数；WPM用独立Python数学公式验证。提交固定fixture，CI无需安装Python科学计算栈。

逐值绝对误差阈值1e-10。测试覆盖非退化范围；常量列、并列、零权重、单行在MoonChoice边界测试中单独验证，不宣称pymcdm具有相同回退。测试不是跨所有输入的形式证明；无基准性能声明。

其余测试覆盖正仿射单位不变性、备选排列等变性、严格支配链、AHP一致性/失败、数值上限、不可变输入、排序防篡改、文档/情景预算、CSV引号/换行、JSON模式和请求错误。
