# Week 2 Module D — Agent 发起链上动作的执行流程与权限策略设计

**作者**：beetroot42  
**日期**：2026-05-29  
**来源**：[Agent Wallet](https://aiweb3.school/zh/handbook/bridge/agent-wallet/) · [Wallet/Permission](https://aiweb3.school/zh/handbook/tracks/wallet-permission/) · [Account Abstraction](https://aiweb3.school/zh/handbook/web3/account-abstraction/)  
**仓库**：https://github.com/beetroot42/ai-web3-school-cohort-0

---

## 一、执行流程图：Agent 发起链上动作

### 1.1 完整流程（可自动 vs 必须人工确认）

```
用户设置阶段（一次性，人工完成）
────────────────────────────────────
[人工] 用户配置 Session Key 权限策略
       ↓ 定义：预算 / 白名单合约 / 允许方法 / 时间窗口
[人工] 用户用主钱包签名激活 Smart Account（ERC-4337）
       ↓ Session Key 写入链上
────────────────────────────────────

运行时阶段（Agent 自主执行或请求人工）
────────────────────────────────────
Step 1 [自动] Agent 读取链上状态
        └─ eth_call / The Graph 查询（只读，无签名）

Step 2 [自动] Agent 生成交易意图（候选 UserOperation）
        └─ 构造 calldata：to / value / data / gasLimit

Step 3 [自动] 交易前模拟（Simulation）
        ├─ 调用 Tenderly Simulation API
        ├─ 检查：token 余额变化 / 授权变化 / revert 原因
        └─ 结果：通过 → Step 4；失败 → 记录日志 + 告警

Step 4 [自动/人工判断] Guard 策略校验
        ├─ 目标地址在白名单？        ✓ → 继续
        ├─ 方法在允许列表？          ✓ → 继续
        ├─ 单笔金额 ≤ 阈值（5 USDC）？✓ → 继续
        ├─ 今日累计未超日限？        ✓ → 继续
        └─ 任一不满足 → 进入分支：
              ├─ 轻微越界（金额 > 5 USDC 但 < 20 USDC）→ [人工确认]
              └─ 严重越界（地址不在白名单 / 方法不允许）→ 直接拒绝

Step 5 ┌─ [自动] 小额 / 白名单 / 低风险
        │    └─ Session Key 自动签名 UserOperation
        │    └─ 跳至 Step 6
        └─ [人工确认] 中高风险
             └─ 推送通知：资产变化预览 + 风险说明
             └─ 用户确认 → Step 6 / 用户拒绝 → 记录并终止

Step 6 [自动] Bundler 打包 UserOperation 并提交 EntryPoint

Step 7 [自动] EntryPoint 调用 Smart Account 执行交易
        └─ Paymaster（可选）代付 gas

Step 8 [自动] 监听交易结果
        ├─ 成功 → 写入审计日志 + 更新累计预算
        └─ 失败 → 记录 revert reason + 告警 + 触发失败处理流程

Step 9 [自动] 日志写入（链上 Event + 链下数据库）
────────────────────────────────────
```

### 1.2 风险等级与确认策略对照表

| 操作类型 | 示例 | 风险等级 | 确认方式 |
|----------|------|---------|---------|
| 只读查询 | `balanceOf` / `eth_call` | 无风险 | 全自动 |
| 小额稳定币转账 | 0.5 USDC x402 支付 | 低风险 | Session Key 自动签名 |
| 中额 ERC-183 资金锁定 | fund() 10 USDC | 中风险 | 推送通知 + 用户确认 |
| 批准授权（approve） | USDC approve() | 中风险 | 必须展示额度 + 人工确认 |
| 大额转账 | > 20 USDC 任意转账 | 高风险 | 人工确认 + 模拟预览 |
| 任意地址转账 | 收款方不在白名单 | 高风险 | 直接 Guard 拒绝 |
| 合约升级 / 权限变更 | Ownable.transferOwnership | 极高风险 | 多签确认（Safe）|

---

## 二、链析 Agent Wallet 权限策略设计

**场景**：Alice 授权链析 Agent 在执行分析任务时，自动支付小额 API 费用和锁定任务 Escrow 资金。

### 2.1 Session Key 配置（完整 Policy）

```yaml
session_key:
  id: "sk-chainanalyzer-20260529"
  agent_address: "0xAgentSessionKey..."
  smart_account: "0xAliceSmartAccount..."
  chain_id: 8453  # Base Chain

  # 1. 预算控制
  budget:
    limit_per_tx: "0.5 USDC"         # 单笔上限（x402 API 调用）
    limit_per_day: "5.0 USDC"        # 日限（防死循环）
    limit_total: "35.0 USDC"         # 总额度（7 天上限）
    auto_pause_on_exceed: true        # 超限自动暂停，不报错继续

  # 2. 可调用合约白名单
  allowed_contracts:
    - address: "0xEscrowContract..."      # ERC-8183 Escrow
      label: "ChainAnalyzer Escrow"
    - address: "0x833589fCD6Edb6E08..."   # USDC on Base
      label: "USDC Token"
    - address: "0xDappRadarPaywall..."    # DappRadar x402 收款
      label: "DappRadar Paywall"
    - address: "0xGraphProtocol..."      # The Graph 查询付款
      label: "The Graph API"

  # 3. 可执行动作（函数级别白名单）
  allowed_methods:
    - contract: "USDC"
      methods:
        - "transfer(address,uint256)"    # 允许：定向转账
      forbidden:
        - "approve(address,uint256)"     # 禁止：任意 approve（防无限授权）
    - contract: "EscrowContract"
      methods:
        - "fund(uint256,uint256)"        # 允许：锁定资金
        - "claimRefund(uint256)"         # 允许：申请退款
      forbidden:
        - "complete(uint256,bytes32)"    # 禁止：Agent 不能自行完成验收
        - "reject(uint256,bytes32)"      # 禁止：Agent 不能自行拒绝

  # 4. 人工确认阈值
  human_confirmation_threshold:
    single_tx_above: "5.0 USDC"        # 单笔超 5 USDC 需推送确认
    daily_usage_above: "80%"           # 日额度使用超 80% 告警
    new_recipient: true                 # 收款方不在白名单，必须人工确认
    approve_any: true                   # 任何 approve 操作必须人工确认

  # 5. 撤销方式
  revocation:
    user_manual: true                   # 用户随时可在 Dashboard 一键撤销
    auto_expire: "2026-06-05T00:00:00Z" # 7 天到期自动失效
    auto_revoke_triggers:
      - condition: "3 consecutive failures"
        action: "pause_session_key"
      - condition: "unknown_recipient_detected"
        action: "freeze_and_notify"
      - condition: "daily_budget_exceeded"
        action: "pause_until_next_day"

  # 6. 日志记录
  audit_log:
    on_chain:
      - event: "UserOperationEvent"       # EntryPoint 每次执行记录
      - event: "Transfer"                 # ERC-20 转账 log
      - event: "JobFunded"                # Escrow 资金锁定 log
    off_chain:
      storage: "https://log.chainanalyzer.agent/"
      fields:
        - timestamp
        - agent_address
        - tx_hash
        - operation_type
        - amount
        - recipient
        - policy_rule_triggered
        - simulation_result
        - user_confirmation_status
    retention: "180 days"

  # 7. 失败处理
  failure_handling:
    simulation_fail:
      action: "abort_and_log"            # 模拟失败直接放弃，不广播
      notify_user: true
    guard_reject:
      action: "log_and_notify"           # Guard 拒绝时记录原因，通知用户
      notify_message: "操作被策略拦截：{reason}"
    tx_revert:
      action: "log_revert_reason"        # 链上失败时记录 revert 原因
      retry_policy: "no_auto_retry"      # 不自动重试（防止资金二次消耗）
      notify_user: true
    consecutive_failures:
      threshold: 3
      action: "pause_session_key_24h"    # 连续 3 次失败，冻结 24 小时
```

### 2.2 权限策略可视化摘要

```
                    链析 Agent Session Key 权限边界
┌─────────────────────────────────────────────────────────┐
│  可自动执行（无需用户介入）                               │
│  ✓ USDC transfer ≤ 0.5 USDC → DappRadar / The Graph    │
│  ✓ Escrow fund() ≤ 5 USDC                              │
│  ✓ Escrow claimRefund()（超时自动退款）                  │
├─────────────────────────────────────────────────────────┤
│  需推送通知 + 用户确认                                    │
│  ⚠ 任何单笔 > 5 USDC                                   │
│  ⚠ 日累计使用 > 80%                                    │
│  ⚠ 收款方不在白名单                                     │
├─────────────────────────────────────────────────────────┤
│  Guard 直接拒绝（不进入确认流程）                         │
│  ✗ approve() 任意合约任意额度                           │
│  ✗ 调用非白名单合约                                     │
│  ✗ 调用非白名单方法（如 complete / reject）              │
│  ✗ 转账至任意外部地址                                   │
│  ✗ Session Key 已过期或已撤销                           │
└─────────────────────────────────────────────────────────┘
```

---

## 三、ERC-4337 / Safe / Guard / Policy 的作用与风险边界

### 3.1 它们解决的是"谁的问题"？

```
普通 EOA 钱包的风险模型：
  私钥 = 全部权限
  → Agent 拿到私钥 = Agent 可以做任何事
  → 没有防御层，出错不可撤销

引入 ERC-4337 + Safe + Guard/Policy 后：
  私钥        → 只用于激活 Smart Account，平时不动
  Session Key → Agent 拿到的是受限能力，而非全部控制权
  Guard       → 每笔交易发出前额外过一道确定性规则检查
  Policy      → 定义 Guard 检查的规则集合，系统可执行
```

---

### 3.2 ERC-4337（账户抽象）

**解决的核心问题**：EOA 账户权限太粗，无法表达"只允许 Agent 做某些事"。

**传统 EOA 的问题**：
- 私钥签名 = 账户全部权限，无法限制合约、金额或方法
- 每次操作必须消耗原生 ETH 支付 gas
- 不支持批量执行、社交恢复、自动化规则

**ERC-4337 引入的关键组件**：

| 组件 | 作用 |
|------|------|
| **UserOperation** | 意图对象，包含 sender / calldata / signature，由 Agent 生成 |
| **Smart Account** | 合约账户，自定义验证逻辑（谁能签名、什么条件允许）|
| **Bundler** | 收集 UserOperation，打包提交 EntryPoint |
| **EntryPoint** | 中心化执行合约，调用 Smart Account 验证 + 执行 |
| **Paymaster** | 可选，代 Agent 付 gas（用 USDC 替代 ETH）|
| **Session Key** | 有限权限的临时签名密钥，由 Smart Account 校验规则 |

**对 Agent 场景的意义**：
> Agent 不再需要持有用户主私钥，只需要一把 Session Key。Smart Account 在链上合约层面强制执行权限边界，即使 Agent 被黑客控制、模型产生幻觉或代码 bug，越界操作也无法通过 Smart Account 的验证。

**解决的风险类型**：
- Agent 代码 bug 导致错误转账
- 模型幻觉生成高风险交易
- 私钥泄露导致全部资产损失

---

### 3.3 Safe（多签智能账户）

**解决的核心问题**：高价值场景下，单个热钱包或单个 Agent 不应独占执行权。

**Safe 的核心能力**：
- **多签（M-of-N）**：大额操作需要多个私钥持有人同意
- **模块系统（Modules）**：插件式扩展自动化能力（如限额模块、时间锁模块）
- **Guard 接口**：所有交易在执行前和执行后都会调用 Guard 合约检查

**在 Agent 场景中的价值**：
```
链析 Agent 的权限层级：

高风险操作（合约升级 / 大额转账）
  └─ Safe 3/5 多签（Owner + 团队成员）确认后执行

中等操作（Escrow fund > 20 USDC）
  └─ Safe 1/3 轻量多签（用户主账号）确认

低风险自动化（API 微支付 ≤ 5 USDC）
  └─ Safe Module（如 Allowance Module）限额自动执行，无需多签
```

**解决的风险类型**：
- 单点控制（Single Point of Failure）
- Agent 失控后单方面转移大额资产
- 团队内部操作无留存记录

---

### 3.4 Guard / Policy 机制

**解决的核心问题**：AI 生成的交易不可信，需要在执行前过一道"确定性规则检查"。

**Guard 的工作原理**：

```
Safe Guard 的调用时机：

交易进入 Safe
  │
  ├─ [执行前] checkTransaction()
  │    └─ 检查：目标地址 / calldata / value / gas
  │    └─ 不通过 → revert，交易不执行
  │
  ├─ Safe 执行交易（如果通过）
  │
  └─ [执行后] checkAfterExecution()
       └─ 检查：状态变化是否在预期范围内
       └─ 可用于审计和异常检测
```

**Policy 的本质**：
Guard 检查的是策略（Policy）的代码化表达。一个好的 Policy 应该能回答：
> "这笔操作，系统有没有违规？"——而不是"AI 觉得有没有违规？"

**Guard 能检查什么**：
- `to` 地址是否在白名单（防止转账给任意地址）
- `calldata` 中调用的是否是允许的函数（防止 approve 无限额度）
- `value` 是否超过单笔限额（防止超支）
- 滑点是否过大（防止 MEV 攻击导致异常损失）
- 当日已累计金额（防止死循环超支）

**Guard 无法检查什么（局限性）**：
- 报告内容是否真实（语义层面的质量判断）
- 链外行为（Agent 是否在正确执行任务）
- 复杂市场状态（只能用 Oracle 辅助）

**解决的风险类型**：
- Prompt Injection 导致 Agent 生成恶意交易
- 工具调用返回篡改数据（如修改收款地址）
- 模型误判导致超限操作

---

### 3.5 三者的协同关系

```
┌──────────────────────────────────────────────────────┐
│  完整的 Agent Wallet 安全层级                         │
│                                                      │
│  Layer 0（AI 层）                                    │
│    Agent 生成 UserOperation 意图                      │
│                                                      │
│  Layer 1（Policy 层）                                │
│    Policy 规则集定义什么能做什么不能做                  │
│                                                      │
│  Layer 2（Guard 层）                                 │
│    确定性代码检查：不符合 Policy 的交易直接 revert      │
│                                                      │
│  Layer 3（Smart Account / ERC-4337 层）              │
│    Session Key 校验 + EntryPoint 执行                 │
│                                                      │
│  Layer 4（Safe 多签层，高价值操作）                   │
│    M-of-N 多签确认，Owner 有最终否决权                  │
│                                                      │
│  Layer 5（用户 / 人工层）                            │
│    中高风险操作推送确认，随时撤销 Session Key            │
└──────────────────────────────────────────────────────┘

AI 层越往上，越智能但越不确定；
Guard 层越往下，越确定但越不灵活。
好的设计把两者结合：AI 负责生成意图，Guard 负责拒绝越界。
```

---

## 四、核心洞察

> **权限不是"给多少"的问题，而是"怎么限制"的问题。**

1. **Agent 不能拥有钱包，只能拥有受限能力**：Session Key 是最小授权单元，用完即废，范围越小越安全。

2. **ERC-4337 让权限可以被合约代码验证**：传统私钥签名无法表达"只允许 swap，不允许 approve"，Smart Account 可以。

3. **Safe 解决的是"谁负责"的问题**：高价值资产不应由单一热钱包控制，多签把"谁能动资产"变成治理问题而非技术问题。

4. **Guard 是 AI 判断的最后一道防线**：模型可以出错，工具可以被注入，但 Guard 只看链上可验证的事实（地址、金额、函数选择器），不受模型幻觉影响。

5. **日志是事后追责的唯一依据**：链上 Event 不可篡改，链下 Log 保留操作上下文，两者缺一不可。

---

**GitHub**：https://github.com/beetroot42/ai-web3-school-cohort-0/blob/main/submissions/week2-module-d-agent-wallet-policy.md
