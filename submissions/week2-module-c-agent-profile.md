# Week 2 Module C — Agent Profile 设计与协议比较

**作者**：beetroot42  
**日期**：2026-05-29  
**来源**：[Agent Identity](https://aiweb3.school/zh/handbook/bridge/agent-identity/) · [Agent Trust & Reputation](https://aiweb3.school/zh/handbook/bridge/agent-trust-and-reputation/) · [MCP](https://aiweb3.school/zh/handbook/ai/mcp/)  
**仓库**：https://github.com/beetroot42/ai-web3-school-cohort-0

---

## 一、选定 Agent：链析 Agent

> 延续 Week 2 主线方向（Identity / Reputation），选取 Module B 场景中设计过的「链析 Agent」，
> 本次从 identity、capability、协作关系、失败处理等维度做完整 profile 拆解。

---

## 二、Agent Identity 拆解

### 2.1 它是谁

| 字段 | 内容 |
|------|------|
| **名称** | 链析 Agent（ChainAnalyzer-v1） |
| **Agent ID** | `eip155:8453:0xIdentityRegistry...` / `agentId: #42`（ERC-8004 Base 链注册）|
| **版本** | `v1.2.0` |
| **描述** | 专注链上数据分析与 DeFi 尽职调查的付费 AI Agent。输入目标合约地址，输出结构化风险报告（合约风险评分、资金流向图、管理员权限分析）。|
| **创建时间** | `2026-03-01` |
| **Profile URI** | `ipfs://QmAgentProfile42...`（IPFS 存储，owner 签名更新）|

---

### 2.2 由谁维护
| 角色 | 地址 / 说明 |
|------|------------|
| **Owner** | `0xBeetroot42MultiSig...`（3/5 多签，控制身份更新和收款地址变更）|
| **Operator** | `0xOperatorHotWallet...`（日常服务运维，不持有 profile 更新权）|
| **争议联系** | `dispute@chainanalyzer.agent`（24h 响应 SLA）|

**信任设计**：Owner 和 Operator 分离。升级合约、修改收款地址、增加高风险能力，必须由 3/5 多签触发并在链上留下可验证记录，普通运维操作由 Operator 单独热钱包执行。

---

### 2.3 能力清单

#### Capability 1：合约风险分析

| 维度 | 内容 |
|------|------|
| **描述** | 分析智能合约的管理员权限、可升级性、外部依赖和历史漏洞模式 |
| **风险等级** | 中风险（只读，不执行链上写操作）|
| **输入** | `{ "contract_address": "0x...", "chain_id": 1 }` |
| **输出** | `{ "risk_score": 0-100, "admin_key_risks": [...], "upgradeability": "proxy/immutable", "known_vulnerabilities": [...] }` |
| **价格** | `3 USDC / 次` |
| **执行时间** | 最长 5 分钟 |
| **失败退款** | 超时或异常自动退款，链上 Escrow 状态变 `Rejected` |
| **权限要求** | 无需钱包签名，只读 RPC 调用 |

#### Capability 2：资金流向追踪
| 维度 | 内容 |
|------|------|
| **描述** | 追踪目标地址过去 N 天内的资金流入/流出，标记混币器、可疑地址和异常转账 |
| **风险等级** | 中风险（只读）|
| **输入** | `{ "address": "0x...", "chain_id": 1, "days": 30 }` |
| **输出** | `{ "total_in": "...", "total_out": "...", "flagged_counterparties": [...], "flow_graph_ipfs_cid": "Qm..." }` |
| **价格** | `2 USDC / 次`（30 天数据），超过 90 天 `+1 USDC` |
| **执行时间** | 最长 8 分钟 |
| **数据来源** | The Graph 子图 + Etherscan API（x402 付费调用）|
| **权限要求** | 无需钱包签名 |

#### Capability 3：完整尽调报告
| 维度 | 内容 |
|------|------|
| **描述** | 组合 Capability 1 + 2 + 代币经济分析，生成结构化 PDF + JSON 报告 |
| **风险等级** | 中风险（只读 + 付费子调用）|
| **输入** | `{ "target_protocol": "0x...", "chain_id": 1, "required_fields": [...], "format": "pdf+json" }` |
| **输出** | `{ "report_ipfs_cid": "Qm...", "report_hash": "0x...", "json_summary": {...} }` |
| **价格** | `10 USDC / 次` |
| **执行时间** | 最长 30 分钟，含 challenge window |
| **失败退款** | ERC-8183 Escrow 合约托管；超时或字段缺失触发 `claimRefund()` |
| **人工兜底** | 验收合约自动检查字段；争议窗口 10 分钟内 Alice 可发起 dispute |

---

### 2.4 如何被调用
```
调用流程（以 Full DD Report 为例）：

1. 发现入口（Discovery）
   方式A：ERC-8004 Identity Registry 查询 agentId #42
           → 解析 agentURI → 获取 Profile JSON
   方式B：A2A Well-Known 端点
           https://chainanalyzer.agent/.well-known/agent-card.json

2. 协商任务（Negotiation）
   调用方 → POST https://api.chainanalyzer.agent/v1/quote
   Request Body：
   {
     "capability": "full_dd_report",
     "target_protocol": "0xProtocol...",
     "required_fields": ["risk_score", "fund_flow", "admin_key_analysis"],
     "chain_id": 1
   }
   Response：
   {
     "quote_id": "q-001",
     "price": "10 USDC",
     "expires_in": 300,
     "evaluator": "0xEval...",
     "escrow_contract": "0xEscrow..."
   }

3. 预算锁定（Budget Lock）
   调用方的 Smart Account → fund() via ERC-8183 Escrow
   10 USDC 锁入合约，状态：Funded

4. 执行与交付（Execute & Deliver）
   链析 Agent 监听 JobFunded 事件 → 开始执行
   → submit(jobId, deliverable_hash)

5. 验收与结算（Accept & Settle）
   Evaluator 合约检查字段 → complete() → 10 USDC 释放
```

**支持的协议接口**：

| 协议 | 端点 | 用途 |
|------|------|------|
| A2A | `https://chainanalyzer.agent/.well-known/agent-card.json` | Agent 发现与任务协商 |
| MCP | `https://mcp.chainanalyzer.agent/` | 工具调用（读链上数据、生成报告） |
| REST | `https://api.chainanalyzer.agent/v1/` | 传统客户端集成 |
| x402 | 内置（服务商作为消费方使用）| 子任务支付（The Graph API 等）|

---

### 2.5 如何收费

| 收费项 | 金额 | 结算方式 |
|--------|------|---------|
| 合约风险分析 | 3 USDC | x402 按请求付款（HTTP 402 流程）|
| 资金流追踪 | 2–3 USDC | x402 按请求付款 |
| 完整尽调报告 | 10 USDC | ERC-8183 Escrow 托管，验收后释放 |
| 订阅套餐（可选）| 50 USDC / 月 | ERC-20 approve + 自动扣费 |

**收款地址**：`0xAgentWallet...`（记录于 ERC-8004 `agentWallet` 字段，变更需 owner 多签 + EIP-712 签名）

**退款政策**：
- 超时 → 自动 `claimRefund()`，100% 退回
- 字段缺失 → Evaluator `reject()`，100% 退回
- 质量争议 → DAO 仲裁，比例退款（结果记入链上声誉）

---

### 2.6 如何被验证
**三层验证体系**：

```
第一层：身份验证（Who is this?）
  ERC-8004 Identity Registry
  → agentId #42 的 owner 是 0xBeetroot42MultiSig
  → agentURI 指向 Profile JSON（IPFS CID 验证内容完整性）
  → 域名控制权：.well-known/agent-registration.json 包含 agentId #42

第二层：能力验证（Can it do what it claims?）
  ERC-8004 Validation Registry
  → 链析 Agent 主动调用 validationRequest()，请求第三方验证器验证：
    "能否在 5 分钟内分析一个已知漏洞合约（Parity Multisig 事件）"
  → 验证器返回 validationResponse(response=95/100)
  → 结果链上可查

第三层：声誉验证（Has it done well before?）
  ERC-8004 Reputation Registry
  → 历史任务完成率：98.2%（链上 feedback 聚合）
  → 平均评分：94/100
  → dispute 记录：2 次（均最终仲裁判 Agent 胜）
  → 最近 90 天无 0-分评价
```

**可验证凭证（VC）**：
- `{issuer: "ETHPanda Security Lab", claim: "通过 2026-Q1 DeFi 分析能力测试", expires: "2027-01-01"}`
- VC hash 存储于 Profile JSON，由 issuer 公钥可验证

---

### 2.7 协作对象

```
链析 Agent 的协作网络：

  用户 Alice（Client）
      │ 委托任务 + 付款
      ▼
  链析 Agent（ChainAnalyzer）
      │
      ├── The Graph API（数据源，x402 付费）
      │     → 链上事件索引、Token 转账历史
      │
      ├── 第三方 PDF 生成服务（子服务，x402 付费）
      │     → 结构化报告渲染
      │
      ├── Evaluator 合约（验收方）
      │     → 自动检查输出字段完整性
      │
      └── DAO 仲裁合约（争议仲裁方，按需触发）
            → 多签仲裁，结果写入声誉系统
```

**数据流向**：
- 链析 Agent 调用 The Graph 时，**不暴露用户 Alice 的身份**（请求中只含目标合约地址）
- 生成的报告上传至 IPFS，只向 Alice 提供 CID，**内容不公开**（IPFS 内容寻址，知道 CID 才能访问）

---

### 2.8 失败点与处理
| 失败场景 | 概率 | 影响 | 处理机制 |
|----------|------|------|---------|
| The Graph API 不可用 | 低 | 任务无法完成 | 自动降级：切换 Etherscan 直查；超时触发 `claimRefund()` |
| 模型幻觉导致虚假风险评分 | 中 | 错误报告，可能误导决策 | Evaluator 只检查格式不检查内容；challenge window 让 Alice 人工复核 |
| 执行超过 30 分钟 | 低 | 超时退款 | Escrow `expiredAt` 强制触发 `claimRefund()`，Agent 信誉受损 |
| Evaluator 合约 bug | 极低 | 错误验收或错误拒绝 | Evaluator 版本记录在声誉系统；bug 被发现后 Owner 多签升级 |
| 服务端被 Prompt Injection | 中 | 数据泄露 / 恶意输出 | 输入验证 + 系统 Prompt 隔离；工具调用结果先进 sandbox 再写入上下文 |
| Owner 私钥丢失 | 极低 | 无法更新 profile 或收款 | 多签设计（3/5），单私钥丢失不影响操作 |
| 声誉被刷好评（Sybil 攻击）| 中 | 声誉失真 | ERC-8004 要求 `getSummary()` 时必须指定 `clientAddresses`，过滤机器刷分 |

---

## 三、Agent Profile JSON 草稿（机器可读）

基于 ERC-8004 规范格式：

```json
{
  "type": "https://eips.ethereum.org/EIPS/eip-8004#registration-v1",
  "name": "ChainAnalyzer-v1",
  "description": "A paid AI agent specialized in on-chain DeFi due diligence. Inputs a contract/protocol address, outputs structured risk reports including contract risk scoring, fund flow tracing, and admin key analysis.",
  "image": "ipfs://QmAgentLogo42...",
  "version": "1.2.0",
  "owner": "0xBeetroot42MultiSig...",
  "operator": "0xOperatorHotWallet...",
  "contact": "dispute@chainanalyzer.agent",
  "services": [
    {
      "name": "A2A",
      "endpoint": "https://chainanalyzer.agent/.well-known/agent-card.json",
      "version": "0.3.0"
    },
    {
      "name": "MCP",
      "endpoint": "https://mcp.chainanalyzer.agent/",
      "version": "2025-06-18"
    },
    {
      "name": "web",
      "endpoint": "https://chainanalyzer.agent/"
    }
  ],
  "capabilities": [
    {
      "id": "contract_risk_analysis",
      "description": "Analyze smart contract admin keys, upgradeability, and vulnerability patterns",
      "risk_level": "read-only",
      "input_schema": { "contract_address": "string", "chain_id": "integer" },
      "output_schema": { "risk_score": "integer", "admin_key_risks": "array", "known_vulnerabilities": "array" },
      "price": "3 USDC",
      "max_execution_time": "5m",
      "refund_policy": "full_refund_on_timeout"
    },
    {
      "id": "fund_flow_tracing",
      "description": "Trace fund flows for an address over a specified period, flagging mixers and suspicious counterparties",
      "risk_level": "read-only",
      "input_schema": { "address": "string", "chain_id": "integer", "days": "integer" },
      "output_schema": { "total_in": "string", "total_out": "string", "flagged_counterparties": "array", "flow_graph_ipfs_cid": "string" },
      "price": "2 USDC",
      "max_execution_time": "8m",
      "refund_policy": "full_refund_on_timeout"
    },
    {
      "id": "full_dd_report",
      "description": "Full due diligence report combining contract risk, fund flow, and tokenomics analysis",
      "risk_level": "read-only",
      "input_schema": { "target_protocol": "string", "chain_id": "integer", "required_fields": "array" },
      "output_schema": { "report_ipfs_cid": "string", "report_hash": "string", "json_summary": "object" },
      "price": "10 USDC",
      "max_execution_time": "30m",
      "settlement": "ERC-8183 Escrow",
      "evaluator_contract": "0xEval...",
      "challenge_window": "10m",
      "arbitrator": "0xArb...",
      "refund_policy": "full_refund_on_timeout_or_missing_fields"
    }
  ],
  "x402Support": true,
  "payment_assets": [
    { "token": "USDC", "chain_id": 8453, "address": "0x833589fCD6Edb6E08f4c7C32D4f71b54bda02913" }
  ],
  "active": true,
  "registrations": [
    { "agentId": 42, "agentRegistry": "eip155:8453:0xIdentityRegistry..." }
  ],
  "supportedTrust": ["reputation", "crypto-economic", "vc-attestation"],
  "verifiable_credentials": [
    {
      "issuer": "ETHPanda Security Lab",
      "claim": "Passed DeFi Analysis Capability Test Q1-2026",
      "issued_at": "2026-03-15",
      "expires": "2027-01-01",
      "vc_hash": "0xVCHash..."
    }
  ]
}
```

---

## 四、加分项：MCP vs A2A 协议比较

### 它们分别解决哪类问题？

```
完整协作链：

  发现 → 身份验证 → 能力查询 → 任务下发 → 工具调用 → 结果返回 → 支付
    │                               │              │
    └──── A2A ──────────────────────┘              │
                                         MCP ──────┘
```

---

### MCP：解决「模型 ↔ 工具 / 资源」的调用标准化问题

**全称**：Model Context Protocol（模型上下文协议）

**核心定位**：标准化 LLM 与**本地或远程工具、数据源、上下文**之间的调用接口。

**解决什么问题**：

在没有 MCP 之前，每个 AI 应用都要自己实现"如何让模型调用工具"：
- 自定义 function calling schema
- 自己实现 RPC 调用序列化
- 每接入一个新工具就要写新的适配代码

MCP 提供了统一的三类接口：
- **Tools**：Agent 可主动调用的函数（如 `read_contract_abi(address)`）
- **Resources**：Agent 可读取的数据（如 `chain://base/tx/0x...`）
- **Prompts**：可复用的 prompt 模板

**在链析 Agent 中的位置**：

```
Alice 的 AI 助手（LLM）
  ↓ 通过 MCP 协议调用工具
链析 Agent 的 MCP Server（mcp.chainanalyzer.agent）
  提供以下 Tools：
    - analyze_contract(address, chain_id)
    - trace_fund_flow(address, days)
    - generate_dd_report(protocol, fields)
  提供以下 Resources：
    - chain://base/contract/{address}/abi
    - chain://base/address/{address}/transactions
```

**局限性**：
- MCP 是工具调用协议，**不涉及身份验证**（谁调用这个工具？）
- **不涉及支付**（调用工具后怎么结算费用？）
- **不处理多 Agent 协作**（Agent A 如何委托 Agent B？）

**一句话定位**：MCP 解决的是「模型如何用标准化方式调用外部能力」，是 Agent 的**工具箱标准接口**。

---

### A2A：解决「Agent ↔ Agent」跨平台协作与任务委托问题

**全称**：Agent2Agent Protocol（Google 主导的开放协议）

**核心定位**：标准化 **Agent 之间**的发现、认证、能力查询、任务委托和结果交换。

**解决什么问题**：

当 Alice 的 AI 助手（消费方 Agent）想委托链析 Agent（服务方 Agent）完成任务时，需要解决：
- 如何找到链析 Agent？（Discovery）
- 如何知道它能做什么？（Capability Negotiation）
- 如何下达任务、同步状态？（Task Lifecycle）
- 任务完成后结果如何返回？（Result Exchange）

**A2A 的关键组件**：

| 组件 | 作用 |
|------|------|
| **AgentCard** | 机器可读的 Agent 自我介绍（`.well-known/agent-card.json`）|
| **Task** | 标准化的任务对象，有 ID、状态、输入输出字段 |
| **Skills** | Agent 能力列表，每个 Skill 有 name、description、input/output schema |
| **Authentication** | Agent 间相互验证身份（JWT / DID 签名）|

**在链析 Agent 中的位置**：

```
Alice 的 AI 助手（消费方 Agent）
  ↓ GET /.well-known/agent-card.json
链析 Agent 的 AgentCard
  ↓ 解析 Skills，发现 full_dd_report Skill
Alice 的 AI 助手
  ↓ POST /tasks（A2A Task 格式，含任务 ID、输入参数）
链析 Agent
  ↓ 接受任务 → 执行 → 返回任务状态更新
  ↓ 最终返回 { taskId, status: "completed", artifacts: [{ type: "file", url: "ipfs://Qm..." }] }
```

**局限性**：
- A2A 处理任务协作，**不内置支付**（任务完成后用什么协议结算？需要 ERC-8183 或 x402）
- **不提供链上身份绑定**（A2A 的 AgentCard 是 Web2 端点，需配合 ERC-8004 做链上锚定）
- 协议本身不限制 Agent 乱发任务，**无预算控制**

**一句话定位**：A2A 解决的是「Agent 如何以标准化方式找到、沟通和委托另一个 Agent」，是 Agent 的**协作通信协议**。

---

### MCP vs A2A：对比总结

| 维度 | MCP | A2A |
|------|-----|-----|
| **连接层** | 模型 ↔ 工具/资源 | Agent ↔ Agent |
| **解决的问题** | 工具调用标准化 | 跨 Agent 任务委托 |
| **发现机制** | MCP Server 注册工具列表 | AgentCard（`.well-known/agent-card.json`）|
| **任务状态** | 无（单次工具调用）| 有（Task 对象有完整生命周期）|
| **身份验证** | 无内置（依赖 transport 层）| 有（Agent 级 auth token）|
| **支付** | 无 | 无（需配合 x402 / ERC-8183）|
| **最适合场景** | 模型调单个工具（读链上数据、生成报告）| 一个 Agent 委托另一个 Agent 完整任务 |
| **在链析 Agent 的位置** | Alice 的助手通过 MCP 调用链析工具函数 | Alice 的助手通过 A2A 委托链析完成整个尽调任务 |

---

### 关键洞察：两者互补而非替代

```
完整调用链中 MCP 和 A2A 的分工：

Alice 的 AI 助手
  │
  ├── A2A：发现链析 Agent → 协商任务 → 委托全报告 → 接收结果
  │
  └── 链析 Agent 内部
          │
          └── MCP：调用 The Graph 工具 → 调用 ABI 解析工具 → 调用 PDF 生成工具
```

> **类比**：A2A 是"公司之间签合同、分工协作"，MCP 是"公司内部员工使用标准化办公工具"。
> 两者都必要，但面向不同的调用层级。

---

## 五、总结

| 设计维度 | 链析 Agent 的解决方案 |
|----------|-------------------|
| **身份** | ERC-8004 Identity Registry（链上锚定 + DID 可解析）|
| **能力描述** | Profile JSON + AgentCard（机器可读，含输入输出 schema）|
| **调用入口** | MCP（工具调用）+ A2A（任务委托）+ REST（传统集成）|
| **收费机制** | x402（小额按请求）+ ERC-8183 Escrow（大额条件结算）|
| **验证体系** | 三层：身份（ERC-8004）+ 能力（Validation Registry）+ 声誉（Reputation Registry）|
| **失败处理** | 超时自动退款 + Evaluator 自动拒绝 + DAO 仲裁兜底 |
| **协作协议** | A2A 发现与委托 + MCP 工具调用，互补不替代 |

**GitHub**：https://github.com/beetroot42/ai-web3-school-cohort-0/blob/main/submissions/week2-module-c-agent-profile.md
