const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("📡 Deploying with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Balance:", ethers.formatEther(balance), "ETH");

  const label = "beetroot42-task05";
  const Counter = await ethers.getContractFactory("SimpleCounter");
  const counter = await Counter.deploy(label);
  await counter.waitForDeployment();

  const address = await counter.getAddress();
  console.log("\n✅ SimpleCounter deployed!");
  console.log("📍 Contract address:", address);
  console.log("🔗 Sepolia Etherscan:", `https://sepolia.etherscan.io/address/${address}`);

  // Read initial state
  const [count, owner, lbl] = await counter.getState();
  console.log("\n📖 Initial state (getState):");
  console.log("  count :", count.toString());
  console.log("  owner :", owner);
  console.log("  label :", lbl);

  // Call increment()
  console.log("\n⏳ Calling increment()...");
  const tx = await counter.increment();
  await tx.wait();
  console.log("✅ increment() confirmed! TxHash:", tx.hash);
  console.log("🔗 Tx:", `https://sepolia.etherscan.io/tx/${tx.hash}`);

  // Read updated state
  const [count2] = await counter.getState();
  console.log("\n📖 Updated state:");
  console.log("  count :", count2.toString(), "← should be 1");
}

main().catch((e) => { console.error(e); process.exitCode = 1; });
