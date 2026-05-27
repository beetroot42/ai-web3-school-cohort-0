// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SimpleCounter
 * @notice AI × Web3 School — Task 05
 * @dev Minimal counter contract for testnet deployment exercise.
 *      Deployed by: beetroot42
 *      Network: Sepolia Testnet
 */
contract SimpleCounter {
    // ── State ──────────────────────────────────────────────
    uint256 public count;          // 计数器（链上状态）
    address public owner;          // 部署者地址
    string  public label;          // 自定义标签

    // ── Events ─────────────────────────────────────────────
    event Incremented(address indexed caller, uint256 newCount);
    event LabelUpdated(string newLabel);

    // ── Constructor ────────────────────────────────────────
    constructor(string memory _label) {
        owner = msg.sender;
        label = _label;
        count = 0;
    }

    // ── Write Functions (需要人工钱包确认) ──────────────────

    /// @notice 计数器 +1，任何人可调用
    function increment() external {
        count += 1;
        emit Incremented(msg.sender, count);
    }

    /// @notice 重置为 0，仅部署者可调用
    function reset() external {
        require(msg.sender == owner, "Only owner can reset");
        count = 0;
    }

    /// @notice 更新标签
    function setLabel(string memory _newLabel) external {
        label = _newLabel;
        emit LabelUpdated(_newLabel);
    }

    // ── Read Functions (免费，无需签名) ────────────────────

    /// @notice 一次性读取所有状态
    function getState() external view returns (
        uint256 _count,
        address _owner,
        string memory _label
    ) {
        return (count, owner, label);
    }
}
