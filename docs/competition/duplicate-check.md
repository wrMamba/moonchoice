# MoonChoice 语义查重与选题记录

日期：2026-10-14。仅针对实际检索/源码审阅范围，不构成官方裁决，不宣称绝对唯一。

## 三个不同问题域候选

评分顺序：生态广度、用户多样性、复用、低重合风险、深度、验证、工期、维护；各1–5。硬失败不由分数抵消。

| 候选/任务 | 分值 | 决策 |
| --- | --- | --- |
| MoonChoice：观测矩阵多准则排序与解释 | 5/4/5/4/5/5/4/4=36 | 通过当前范围并选择 |
| 稳定匹配：双方偏好与容量分配 | 4/4/4/1/4/5/4/4=30 | 淘汰：MoonMatch成熟直接重合 |
| Petri网：标识、使能/触发、PNML分析 | 4/4/5/1/5/4/3/4=30 | 淘汰：永久登记MoonPetri及现有包核心重合 |

## 范围与限制

按已安装osc2026-guide的Project Research Guide执行。MoonCakes `moon search <term> --limit 100 --json` 共25组：topsis、vikor、promethee、electre、multicriteria、多准则、outranking、decision、ahp、pareto、entropy weighting、stable matching、gale shapley、hospital residents、assignment、petri、pnml、MCDA、MCDM、ideal solution、compromise ranking、criteria weights、promethee_ii、topsis_score、决策矩阵。

直接名称零结果不是通过理由；promethee/electre等模糊结果经功能筛查。decision92项、assignment达100上限，非全量穷尽。相邻包执行精确moon view，审阅公开接口/源码/测试。

GitHub检索MoonBit+TOPSIS/multicriteria/PROMETHEE仓库，以及TOPSIS/VIKOR/PROMETHEE/entropy_weights/analytic hierarchy代码；weighted sum命中16项并实际检查连续多目标LP。incomplete_results=false不证明全站代码已索引。另读[官方清单](https://github.com/moonbitlang/awesome-moonbit)和本地永久注册表完整相关指纹。原始响应和源码快照在仓库外研究目录；此处保留可复核路径，不发布账号/环境日志。

## 相邻矩阵

| 项目与实际证据 | 输入→行为→输出 | 分类/差异 |
| --- | --- | --- |
| [vectie/moontown](https://github.com/vectie/moontown) 0.1.6，src/commission/commission.mbt及commission_wbtest.mbt | 证据账本/提案→0..10加权晋升 | 高度相邻聚合，不提供异量纲通用矩阵、理想距离、妥协集、阈值流量；扩展其领域状态不适合通用MCDA |
| [mwqcodex/moonbitSPC](https://github.com/mwqcodex/moonbitSPC) 0.2.0，mbti、analytics源码/测试 | 质量统计→weighted_row_score/weighted_scores、缺陷类别Pareto | 共享加权原语不属创新；已阅接口无TOPSIS/VIKOR/PROMETHEE，缺陷类别排序不是支配前沿 |
| [Juwan-Hwang/moon-certified](https://github.com/Juwan-Hwang/moon-certified) 0.1.1，optimization/multi_obj_lp/multi_obj_lp.mbt及测试 | 连续可行域→weighted-sum/epsilon-constraint LP→最优解 | 同方向不同任务，本项目不求连续规划，处理已观测有限选项 |
| [hutingyu-nuist/moonballot](https://github.com/hutingyu-nuist/moonballot) 已阅0.1.0、公开较新0.1.3，pairwise源码/测试 | 序数选票→两两计票/IRV | 非原单位差异的PROMETHEE，本项目不做选举 |
| [chenzexin02-hash/moonbit-decision-tree](https://github.com/chenzexin02-hash/moonbit-decision-tree) 0.2.0，接口/README | 标记数据→树训练→预测 | 名称相邻但核心不重合，本项目不做训练 |
| [shencangsheng513/moonmatch](https://github.com/shencangsheng513/moonmatch) 0.1.0，mbti及hospital-resident测试 | 双边偏好/容量→稳定配对 | 与第二候选直接重合，淘汰；本项目无分配算法 |
| 永久登记MoonPetri及petri/pnml关联包 | 标识/迁移→网分析 | 第三候选直接重合，淘汰；本项目无迁移状态 |

维护判断基于公开版本、可访问源码和测试，不以下载量/排序替代。私有、未索引和后续新发布项目不在结论内。独立建设必要性是稳定的有限MCDA数据模型与解释流程，不是加权和/矩阵本身。

## 核心指纹与反向复核

输入：有限Double矩阵、benefit/cost、权重、原单位阈值、显式情景。核心：minmax/vector→SAW/TOPSIS/WPM/VIKOR、六偏好PROMETHEE、Pareto层、AHP/客观赋权、秩一致性、解析交点和删除重算。输出：秩、贡献/距离/流量、妥协集、频数及JSON/CSV。

反向关键词包括promethee_ii、topsis_score、criteria weights、compromise ranking、决策矩阵，且检查weighted sum邻项源码。交付前再次检索并重读共享注册表新增相关条目；若发现成熟直接替代则停止发布，不用功能堆叠掩盖重复。当前记录范围内未发现成熟的直接替代；数学方法均非原创。
