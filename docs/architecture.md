# 模型与实现边界

构造器验证并复制输入 → 权重归一化 → 明确模型/归一化 → 分数与轨迹 → 统一排序 → 解释/一致性/敏感性。无全局状态。

Minmax收益/成本分别为(x-min)/(max-min)、(max-x)/(max-min)。Vector为sign*x/sqrt(sum(x*x))，先按最大绝对值缩放。补偿求和降低混合符号误差，不消除有限精度。

TOPSIS理想/反理想点取加权收益定向数据的max/min，得分为反理想距离/两距离和。WPM在原始正数上计算log差，相对乘积仅展示。VIKOR以加权归一化损失的和S/最大R形成Q，越小越好；常量列及零跨度项为0，妥协集合与排序分开提供。

PROMETHEE使用原始单位方向差异，六种函数映射到[0,1]，再加权成对偏好和平均流量。单位变换后调用者必须同步缩放阈值。

客观赋权描述离散/相关结构，不保证表达人的偏好。AHP使用有界幂迭代，不收敛报错；固定RI经验表不是显著性检验，不自动施加CR阈值。

## 复杂度

矩阵<=8192值；SAW/TOPSIS/VIKOR/WPM为O(np)+O(n²)排序；PROMETHEE/Pareto为O(n²p)，最大2097152次指标比较。AHP n<=15、最多4096轮O(n²)迭代。多方法<=16，情景按显式工作预算限制。内存主要为矩阵、成对矩阵及显式情景结果。

## 协议

matrix/1的五必需键为schema、alternatives、criteria、directions、values。request/1按operation验证互斥weights/scenarios；algorithm按kind验证准确键集。键顺序无语义，未知schema拒绝，重复键沿用core最后值规则，见SECURITY.md。

CSV最多258记录、33字段，解码字段<=4096 UTF-16单元（合法标签仍<=128），编码字段额外扫描预算8194单元。无BOM自动消除、注释、缺失值或分隔符猜测。输出CRLF与JSON数字。

## 解释

report的additive_minmax_contributions始终为独立SAW诊断，不是TOPSIS/VIKOR分数分解。profiles的总体标准差不是估计误差。删指标后重新归一化，剩余全零记录skipped；PROMETHEE规格同步投影。情景频数不假设权重概率分布。

0.x API不承诺未来小版本兼容。客户端锁定精确版本并检查响应schema。
