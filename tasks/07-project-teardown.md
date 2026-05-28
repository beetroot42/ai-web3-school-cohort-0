# Task 07 — AI × Web3 项目拆解

> beetroot42 · AI × Web3 School · 2026-05-27
>
> 拆解对象：**Bittensor (TAO)** 和 **Ritual Network**

---

## 对象一：Bittensor (TAO)

### 它在解决什么问题

AI 训练和推理的算力高度集中在少数大公司（OpenAI、Google、AWS）手中，外部无法插入和验证这些模型的输出质量。
Bittensor 试图构建一个去中心化的 AI 智能市场：任何人都可以贡献 AI 模型（作为 Miner），任何人都可以对输出质量进行评分（作为 Validator），贡献越优质，获得的 TAO 代币越多。用 token 经济学替代集中调度，让「谁的模型更好」变成一个有经济激励的市场博弈问题。

### AI 部分是什么

- **Miners** 在链下运行实际的 AI 模型（LLM 文本生成、图像生成、金融预测等），响应来自 Subnet 的推理请求。
- 每个 **Subnet** 定义自己的任务和质量评估标准——本质上是一个可编程的 AI 任务市场。
- **Yuma Consensus** 是评价机制的核心：各 Validator 独立打分，最终按质量加权聚合，决定 TAO 的分发比例。AI 的"好坏"被量化为链上可结算的权重值。

### Web3 部分是什么

- **Subtensor 区块链**（基于 Substrate 框架）：记录所有 Miner/Validator 的权重、排名、奖励分发。
- **TAO 代币**：激励机制的货币单位，最大供应量 2100 万（类比 BTC），有减半机制。
- **Staking**：Validator 需质押 TAO 才能参与评分，经济损失作为恶意行为的惩戒成本（类似 PoS slashing 逻辑）。
- **2025 年升级 Dynamic TAO（dTAO）**：引入 Subnet 级 Alpha 代币 + AMM 定价，更细粒度的去中心化市场结构。

### 可验证材料

| 类型 | 链接 |
|------|------|
| 白皮书 | https://bittensor.com/whitepaper |
| Subtensor 链层代码 | https://github.com/opentensor/subtensor |
| Bittensor SDK | https://github.com/opentensor/bittensor |
| 官网 / 生态 | https://bittensor.com |
| 链上数据浏览 | https://taostats.io |
| Subnet 列表（可观察各 Subnet 权重） | https://taostats.io/subnets |

### 我的判断与疑问

**启发：**
Bittensor 提供了一个非常清晰的思维模型：**把 AI 模型的输出质量变成可以市场化结算的商品**。这和传统 AI 服务（API 按调用量付费，质量不透明）有本质区别——后者你无法验证 OpenAI 到底给你跑了什么模型。这个方向在 AI Agent 大规模普及后会变得更重要：Agent 之间如何互相信任和结算？

**核心问题（也是最大的批评）：**

1. **"质量"如何客观评价？** Yuma Consensus 依赖 Validator 的主观评分，而 Validator 本身有经济激励去偏袒自己合谋的 Miner（权重抄袭、Validator-Miner 勾结）。这不是小问题，是根本性的机制设计漏洞。
2. **链上记录 ≠ 推理可验证**：Subtensor 只记录权重和奖励，不记录具体的 AI 推理过程。如果 Miner 用低质量模型但 Validator 给高分，链上根本看不出来。这更像是"信任 Validator 的经济激励"，而不是真正的可验证 AI。
3. **中心化风险**：2026 年 4 月，Covenant AI 团队公开指控创始人 Jacob Steeves 实质上单方面控制网络奖励分配，与"去中心化"叙事冲突。这类治理风险在代币价格暴跌时会被放大。

**未解疑问：**
- Yuma Consensus 在 Validator 串谋率高时是否有数学上的稳健性保证？有没有类似 BFT 的理论分析？
- Dynamic TAO 的 AMM 机制能否实质性地打破大户的权重控制？还是只是换了一种集中方式？

---

## 对象二：Ritual Network

### 它在解决什么问题

智能合约本质上是确定性、封闭的：无法读取实时数据，更无法调用 AI 模型。现有解法只解决了外部数据问题，但 AI 推理的计算量远超 Oracle 能处理的范围，且传统 Oracle 无法证明这个 AI 输出确实是由特定模型生成的。

Ritual 的定位是**链上智能合约的 AI 协处理器（AI Coprocessor）**：让 Solidity 合约能直接调用 AI 推理，并获得密码学证明——证明这次推理真的是用了那个模型、那个输入，没有被篡改。

### AI 部分是什么

- **Infernet 节点**：分布式节点网络，链下运行实际的 AI 模型（支持 PyTorch、ONNX、LLM 等）。
- **Proof-of-Inference（PoI）**：推理完成后，节点生成密码学证明（ZKP 或 TEE 证明），与输出结果一起上链。
- **EZKL 框架**：将 ONNX 格式的 ML 模型转换为 ZK 电路，使链上合约可以验证"这个输出确实是这个模型跑出来的"。
- 支持三种可验证性级别：ZK 证明（最强，适合小模型）、TEE 硬件隔离（适合大模型）、乐观验证（挑战期机制，吞吐量最高）。

### Web3 部分是什么

- **Infernet SDK**：Solidity 合约通过 SDK 发起推理请求，接收结果 + 证明，整个流程由智能合约编排。
- **EigenLayer 集成**：节点可以 restake ETH 作为经济安全担保；提交错误推理会被 slash。把以太坊的经济安全引入 AI 推理节点的诚实性保障。
- **Ritual Chain（开发中）**：专属 L1，使用 EVM++（增强 EVM，原生支持 AI 操作），采用 Symphony 共识的 Execute-Once-Verify-Many（EOVMT）模型——只有一个节点做推理，其余节点验证证明，大幅降低冗余计算。

### 可验证材料

| 类型 | 链接 |
|------|------|
| 官网 | https://ritual.net |
| Infernet 容器示例（可运行） | https://github.com/ritual-net/infernet-container-starter |
| 技术文档 | https://docs.ritual.net |
| EZKL（ZK-ML 框架） | https://github.com/zkonduit/ezkl |
| 博客 / 技术解读 | https://ritualfoundation.com/blog |

**可操作验证**：`infernet-container-starter` 仓库的 `hello-world` 和 `torch-iris` 项目可以本地跑起来，完整演示"合约发请求 → Infernet 节点推理 → 结果返回合约"的完整链路。`torch-iris` 还演示了 EZKL ZK 证明生成。

### 我的判断与疑问

**启发：**

Ritual 解决的问题非常具体：**"我怎么知道这个 DeFi 协议用的 AI 风险模型是它声称的那个？"** 这在传统 Web2 中完全依赖信任，但在链上金融场景中不可接受。Ritual 的路径——密码学证明 + 经济惩罚双重保障——是目前我见过最系统性的答案。

产品视角的洞见：**"可验证 AI 推理"本质上是在解决 AI 的信任问题，而不只是技术问题**。随着 AI Agent 开始控制链上资金（DeFi Agent、自动化合约执行），"这个 Agent 真的按照它声称的逻辑做出了决策"会变成核心安全需求。

**核心限制（技术诚实）：**

1. **ZK 证明的算力开销巨大**：目前 ZKML 的证明生成比原始推理慢 10,000 倍（2025 年已从 1,000,000 倍改善）。这意味着 GPT-4 级别的大模型实际上无法走 ZK 路径，只有小模型（BERT 级别）才实用。
2. **量化精度损失**：ZK 电路要求整数域运算，浮点数 ML 模型需要量化，这会带来精度损失，敏感场景下可能不可接受。
3. **Ritual Chain 还未上线**：当前可验证的产品是 Infernet（Oracle 层），Ritual Chain 和 Symphony 共识仍是路线图中的内容，还没有主网可验证。

**未解疑问：**
- EOVMT 模型（执行一次、验证多次）如何处理节点提交错误证明的情况？验证节点如何在不重新执行推理的情况下检测出来？
- 当 AI 模型本身被更新（版本迭代），链上的"我用了这个模型"如何锚定版本？模型哈希上链是唯一答案吗？

---

## 横向对比与总结

| 维度 | Bittensor | Ritual |
|------|-----------|--------|
| **核心定位** | 去中心化 AI 市场（竞争出质量） | 可验证 AI 推理（密码学保证真实性） |
| **AI 可验证方式** | 经济激励（Validator 评分，非密码学）| ZK 证明 / TEE / 乐观验证（密码学） |
| **Web3 角色** | 奖励结算账本 + 去中心化治理 | 智能合约集成 + 经济安全（EigenLayer）|
| **最大风险** | Validator 串谋、治理中心化 | ZK 算力瓶颈、产品尚未完全生产可用 |
| **PoW 可验证性** | 链上权重记录（弱）；推理本身链下不可验证 | 密码学证明上链（强）；Infernet 有 GitHub 可运行 Demo |
| **PM 视角关注点** | 谁在为 AI 质量背书？激励机制是否 hold | AI + 链上金融的风险合规场景；Agent 经济时代的信任基础设施 |

**最终判断**：
这两个项目代表了 AI × Web3 的两种截然不同的路径——Bittensor 是**市场机制路径**（用代币博弈代替中心化质量评估），Ritual 是**密码学路径**（用数学证明代替信任）。两者都没有完全解决各自的核心难题，但方向都是真实的工程问题，不是纯叙事。

对于 Hackathon 项目而言，Ritual 的 Infernet 是更容易作为构建基础设施的工具层——它有可运行的 SDK 和清晰的合约集成接口；Bittensor 的 Subnet 生态更适合作为 AI 模型的分发市场来利用，而不是底层基础设施。

---

## 来源

- Bittensor 白皮书：https://bittensor.com/whitepaper
- Subtensor GitHub：https://github.com/opentensor/subtensor
- TaoStats 链上数据：https://taostats.io
- Ritual 官网：https://ritual.net
- Ritual 文档：https://docs.ritual.net
- Infernet 示例代码：https://github.com/ritual-net/infernet-container-starter
- EZKL (ZK-ML)：https://github.com/zkonduit/ezkl
- Covenant AI 事件（Bittensor 治理争议）：公开 X/Twitter 讨论，2026 年 4 月
