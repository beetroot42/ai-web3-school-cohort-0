# Week 1 Proof-of-Work Pack

> **学员**：beetroot42 | **周期**：2026-05-22 ~ 2026-05-28 | **项目**：AI × Web3 School Cohort 0
>
> 📌 **总入口**：https://github.com/beetroot42/ai-web3-school-cohort-0

---

## ⚡ 本周一句话总结

> 从"有 Web3 基础知识"到"真正在链上部署合约、验证交易、构建 AI 辅助工具"，打通了从概念到实操的完整闭环，并建立了 AI 不能越权的工作边界认知。

---

## 📋 完成任务一览

| # | 任务 | 形式 | 链接 | 状态 |
|---|------|------|------|------|
| 01 | Web3 基础词汇表（8+ 核心概念） | Markdown | [web3-basics-glossary.md](./tasks/web3-basics-glossary.md) | ✅ |
| 02 | 测试网交易 + 区块浏览器验证 | Markdown | [02-testnet-transaction.md](./tasks/02-testnet-transaction.md) | ✅ |
| 03 | EOA vs 合约账户对比卡片 | Markdown | [03-account-types-comparison.md](./tasks/03-account-types-comparison.md) | ✅ |
| 04 | AI × Web3 工作流可视化 | HTML Demo | [04-ai-web3-workflow.html](./tasks/04-ai-web3-workflow.html) | ✅ |
| 05 | Sepolia 合约部署与调用 | Hardhat + Solidity | [05-contract-deploy/](./tasks/05-contract-deploy/) | ✅ |
| 06 | 合约解读助手（AI 交互工具） | 单文件 HTML App | [06-contract-explainer/](./tasks/06-contract-explainer/) | ✅ |
| 07 | AI × Web3 项目拆解（Bittensor + Ritual） | Markdown 分析 | [07-project-teardown.md](./tasks/07-project-teardown.md) | ✅ |
| 08 | 受限 Web3 助手 Workflow 设计 | Markdown + Mermaid | [08-restricted-web3-assistant.md](./tasks/08-restricted-web3-assistant.md) | ✅ |

---

## 🔗 链上验证材料（可公开查询）

### 测试网转账（Task 02）

| 字段 | 内容 |
|------|------|
| 网络 | Ethereum Sepolia Testnet |
| 发送方 | `0xbdF9561e33f868736b8A23e5d681526A6004D06f` |
| 接收方 | `0xa29c684fb5608C1dB01684F0B11d312f8887cB65` |
| 交易哈希 | `0x7a02ee2511d045c401c3f8bb9a3ad31733b408825b88a6dc6f46bb976a967290` |
| Etherscan | https://sepolia.etherscan.io/tx/0x7a02ee2511d045c401c3f8bb9a3ad31733b408825b88a6dc6f46bb976a967290 |
| 状态 | ✅ Success · Block #10,909,383 · 0.00001 ETH |

### 智能合约部署（Task 05）

| 字段 | 内容 |
|------|------|
| 合约名称 | `SimpleCounter` |
| 合约地址 | `0x6FDAD51Ea6096a33C7Df91bA963AFc8276324502` |
| 部署账户 | `0xa29c684fb5608C1dB01684F0B11d312f8887cB65` |
| Etherscan 合约页 | https://sepolia.etherscan.io/address/0x6FDAD51Ea6096a33C7Df91bA963AFc8276324502 |
| increment() 调用 | https://sepolia.etherscan.io/tx/0xa07e40d4a2e3b9b695eff9c7eda2e7fc70114eeac66799f5efdce7318986c97d |
| 结果 | count: 0 → 1 ✅ |

---

## 🤖 AI 工具实践记录

### Task 06 — 合约解读助手（AI 交互 Demo）

- **形式**：单文件 HTML，无依赖，浏览器直接打开
- **功能**：
  - 解析任意合约 ABI JSON → 展示函数列表（Write/Read/Event 分类）
  - 调用 OpenAI API → 中文解释每个函数（5 维度：作用/权限/Gas/状态/场景）
  - AI 自动生成 3 道选择题 Quiz + 即时评分
- **AI vs 人工分工**：

  | 部分 | 来源 |
  |------|------|
  | SimpleCounter ABI 数据 | 🧑 人工（对照 Sol 源码验证） |
  | ABI 解析逻辑 | 🧑 人工编写 |
  | 函数解释文字 | 🤖 GPT 实时生成 |
  | Quiz 题目 + 解析 | 🤖 GPT 实时生成 |
  | UI 初稿 | 🤖 AI 辅助，人工审查 |

- **GitHub**：https://github.com/beetroot42/ai-web3-school-cohort-0/blob/main/tasks/06-contract-explainer/index.html

---

## 🗺️ AI × Web3 工作流设计（Task 08）

**受限 Web3 助手核心思路**：AI 可以规划、解释、生成草稿、验证结果，但不能接触私钥、自动签名或绕过人工确认。

```
用户输入意图
  └─ 🤖 AI：解析 → 操作计划 → 交易草稿 → 确认清单
                                        ↓
                       🔐 人工确认点 ①：审查地址/函数/参数
                                        ↓（通过）
                       🔐 人工确认点 ②：钱包签名广播（AI 完全不参与）
                                        ↓
                       🤖 AI：查询 Etherscan → 生成验证报告
                                        ↓
                       🔐 人工确认点 ③：打开链接手动核查
```

完整 Mermaid 流程图见：[08-restricted-web3-assistant.md](./tasks/08-restricted-web3-assistant.md)

**核心边界一句话**：
> AI 是地图，不是司机。私钥签名永远在用户手里。

---

## 📚 AI × Web3 项目拆解（Task 07）

拆解了两个真实项目，建立识别"AI 部分"和"Web3 部分"的判断框架：

| 项目 | 解决什么问题 | AI 部分 | Web3 部分 | 可验证材料 |
|------|------------|---------|----------|-----------|
| **Bittensor (TAO)** | 去中心化 AI 质量评估市场 | Miner 跑模型、Yuma Consensus 评分 | Subtensor 链、TAO 代币、Staking | [GitHub](https://github.com/opentensor/subtensor) · [TaoStats](https://taostats.io) |
| **Ritual Network** | 链上合约可验证 AI 推理 | Infernet 节点 + ZK Proof-of-Inference | EigenLayer restaking、Solidity SDK | [GitHub](https://github.com/ritual-net/infernet-container-starter) · [文档](https://docs.ritual.net) |

**关键判断**：Bittensor 用经济博弈替代质量评估（弱可验证性）；Ritual 用密码学证明替代信任（强可验证性，但 ZK 算力开销仍是瓶颈）。

---

## ⚠️ 本周遇到的问题与人工修正记录

### 问题 1：Hardhat 部署失败 —— RPC 连接问题

**卡点**：Task 05 初次部署时，使用 Alchemy RPC 频繁超时（`HardhatError: timeout`），导致部署脚本无法广播交易。

**AI 的建议**：检查 `hardhat.config.js` 的 RPC URL 配置，尝试切换到 PublicNode 公共 RPC。

**人工修正**：
1. 手动替换 RPC 为 `https://ethereum-sepolia-rpc.publicnode.com`
2. 验证 RPC 可用性：`curl` 测试返回正常区块高度
3. 重新执行部署脚本，确认私钥在 `.env` 中且 `.env` 已加入 `.gitignore`

**结果**：部署成功，合约地址 `0x6FDAD51...4502`，链上确认 ✅

**修正记录 commit**：https://github.com/beetroot42/ai-web3-school-cohort-0/commits/main

---

### 问题 2：AI 生成的 Quiz 答案需要人工核查

**卡点**：Task 06 中，GPT 生成的 Quiz 题目有一道将 `setLabel()` 描述为"仅 owner 可调用"，但实际上 `SimpleCounter.sol` 的 `setLabel()` 是 `external`，**任何人**都可以调用（没有权限限制）。

**人工修正**：
- 对照 `SimpleCounter.sol` 源码（第 43-46 行）核实
- 确认 `setLabel()` 无 `require(msg.sender == owner)` 检查
- 在 Task 08 的风险清单中增加："Quiz 答案可靠性依赖 GPT，需人工核对"
- 作为典型案例说明"AI 生成 ≠ AI 正确"，需要人工验证步骤

**修正记录**：见 [08-restricted-web3-assistant.md §5 风险](./tasks/08-restricted-web3-assistant.md) 中的风险条目 #5

---

## 🧠 Web3 概念卡片（核心 8 条）

完整词汇表见 [web3-basics-glossary.md](./tasks/web3-basics-glossary.md)，核心概念速览：

| 概念 | 一句话理解 |
|------|-----------|
| 区块链 | 所有人共同维护的、无法篡改的公开账本 |
| 钱包 | 私钥的管理工具，地址是你的"链上身份证" |
| EOA | 人控制的普通账户，由私钥签名发起交易 |
| 合约账户 | 由代码控制的账户，被调用时自动执行逻辑 |
| Gas | 链上计算/存储的费用单位，防止滥用 |
| 交易哈希 | 每笔交易的唯一收据，可公开查验 |
| 测试网 | 与主网逻辑完全一致的练习环境，ETH 无价值 |
| ABI | 合约的"使用说明书"，描述可调用函数和参数 |

---

## 📅 学习日志

- [2026-05-22.md](./daily/2026-05-22.md) — 学习系统初始化、learning-plan 生成
- Task 02–08 均在 2026-05-23 ~ 2026-05-28 期间完成

---

## 🔗 所有相关链接

| 类型 | 链接 |
|------|------|
| GitHub 仓库 | https://github.com/beetroot42/ai-web3-school-cohort-0 |
| 合约 Etherscan | https://sepolia.etherscan.io/address/0x6FDAD51Ea6096a33C7Df91bA963AFc8276324502 |
| 转账 TxHash | https://sepolia.etherscan.io/tx/0x7a02ee2511d045c401c3f8bb9a3ad31733b408825b88a6dc6f46bb976a967290 |
| increment() TxHash | https://sepolia.etherscan.io/tx/0xa07e40d4a2e3b9b695eff9c7eda2e7fc70114eeac66799f5efdce7318986c97d |
| AI 工具 Demo（HTML） | https://github.com/beetroot42/ai-web3-school-cohort-0/blob/main/tasks/06-contract-explainer/index.html |
| Handbook | https://aiweb3.school/zh/handbook/ |
| WCB 课程页 | https://web3career.build/zh/programs/AI-Web3-School |
