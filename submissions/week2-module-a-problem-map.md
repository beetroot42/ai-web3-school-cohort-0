# Week 2 Module A — AI × Web3 问题地图

**作者**：beetroot42  
**日期**：2026-05-22  
**来源**：[AI × Web3 School Handbook](https://aiweb3.school/zh/handbook/)  
**仓库**：https://github.com/beetroot42/ai-web3-school-cohort-0

---

## 总览：为什么 AI × Web3 是一个真实的交叉问题

> 如果只从 AI 侧看，会低估资产和权限风险；只从 Web3 侧看，又容易忽略模型、上下文和工具编排的复杂度。  
> —— AI × Web3 School Handbook

两个领域的核心矛盾点：

| 维度 | AI 视角 | Web3 视角 |
|------|---------|-----------|
| 身份 | 会话 ID、用户画像 | 钱包地址、链上签名 |
| 权限 | Prompt 规则、system message | 私钥控制、智能合约 |
| 可信 | 模型置信度 | 共识机制、不可篡改记录 |
| 隐私 | 数据最小化、本地推理 | 公开链上状态、地址关联 |
| 支付 | API 调用计费 | 链上原子结算、无需中介 |

**交叉才有的问题**：当 AI Agent 开始持有钱包、调用合约、代表用户发起链上交易时，"AI 写错了"不再只是 UX 问题，而是资产安全问题。

---

## 方向一：Payment / Commerce / Settlement（支付 / 商业 / 结算）

### 核心问题
Agent 完成一项任务后，如何获得报酬？多个 Agent 协作完成一个流程时，如何实现原子结算而不依赖中心化平台？

### AI 的作用
- **意图理解**：解析用户的自然语言请求（"帮我订最便宜的会议室"），拆解成可执行子任务
- **报价协商**：Agent 之间用自然语言或结构化 JSON 协商服务价格
- **执行编排**：把"询价 → 授权 → 调用 → 确认收货 → 结算"串成自动化工作流
- **异常处理**：检测服务交付失败，触发争议流程或退款条件

### Web3 机制
- **Machine Payment（机器支付）**：Agent 持有热钱包（Session Key 限额），完成微支付时不需要每次唤醒用户确认
- **Settlement & Escrow（结算与托管）**：智能合约锁定资金，服务交付后自动释放，失败后自动退款
- **链上收据**：每笔支付留下不可篡改的交易凭证，用于审计和声誉积累
- **跨链结算**：通过桥接协议让不同链上的 Agent 完成多方结算

### 关键 Handbook 章节
- [Machine Payment](https://aiweb3.school/zh/handbook/bridge/machine-payment/)
- [Settlement & Escrow](https://aiweb3.school/zh/handbook/bridge/settlement-and-escrow/)
- [Agentic Commerce](https://aiweb3.school/zh/handbook/tracks/agentic-commerce/)

### 典型场景
```
用户 → "帮我预订东京一家 4 星酒店，预算 15,000 日元/晚"
Agent → 调用酒店 API（付费）→ 比价 → 选定 → 从 Session Key 划扣 USDC
         → 酒店合约 mint 预订 NFT → 链上凭证回传给用户
```

---

## 方向二：Identity / Reputation / Capability / Interoperability（身份 / 声誉 / 能力 / 互操作）

### 核心问题
当 Agent 从一个封闭应用走出来，在多个平台接受委托、调用服务时——它是谁？谁能验证它？它的历史行为可不可信？

### AI 的作用
- **能力声明生成**：Agent 用自然语言描述自己能做什么，并生成结构化能力卡（ANS、AgentCard）
- **声誉推断**：从历史任务记录、评价数据中提炼能力评分
- **跨平台适配**：理解不同协议（A2A、MCP）的接口规范，自动完成翻译和调用
- **冒充检测**：识别伪装成高声誉 Agent 的恶意实体

### Web3 机制
- **DID（去中心化身份）**：链上唯一标识符，不依赖任何中心化平台颁发
- **可验证凭证（VC）**：第三方背书的能力证明，链上锚定不可伪造
- **链上声誉积累**：每次完成任务后，链上写入执行记录，形成可公开审计的信用历史
- **Interoperability 协议**：A2A（Agent-to-Agent）、ANS（Agent Name Service）让跨平台 Agent 协作有共同语言

### 关键 Handbook 章节
- [Agent Identity](https://aiweb3.school/zh/handbook/bridge/agent-identity/)
- [Agent Trust & Reputation](https://aiweb3.school/zh/handbook/bridge/agent-trust-and-reputation/)

### 典型场景
```
用户 A 的 Agent → 向陌生服务 Agent 发起委托
服务 Agent 出示 DID + VC（"具备法律摘要能力，已完成 2,000+ 次任务"）
→ 用户 Agent 查链上声誉记录 → 确认可信 → 签名授权委托
→ 任务完成后 → 两方均写入链上评价记录
```

---

## 方向三：Wallet / Permission / Safe Execution（钱包 / 权限 / 安全执行）

### 核心问题
给 Agent 一个钱包私钥，等于给它无限授权。如何设计"最小授权"使得 Agent 能自主操作，同时人类随时可以撤销？

### AI 的作用
- **意图解析**：把"帮我买一些 ETH解析成具体交易参数，而不是直接执行任意 calldata
- **风险评估**：在签名前模拟交易，检测异常（转账金额超出预期、目标地址黑名单）
- **Human-in-the-loop 判断**：根据风险等级，决定是静默执行还是唤醒用户确认
- **执行监控**：实时监控 Agent 行为，发现偏离任务的操作立即暂停

### Web3 机制
- **Account Abstraction（账户抽象）**：Smart Account 支持自定义验证逻辑，实现 Session Key（限额、限时、限对象）
- **Policy Guard**：合约层面定义可执行操作白名单，越权操作直接 revert
- **Simulation（模拟执行）**：发链前 dry-run 所有交易，无效操作在本地拦截
- **多签/延时锁**：高风险操作要求多方确认或等待冷静期

### 关键 Handbook 章节
- [Agent Wallet](https://aiweb3.school/zh/handbook/bridge/agent-wallet/)
- [Account Abstraction](https://aiweb3.school/zh/handbook/web3/account-abstraction/)
- [Wallet / Permission](https://aiweb3.school/zh/handbook/tracks/wallet-permission/)

### 典型场景
```
用户创建 Agent，授予 Session Key：
  - 每日限额 50 USDC
  - 只能调用白名单合约
  - 有效期 7 天
  - 转账超 20 USDC 须推送确认

Agent 执行：检测到超额交易 → 暂停 → 推送提醒 → 等待用户签名
→ 时间锁到期 → Session Key 自动失效
```

---

## 方向四：Privacy / Security / Sovereignty（隐私 / 安全 / 主权）

### 核心问题
Web3 数据公开，AI 系统扩大数据面。用户的地址、持仓、治理投票、AI 对话记录如何避免被组合出精准用户画像？Agent 系统如何防御 Prompt Injection 和工具滥用？

### AI 的作用
- **本地推理**：敏感数据不出设备，用本地模型处理隐私相关任务
- **数据最小化**：只向 Agent 提供当前任务所需的最小上下文
- **安全审计**：分析 Agent 调用日志，检测异常工具调用和数据外泄行为
- **Prompt Injection 防御**：在工具响应进入上下文之前，对恶意内容进行过滤和沙盒处理

### Web3 机制
- **零知识证明（ZK）**：证明"我的余额满足条件"而不暴露具体数额
- **链上审计日志**：不可篡改地记录 Agent 的关键操作，出问题可回溯
- **主权数据存储**：用户数据存储在自己控制的节点，而不是平台数据库
- **隐私合约**：链上隐私计算（Fully Homomorphic Encryption、TEE）让数据在加密状态下被处理

### 关键 Handbook 章节
- [AI Privacy](https://aiweb3.school/zh/handbook/bridge/ai-privacy/)
- [AI Security](https://aiweb3.school/zh/handbook/bridge/ai-security/)
- [AI Sovereignty](https://aiweb3.school/zh/handbook/bridge/ai-sovereignty/)

### 典型场景
```
用户用 AI 助手管理 DeFi 头寸
问题：AI 服务商看到用户完整持仓 + 对话历史 + 钱包地址
解法：
  本地模型处理持仓 → 只上传 ZK 证明（"余额 > 阈值"）
  操作日志上链（不含内容，只含操作类型 + 时间戳）
  用户拥有"数据删除权"（从自己节点删除，链上不存明文）
```

---

## 方向五：Dev Tooling / Agent Workflow（开发工具 / 智能体工作流）

### 核心问题
Web3 开发摩擦极大：合约 ABI 难读、calldata 不直观、测试覆盖难设计、部署不可逆。AI 能降低多少摩擦？工作流里哪些步骤可以自动化，哪些必须人工审查？

### AI 的作用
- **合约理解**：把 ABI、Solidity 源码翻译成自然语言解释（"这个函数会转走你的全部余额"）
- **测试生成**：根据合约逻辑自动生成边界条件测试用例
- **代码审查**：识别常见漏洞模式（重入攻击、整数溢出、权限错误）
- **工作流编排**：把"写合约 → 测试 → 审计 → 部署 → 验证"串成半自动流水线

### Web3 机制
- **链上状态作为上下文**：Agent 读取真实链上数据（余额、合约状态）辅助决策，而非依赖静态文档
- **交易模拟**：在 Tenderly、Foundry fork 环境中预演，让 AI 分析模拟结果
- **可验证执行记录**：部署、交互、测试结果写入链上或去中心化存储，形成可复现的工作记录
- **MCP 工具链**：通过 MCP 协议把 RPC、钱包、浏览器插件、Etherscan 整合成 Agent 可调用工具集

### 关键 Handbook 章节
- [Dev Tooling](https://aiweb3.school/zh/handbook/tracks/dev-tooling/)
- [Agent Workflow](https://aiweb3.school/zh/handbook/bridge/agent-workflow/)
- [MCP](https://aiweb3.school/zh/handbook/ai/mcp/)

### 典型场景
```
开发者："帮我审查这个合约有没有重入漏洞"
Agent →
  1. 读取合约 ABI + 源码（Web3 Tool Use）
  2. 生成攻击测试用例（AI 推理）
  3. 在 Foundry fork 上执行（链上模拟）
  4. 返回：发现漏洞 + 建议修复方案 + 测试代码
  5. 修复后重新跑测试 → 自动记录审计结果
```

---

## 方向六：Governance / Coordination / Public Goods（治理 / 协调 / 公共物品）

### 核心问题
DAO 里信息太多（提案、论坛、会议纪要、预算请求），导致少数人掌握上下文，多数人只能被动投票。AI 能帮助治理系统减少信息不对称，但谁来验证 AI 总结的准确性？

### AI 的作用
- **提案摘要**：自动生成 DAO 提案的结构化总结（背景、影响、投票建议）
- **多方观点呈现**：从论坛讨论中提炼支持/反对论点，减少信息茧房
- **预算追踪**：对比提案承诺与实际支出，生成可读报告
- **协调建议**：识别重复提案、冲突资源分配，辅助仲裁

### Web3 机制
- **链上提案记录**：所有提案在链上存档，AI 总结可被溯源验证
- **投票权重机制**：链上记录代币持仓、贡献积分，作为 AI 决策辅助的输入
- **公共物品资助**：Gitcoin Grants 等机制让 AI 辅助的治理工具获得可持续资金
- **DAO 执行层**：治理投票通过后，链上 Executor 合约自动执行，AI 负责追踪执行情况

### 关键 Handbook 章节
- [Governance AI](https://aiweb3.school/zh/handbook/bridge/governance-ai/)
- [Governance](https://aiweb3.school/zh/handbook/tracks/governance/)

### 典型场景
```
DAO 成员："这周有 12 个提案，帮我理解关键分歧"
Agent →
  1. 拉取链上提案 + 论坛讨论（Web3 Indexing）
  2. 生成结构化摘要 + 主要争议点（AI 推理）
  3. 标注来源链接（可验证）
  4. 用户投票 → 链上记录 → Agent 追踪后续执行
```

---

## 两个方向的"为什么不是纯 AI / 纯 Web3"分析

### 方向二：Identity / Reputation（身份 / 声誉）

**为什么不是纯 AI 问题？**

AI 可以生成能力描述、从历史对话推断可信度，但这些判断：
- **无法抗篡改**：平台数据库里的声誉记录可以被平台修改或删除
- **无法跨平台迁移**：在 ChatGPT 上的对话记录，无法带到另一个服务使用
- **无法被第三方验证**：没有独立机构可以证明这个 Agent 真的完成了 2,000 次任务

AI 解决的是"理解和生成"问题，但解决不了"谁来背书、怎么让陌生人相信"的问题。

**为什么不是纯 Web3 问题？**

Web3 可以用链上地址做身份锚点，但：
- **没有语义**：0x 地址本身不能表达 Agent 能做什么、擅长什么
- **无法理解能力**：链上记录"完成了交易"，但不能判断这个 Agent 的任务质量
- **跨协议互操作复杂**：A2A 协议、ANS、DID 标准需要 AI 做翻译和适配层

Web3 解决的是"谁不可篡改地记录历史"问题，但解决不了"能力怎么描述、质量怎么评估"的问题。

**结论**：身份问题需要 AI 提供语义层（能力描述、质量推断），Web3 提供可信层（不可篡改记录、去中心化背书）。两者缺一不可。

---

### 方向四：Privacy / Security / Sovereignty（隐私 / 安全 / 主权）

**为什么不是纯 AI 问题？**

AI 有数据最小化原则、本地推理方案，但：
- **平台托管问题**：云端 AI 服务天然需要访问用户数据，单靠 AI 设计无法保证数据主权
- **无法自我证明**：AI 系统无法对外证明"我没有泄露你的数据"，需要可验证机制
- **审计依赖可信第三方**：传统 AI 审计需要信任平台自己的日志，无法独立核查

AI 能降低数据暴露面，但不能解决"谁来证明 AI 真的保护了隐私"的问题。

**为什么不是纯 Web3 问题？**

Web3 有公开账本和 ZK 证明，但：
- **链上数据天然公开**：所有交易记录默认可被任何人查询，隐私保护需要额外设计
- **无法理解威胁**：Prompt Injection、上下文污染、工具滥用是 AI 特有的攻击面，Web3 合约层无法防御
- **密码学工具难用**：ZK proof、TEE 对普通用户不透明，需要 AI 作为理解和操作的中间层

Web3 提供了密码学基础设施，但无法理解 AI 特有的攻击面。AI 能识别威胁，但无法自我证明安全性。

**结论**：隐私安全问题需要 AI 检测攻击面 + Web3 提供可验证证明，组合才能构建真正可信的系统。

---

## Week 2 主线方向选择

### 🎯 选定方向：Identity / Reputation / Capability / Interoperability

**理由**：

1. **产品视角最强**：这是一个典型的"用户看不见、但决定一切"的基础设施问题。对我作为 PM 来说，如何设计 Agent 的身份和声誉系统，是构建用户信任的核心。

2. **Hackathon 可落地**：可以快速做出一个最小可演示原型——比如一个 Agent 声誉注册表（链上存储 Agent 的 DID + 任务完成记录 + 评分），前端用 AI 展示能力摘要。

3. **与已有工作衔接**：Week 1 做了 ABI Explainer（合约交互理解工具），可以延伸为"Agent 展示自己能力的 proof"。每次成功解释一个合约，就在链上写一条能力记录。

4. **问题足够深**：DID + VC + 声誉积累 + 跨协议互操作，每一块都有值得拆解的技术细节，不会很快遇到瓶颈。

### 后续拆解方向

```
Week 2 主线：Agent Identity & Reputation

├── 概念拆解
│   ├── DID vs 传统账户体系的区别
│   ├── VC（可验证凭证）如何在链上锚定
│   └── A2A / ANS 协议的现状和局限
│
├── 案例研究
│   ├── Ceramic Network（去中心化身份存储）
│   ├── Lens Protocol（链上社交图谱）
│   └── Verifiable AI（如何给 Agent 输出加可验证戳记）
│
├── Proposal 草稿
│   ├── 问题定义：Agent 在跨平台协作中的身份信任问题
│   ├── 目标用户：需要委托 Agent 完成任务的普通用户
│   ├── 解法框架：链上声誉注册表 + AI 能力摘要生成
│   └── 最小 demo：Agent 完成任务 → 写入链上记录 → 前端展示声誉卡
│
└── 技术实验
    ├── 用 EAS（Ethereum Attestation Service）做声誉存证
    ├── 用 Vercel AI SDK 生成 Agent 能力描述
    └── 前端：能力卡展示 + 历史任务列表
```

---

## 问题地图总览（可视化索引）

```
AI × Web3 问题地图
│
├── Payment / Commerce / Settlement
│   AI：意图解析、报价协商、工作流编排
│   Web3：Session Key、托管合约、链上收据
│
├── Identity / Reputation / Capability ◀── 【Week 2 主线】
│   AI：能力描述、声誉推断、跨协议翻译
│   Web3：DID、VC、链上行为记录
│
├── Wallet / Permission / Safe Execution
│   AI：意图解析、风险评估、Human-in-the-loop 判断
│   Web3：Account Abstraction、Session Key、Policy Guard
│
├── Privacy / Security / Sovereignty
│   AI：本地推理、Prompt Injection 防御、审计分析
│   Web3：ZK 证明、链上审计日志、主权数据存储
│
├── Dev Tooling / Agent Workflow
│   AI：合约理解、测试生成、代码审查、流水线编排
│   Web3：链上状态作为上下文、交易模拟、MCP 工具链
│
└── Governance / Coordination / Public Goods
    AI：提案摘要、多方观点、预算追踪、协调建议
    Web3：链上提案存档、投票权重机制、DAO 执行层
```

---


**GitHub**：https://github.com/beetroot42/ai-web3-school-cohort-0/blob/main/submissions/week2-module-a-problem-map.md
