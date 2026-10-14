# MoonChoice

有界、可解释的 MoonBit 多准则决策分析（MCDA）库。输入已观测的有限备选项、收益/成本指标及权重，输出排序、逐指标证据和偏好敏感性；不替代人的决策。

模块：`wrMamba/moonchoice@0.1.0` · MIT · 无第三方运行时依赖（仅 MoonBit core）。

## 三类下游工作流

- **采购与工程评审**：读取混合量纲的 CSV，比较吞吐量、延迟、成本，得到 SAW/TOPSIS 排序及贡献明细，而不是一个不透明总分。
- **部署配置系统**：给定候选测量，用原始单位的 PROMETHEE 阈值形成成对偏好，检查净流量与 Pareto 层。
- **数据分析工作流**：通过显式权重网格重算，查看首位次数、秩频数、跨方法一致性、删项/删指标后的反转；通过版本化 JSON 嵌入其他应用。

## 安装

安装官方 MoonBit 工具链后，在自己的模块目录运行：

```sh
moon add wrMamba/moonchoice@0.1.0
```

在 `moon.pkg` 中添加导入：

```moonbit
import {
  "wrMamba/moonchoice" @choice,
}
```

```moonbit
fn main raise {
  let m = @choice.decision_matrix(
    ["A", "B", "C"], ["quality", "cost"],
    [@choice.Benefit, @choice.Cost],
    [[7.0, 8.0], [9.0, 10.0], [6.0, 5.0]],
  )
  let r = @choice.saw(m, [0.5, 0.5])
  assert_eq(r.ranking.winners(), ["B", "C"])
  println(@choice.ranking_json(r.ranking).stringify())
}
```

可执行包还需 `pkgtype(kind: "executable")`。完整独立导入例子见 `examples/`。

## API 导览

| 文件 | 已实现内容 |
| --- | --- |
| matrix, normalization | 防御性复制、收益/成本、minmax/向量归一化、尺度安全权重 |
| saw, topsis, wpm | 加权和贡献、理想解距离轨迹、正数对数加权乘积 |
| vikor | S/R/Q、可接受优势/稳定性、妥协集合 |
| preference, promethee | 六种偏好函数、成对矩阵、正负净流量 |
| objective_weights, ahp | 熵/离差/CRITIC、AHP 特征向量、残差/一致性/最坏三元组 |
| pareto, agreement | 精确支配层与见证、带并列的 Spearman/Kendall tau-b |
| scenarios, explain, transform | 有限网格、解析 SAW 交点、成对解释、单位变换、删项反转 |
| diagnostics | 指标统计、删指标敏感性、含警告和独立 SAW 贡献的报告 |
| json_codec, csv_codec, service | 有界 JSON/CSV、版本模式、无 I/O 的 JSON 请求分派 |

上述实现均为 `.mbt`。完整签名见 `pkg.generated.mbti`。失败使用 `ChoiceError::{Invalid, Budget, Numerical}`，不填补缺失数据。

## 三个可运行例子

```sh
moon run examples/procurement --target wasm-gc --deny-warn
moon run examples/deployment --target wasm-gc --deny-warn
moon run examples/scenarios --target wasm-gc --deny-warn
```

每个例子真实导入、计算和断言，再输出 JSON；不是只打印文案。可换为 `wasm`、`js`，或在有 C 编译器的环境换成 `native`。

## 格式与请求接口

CSV 第一行固定 `alternative,<指标名...>`，第二行固定 `direction,<benefit|cost...>`，后续为名称与数值。支持逗号、双引号转义、LF/CRLF 和带换行字段；不猜分隔符，不忽略空记录。数字为 JSON 数字语法，不接收 NaN/Infinity/空字段。

矩阵 JSON：

```json
{"schema":"moonchoice.matrix/1","alternatives":["A","B"],"criteria":["speed"],"directions":["benefit"],"values":[[1],[2]]}
```

`dispatch(String) -> String` 接收：

```json
{"schema":"moonchoice.request/1","operation":"rank","matrix":{"schema":"moonchoice.matrix/1","alternatives":["A","B"],"criteria":["speed"],"directions":["benefit"],"values":[[1],[2]]},"weights":[1],"algorithm":{"kind":"topsis","normalization":"minmax"}}
```

operation 为 rank、report、scenarios；后者用二维 scenarios 替代 weights。算法为 saw/topsis（必须指定 normalization=minmax/vector）、product、vikor（必须指定 v）、promethee（必须指定每指标 preferences）。偏好如 `{"kind":"linear","q":1,"p":5}`；另有 usual、ushape(q)、vshape(p)、level(q,p)、gaussian(sigma)。拒绝未知/不适用字段。响应包含 schema、ok 与 result 或分类 error。详见 [架构说明](docs/architecture.md)。

## 数值和语义约定

- 最多256个备选项、32个指标；标签唯一、非空白、<=128 UTF-16单元；输入有限且绝对值<=1e100。
- 权重非负且至少一个正数，自动归一化。minmax常量列为零信息；向量成本列取负号，不采用倒数变换。
- TOPSIS全同候选得0.5；VIKOR零跨度项为0；无信息客观赋权显式返回均匀回退；WPM要求原始值严格为正。
- 先精确稳定排序，再按组首分数绝对容差（默认1e-10）形成competition rank。不是epsilon比较器，不保证链式近似相等可传递。
- 单指标不支持连续权重交点，网格只允许权重1。Spearman/tau-b无秩方差返回None。
- 最多16种比较方法、64组情景；情景预算 n*n*p*count<=16777216。JSON/CSV<=1 Mi UTF-16单元；JSON<=8层容器。
- DecisionMatrix不暴露内部可变数组；返回结果数组可变，Ranking消费接口重校验一致性。不要修改报告后再当可信计算结果。
- Double舍入和下溢仍存在，极小权重/相对差异可能丢失；不提供任意精度或跨平台逐位一致保证。

**不做**投票/IRV、稳定匹配、连续规划、预测训练、缺失值填补、随机概率推断或自动执行采购/医疗/金融决策。情景频数不是获胜概率。归一化依赖候选集合，删项可能反转排序，库如实报告而不宣称消除。

## 开发和验收

```sh
moon info && moon fmt
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
python scripts/audit.py
```

GitHub Actions 对 wasm-gc、wasm、js、native 执行接口一致性、严格检查、测试、构建和三个工作流。审计脚本列出生产文件并保守统计有效提交；测试、示例、接口文件不计核心行数。再生成数值对照见 [参考与验证](docs/references.md)。不提供未经实测的性能基准或绝对唯一性承诺。[语义查重记录](docs/competition/duplicate-check.md)。

[MIT](LICENSE) · [AI 使用说明](AI-USE.md) · [安全边界](SECURITY.md) · [变更记录](CHANGELOG.md)
