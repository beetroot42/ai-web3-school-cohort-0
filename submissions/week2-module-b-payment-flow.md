# Week 2 Module B — Agent 帮人完成任务并收款：最小 Payment / Commerce Flow

**作者**：beetroot42  
**日期**：2026-05-22  
**来源**：[AI × Web3 School Handbook — Settlement & Escrow](https://aiweb3.school/zh/handbook/bridge/settlement-and-escrow/) · [Agentic Commerce](https://aiweb3.school/zh/handbook/tracks/agentic-commerce/)  
**仓库**：https://github.com/beetroot42/ai-web3-school-cohort-0

---

## 场景选择：链上尽职调查报告生成服务

### 场景描述

> 用户需要对某个 DeFi 协议做投资前尽职调查（Due Diligence），但自己缺乏解读链上数据和合约代码的能力。
> 他委托一个专业 Agent（"链析 Agent"）完成：合约风险分析 + 链上资金流向梳理 + 一份结构化 PDF 报告。
> 报酬：10 USDC，交付截止：30 分钟，报告须通过格式和关键字段检查。

这个场景包含：
- **明确的任务边界**（报告要有哪些字段）
- **可验证的交付物**（PDF hash + 字段检查）
- **有争议空间**（报告质量主观判断）
- **时间约束**（超时退款）

---

## 角色定义

| 角色 | 实体 | 链上地址 / 标识 |
|------|------|----------------|
| **下单方（Client）** | 用户 Alice | `0xAlice...` — 持有 Smart Account（AA）|
| **执行方（Provider）** | 链析 Agent | `0xAgent...` — 持有 Session Key，已在 ERC-8004 Identity Registry 注册 |
| **验收方（Evaluator）** | 格式检查脚本 + Alice 本人（兜底） | 自动评估合约地址 `0xEval...` |
| **仲裁方（Arbitrator）** | DAO 多签或链上仲裁合约 | `0xArb...` — 仅 Dispute 状态触发 |
| **付款方** | Alice 的 Smart Account（锁入 Escrow 合约） | 触发条件满足后自动释放 |

---

## 完整流程设计（7 个阶段）

### 阶段 0：交易前准备

```
Alice 的 Smart Account 配置：
  Session Key 权限：
    - 每日限额：50 USDC
    - 可调用合约白名单：[Escrow 合约地址]
    - 有效期：7 天
    - 单笔 > 20 USDC 须推送确认

链析 Agent 已注册（ERC-8004）：
  agentId: #42
  agentURI: ipfs://Qm...（含能力描述 + 服务端点）
  声誉评分：94/100（来自 Reputation Registry）
  支持协议：A2A, MCP, x402
```

---

### 阶段 1：报价

**触发**：Alice 的 AI 助手发现链析 Agent 可以完成此任务。

**流程**：
```
Alice Assistant → 调用链析 Agent 的 A2A 端点
                → 发送任务描述（JSON）：
                  {
                    "task": "DeFi DD Report",
                    "target_protocol": "0xProtocol...",
                    "required_fields": ["risk_score", "fund_flow", "admin_key_analysis"],
                    "format": "PDF + structured JSON",
                    "deadline_minutes": 30
                  }

链析 Agent → 返回报价（Quote）：
              {
                "quote_id": "q-20260522-001",
                "price": "10 USDC",
                "currency": "USDC (Base chain)",
                "expires_in": "5 minutes",
                "delivery_guarantee": "30 min or full refund",
                "evaluator": "0xEval..."
              }
```

**Alice 确认**：检查报价超出单笔 20 USDC 阈值 → 推送通知 → Alice 手动确认。

---

### 阶段 2：预算授权

**触发**：Alice 确认报价。

**Payment Intent 结构**（链析 Agent 接收，Escrow 合约验证）：
```json
{
  "intent_id": "pi-20260522-001",
  "quote_id": "q-20260522-001",
  "payer": "0xAlice...",
  "provider": "0xAgent...",
  "evaluator": "0xEval...",
  "arbitrator": "0xArb...",
  "max_amount": "10 USDC",
  "asset": "USDC",
  "chain": "Base",
  "task_description_hash": "0xABC...",
  "acceptance_criteria": {
    "required_fields": ["risk_score", "fund_flow", "admin_key_analysis"],
    "format_check": true,
    "min_word_count": 500
  },
  "deadline": "2026-05-22T17:00:00+09:00",
  "refund_conditions": ["超时", "格式不符", "字段缺失"],
  "dispute_window_minutes": 10,
  "valid_until": "2026-05-22T16:35:00+09:00"
}
```

**链上动作**：Alice 的 Smart Account 调用 Escrow 合约：
```
createJob(
  provider = 0xAgent,
  evaluator = 0xEval,
  expiredAt = now + 30min,
  description = hash(PaymentIntent),
  hook = 0x0
)
→ 返回 jobId: #8183-001
→ 状态：Open

setBudget(jobId, 10 USDC)
→ 双方确认金额

fund(jobId, 10 USDC)
→ 10 USDC 从 Alice 钱包转入 Escrow 合约
→ 状态：Funded ✅
```

---

### 阶段 3：执行

**触发**：Escrow 合约状态变为 Funded，链析 Agent 监听到事件。

**执行步骤**（Agent 自主完成）：
```
链析 Agent：
  1. 读取目标协议合约（Web3 Tool Use → eth_call）
  2. 拉取 30 天资金流向（Indexing → The Graph）
  3. 分析 admin key 权限（合约 ABI 解析）
  4. 调用 PDF 生成服务（x402 支付，0.5 USDC，微支付）
  5. 生成结构化 JSON（risk_score, fund_flow, admin_key_analysis）
  6. 打包 PDF + JSON，上传至 IPFS
     → IPFS CID: QmReport...
     → SHA256: 0xRepHash...
```

**注意**：执行期间 Alice 无需介入，Agent 使用 Session Key 管理内部子支付。

---

### 阶段 4：交付

**触发**：链析 Agent 完成报告，发起 submit。

**链上动作**：
```
Provider 调用：
submit(
  jobId = #8183-001,
  deliverable = bytes32(keccak256("ipfs://QmReport..." + "0xRepHash..."))
)
→ 状态：Submitted ✅
→ 链上 event：JobSubmitted(jobId, deliverable, timestamp)
```

**同时发送给 Evaluator**：
```json
{
  "job_id": "#8183-001",
  "ipfs_cid": "QmReport...",
  "pdf_hash": "0xRepHash...",
  "json_fields": {
    "risk_score": 72,
    "fund_flow": {...},
    "admin_key_analysis": {...}
  },
  "delivery_time": "2026-05-22T16:52:00+09:00",
  "within_deadline": true
}
```

---

### 阶段 5：验收

**Evaluator 合约自动检查**（`0xEval...`）：

| 检查项 | 预期 | 结果 |
|--------|------|------|
| 字段完整性 | risk_score, fund_flow, admin_key_analysis | ✅ 全部存在 |
| PDF hash 匹配 | deliverable 与提交一致 | ✅ 匹配 |
| 格式检查 | PDF 可解析 + JSON 合法 | ✅ 通过 |
| 截止时间 | < 16:30 + 30min = 17:00 | ✅ 16:52 提交 |

**验收结论**：全部通过 → 进入自动完成路径。

**挑战窗口（Challenge Window）**：验收通过后，Alice 有 **10 分钟** 的人工复核窗口，可以发起 Dispute。

```
Alice 在 10 分钟内未发起挑战
→ Evaluator 自动调用：
  complete(jobId = #8183-001, reason = bytes32(keccak256("all checks passed")))
→ 状态：Completed ✅
```

---

### 阶段 6：付款

**触发**：Evaluator 调用 complete()。

**链上自动执行**：
```
Escrow 合约：
  → 10 USDC 从合约转至 Provider（0xAgent...）
  → 平台手续费（如有）：0 USDC（本场景无手续费）
  → 状态：Released ✅
```

**链上 Receipt 写入**：
```json
{
  "receipt_id": "rcpt-20260522-001",
  "job_id": "#8183-001",
  "payer": "0xAlice...",
  "provider": "0xAgent...",
  "amount": "10 USDC",
  "asset": "USDC",
  "chain": "Base",
  "tx_hash": "0xPayTx...",
  "deliverable_hash": "0xRepHash...",
  "completion_time": "2026-05-22T17:02:00+09:00",
  "status": "Completed",
  "evaluator": "0xEval..."
}
```

**声誉更新**（ERC-8004 Reputation Registry）：
```
Alice 的 Smart Account 调用 giveFeedback：
  agentId = 42,
  value = 95,
  tag1 = "DeFi-DD",
  proofOfPayment = { txHash: "0xPayTx..." }
```

---

### 阶段 6A（分支）：退款

**触发条件**：
- 超过截止时间（`block.timestamp >= expiredAt`）但未提交
- 格式检查失败（Evaluator 调用 reject）
- Alice 在挑战窗口内确认交付物不满足要求

**链上动作**：
```
触发路径一：超时
  → 任何人调用：claimRefund(jobId)
  → 10 USDC 退回 Alice
  → 状态：Expired

触发路径二：验收失败
  → Evaluator 调用：reject(jobId, reason = "missing admin_key_analysis field")
  → 10 USDC 退回 Alice
  → 状态：Rejected
```

---

### 阶段 6B（分支）：争议

**触发条件**：Alice 认为报告质量不达标（主观判断），在挑战窗口内提出异议。

**争议流程**：
```
1. Alice 调用争议合约，抵押 1 USDC（防止滥用）：
   raiseDispute(jobId, reason = "risk_score analysis incomplete")
   → 进入 Disputed 状态，10 USDC 继续锁定

2. 链析 Agent 提交反驳证据：
   submitCounter(jobId, evidence_ipfs_cid = "QmCounter...")

3. 仲裁合约（0xArb...）或 DAO 多签（3/5）：
   → 审查双方证据
   → 判决：部分履行 → 7 USDC 给 Agent，3 USDC 退 Alice
   → 或：全额退款 / 全额付款

4. 链上执行仲裁结果，写入 dispute 记录：
   { jobId, outcome, arbitrator, reason_hash, timestamp }

5. 争议记录同步至 ERC-8004 Reputation Registry：
   → 影响链析 Agent 的长期声誉评分
```

---

### 阶段 7：记录证明

所有关键操作均有链上痕迹：

| 时间点 | 链上证据 | 用途 |
|--------|---------|------|
| 下单 | `JobCreated` event，含任务 hash | 证明任务定义不可篡改 |
| 预算锁定 | `Funded` event + tx hash | 证明资金已托管 |
| 交付 | `JobSubmitted` event，含 deliverable bytes32 | 证明交付内容和时间 |
| 验收 | `complete()` tx，含 reason hash | 证明通过了哪些检查 |
| 付款 | ERC-20 Transfer event | 资金流向可查 |
| 声誉 | ERC-8004 `NewFeedback` event | 长期可用于 Agent 信用体系 |
| IPFS 报告 | CID + SHA256 hash | 交付物内容可验证 |

---

## 状态机总结

```
                    ┌─────────────────────────────────────┐
                    │         Escrow 状态机               │
                    └─────────────────────────────────────┘

  [Alice createJob]           [Alice / Evaluator]
        │                           │
        ▼                           │
      Open ──── reject ────────► Rejected
        │                     (退款 Alice)
        │ fund()
        ▼
     Funded ──── reject ────────► Rejected
        │      (Evaluator)         (退款 Alice)
        │
        │ submit()
        ▼       ────── 超时 ──────► Expired
    Submitted                    (退款 Alice)
        │
        ├─── complete() ─────────► Completed
        │    (Evaluator)            (付款 Agent)
        │
        └─── reject() ───────────► Rejected
             (Evaluator)           (退款 Alice)
```

---

## 加分项：协议比较 — x402 vs ERC-8183

### 它们分别解决哪一段？

```
完整流程：
报价 → 预算授权 → 执行 → 交付 → 验收 → 付款/退款/争议 → 记录证明
  │           │                    │              │
  └─ x402 ───┘                    └── ERC-8183 ──┘
   (支付触发层)                    (任务生命周期层)
```

---

### x402：解决「支付触发」段

**定位**：HTTP 层的机器支付协议（Payment 段）

**核心机制**：
1. Agent 向服务端发送 HTTP 请求
2. 服务端返回 `HTTP 402 Payment Required`，含支付参数
3. Agent 用链上稳定币完成支付
4. 服务端验证支付后，返回资源/服务

**在本场景中的位置**：
```
阶段 3（执行）：
链析 Agent 调用 PDF 生成服务
  → 收到 HTTP 402
  → 自动支付 0.5 USDC（通过 Session Key）
  → 服务返回 PDF
```

**x402 解决的核心问题**：
| 维度 | 解决方案 |
|------|---------|
| 注册摩擦 | 无需提前注册账号、KYC、充值 |
| API Key 管理 | 无需管理 API Key，支付即授权 |
| 小额支付 | 按请求付费，无需订阅 |
| 速度 | 链上支付完成即服务，无等待 |
| 中心化风险 | 无协议费用，基于链上结算 |

**局限性**：
- **不处理任务生命周期**：x402 只管"付了钱给资源"，不管"任务完成了没有、交付物是什么、失败怎么退款"
- **无验收逻辑**：服务给了响应就算完成，无法表达"条件满足才付款"
- **无争议机制**：如果服务给了错误响应，x402 无法处理退款或仲裁

**一句话定位**：x402 是 **支付触发器**，解决"Agent 怎么自动付钱"，不解决"钱应不应该付"。

---

### ERC-8183：解决「任务生命周期 + 结算」段

**定位**：链上 Job Escrow 标准（Settlement & Verification 段）

**核心机制**：
定义了一个完整的 **6 状态机**：
```
Open → Funded → Submitted → Completed
                          → Rejected
                          → Expired
```

三个角色（Client / Provider / Evaluator）对应不同的状态转移权限。

**在本场景中的位置**：
```
阶段 2（预算授权）：fund() → Funded
阶段 4（交付）：   submit() → Submitted
阶段 5（验收）：   complete() → Completed（或 reject()）
阶段 6（付款）：   escrow 自动释放 10 USDC
阶段 6A（退款）：  claimRefund() / reject()
```

**ERC-8183 解决的核心问题**：

| 维度 | 解决方案 |
|------|---------|
| 先付钱风险 | Escrow 托管，验收前不释放 |
| 先交付风险 | 资金已链上锁定，验收通过自动付 |
| 验收标准 | Evaluator 角色可以是合约（自动检查）|
| 超时退款 | expiredAt 到期任何人可触发 claimRefund |
| 争议 | reject() 带 reason，结合链上记录 |
| 可审计 | 每次状态变更都有链上 event |
| 与声誉系统组合 | reason 字段可作为 ERC-8004 feedback 的 hash 输入 |

**局限性**：
- **不解决如何发起支付**：只管"资金锁了之后怎么分配"，需要配合 x402 或 Session Key 完成初始付款
- **Evaluator 本身需要被信任**：如果 Evaluator 是 `evaluator = client`（Alice 自己），仍存在主观偏差
- **争议处理未标准化**：ERC-8183 的 reject 只做退款，复杂仲裁需要在 hook 扩展里实现

**一句话定位**：ERC-8183 是 **任务结算框架**，解决"资金什么时候、按什么条件、怎么分配给谁"，不解决"钱从哪里来"。

---

### 两者的互补关系

```
┌─────────────────────────────────────────────────────────────┐
│              完整 Agent Commerce 系统                        │
│                                                             │
│  x402                          ERC-8183                     │
│  ──────                        ────────                     │
│  • HTTP 层支付触发              • 链上任务生命周期管理         │
│  • 无摩擦 API 购买              • Escrow 托管 + 状态机        │
│  • 按请求付费                   • Evaluator 验收逻辑          │
│  • 不处理验收                   • 超时退款 / 争议处理          │
│  • 不处理争议                   • 可组合 hook 扩展             │
│                                                             │
│  → 在阶段 3 的子任务支付中使用    → 在阶段 2-6 的主任务托管中使用│
└─────────────────────────────────────────────────────────────┘

ERC-8004（身份 / 声誉）作为两者的上层基础设施：
  → 为 ERC-8183 的 Provider 提供可信身份验证
  → 把 x402 的支付记录作为 proofOfPayment 写入 feedback
```

---

## 最小可落地原型（Hackathon 方向）

基于本场景，可以快速实现的最小 demo：

```
前端（React + Wagmi）：
  1. 连接 Alice 的钱包（MetaMask）
  2. 输入任务需求（目标合约地址 + 截止时间）
  3. 展示 Agent 报价（从 A2A 端点拉取）
  4. 一键创建 Job + 预算锁定

合约（Solidity on Base Sepolia）：
  - 简化版 ERC-8183 Escrow（Open/Funded/Submitted/Completed/Rejected）
  - ERC-20 USDC 支持（测试币）
  - Evaluator = 固定脚本合约（检查 JSON 字段）

Agent（Python + Web3.py）：
  - 监听 JobFunded 事件
  - 执行分析任务（模拟）
  - 上传结果到 IPFS
  - 调用 submit()

展示：
  - 链上状态机实时展示
  - Receipt 可读版本
  - 声誉写入演示（ERC-8004 Reputation Registry 调用）
```

---

## 核心洞察

> **Agentic Commerce 的根本问题不是"AI 会花钱"，而是"钱应该在什么条件下从哪里流向哪里"。**

1. **状态机先于代码**：Escrow 设计的第一步是定义状态机（谁能触发、需要什么证据、超时怎么处理），而不是先写付款代码。
2. **验收是最难的部分**：AI 可以做初步判断，但高价值或主观任务必须有 challenge window + 人工兜底。
3. **x402 + ERC-8183 是互补的**：前者解决了"如何触发支付"，后者解决了"支付的条件和时机"。单独使用任何一个都不完整。
4. **Receipt 不只是收据**：它是声誉系统的输入、争议系统的证据、审计系统的基础。

