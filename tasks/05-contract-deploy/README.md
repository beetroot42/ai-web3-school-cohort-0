# 任务 05 — 测试网智能合约部署与调用

> **工具**：Hardhat 2 + hardhat-ethers + PublicNode RPC  
> **网络**：Ethereum Sepolia 测试网  
> **部署时间**：2026-05-27

---

## 1. 合约信息

| 项目 | 内容 |
|------|------|
| **合约名称** | `SimpleCounter` |
| **合约地址** | `0x6FDAD51Ea6096a33C7Df91bA963AFc8276324502` |
| **部署账户** | `0xa29c684fb5608C1dB01684F0B11d312f8887cB65` |
| **网络** | Sepolia Testnet |
| **Solidity 版本** | 0.8.20 |

---

## 2. 区块浏览器链接

- **合约地址**：https://sepolia.etherscan.io/address/0x6FDAD51Ea6096a33C7Df91bA963AFc8276324502
- **increment() 调用 TxHash**：https://sepolia.etherscan.io/tx/0xa07e40d4a2e3b9b695eff9c7eda2e7fc70114eeac66799f5efdce7318986c97d

---

## 3. 读取 / 写入结果

### 读取（getState） — 免费，无需签名

**部署后初始状态：**
```
count : 0
owner : 0xa29c684fb5608C1dB01684F0B11d312f8887cB65
label : beetroot42-task05
```

**调用 increment() 之后：**
```
count : 1  ✅
```

### 写入（increment()）— 需要签名，消耗 Gas
- TxHash：`0xa07e40d4a2e3b9b695eff9c7eda2e7fc70114eeac66799f5efdce7318986c97d`
- 状态：链上确认，count 从 0 → 1

---

## 4. 合约代码

见同目录：[SimpleCounter.sol](./SimpleCounter.sol)  
GitHub：https://github.com/beetroot42/ai-web3-school-cohort-0/blob/main/tasks/05-contract-deploy/contracts/SimpleCounter.sol

合约功能：
- `increment()` — 计数器 +1，任何人可调用，需签名 + Gas
- `reset()` — 重置为 0，仅 owner 可调用
- `setLabel()` — 更新标签
- `getState()` — 读取 count/owner/label，免费

---

## 5. 步骤说明与人工确认环节

| 步骤 | 执行方式 | 人工确认？ |
|------|---------|-----------|
| 编写合约 | 手动写 Solidity | ✅ 代码审核 |
| 编译（`npx hardhat compile`）| 命令行自动 | ❌ |
| **部署（`deploy()`）** | 命令行发起 | ⚠️ **钱包签名**（脚本自动用私钥签，等同于授权部署） |
| 读取状态（`getState()`）| view 函数，链下执行 | ❌ 免费无需签名 |
| **调用 increment()** | 链上写入交易 | ⚠️ **钱包签名**（脚本自动用私钥签，消耗 Gas） |
| 链上验证 | Etherscan 查询 TxHash | ✅ 人工确认结果 |

> **核心学习点**：`getState()` 是 view 函数，只读链上状态，完全免费；`increment()` 会修改链上状态，必须签名广播一笔交易并支付 Gas fee。两者的区别就是"读"与"写"的边界。

---

## 🔗 相关资源

- 合约浏览器：https://sepolia.etherscan.io/address/0x6FDAD51Ea6096a33C7Df91bA963AFc8276324502
- Hardhat 文档：https://v2.hardhat.org/
- PublicNode Sepolia RPC：https://ethereum-sepolia-rpc.publicnode.com
- 上一篇：[04-ai-web3-workflow.md](../04-ai-web3-workflow.md)
