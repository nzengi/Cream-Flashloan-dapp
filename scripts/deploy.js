const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying Ethos Reserve Token and Attack Contracts...");

  // Get signer
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Deploy Ethos Reserve Token
  console.log("\n📦 Deploying Ethos Reserve Token...");
  const EthosReserve = await ethers.getContractFactory("EthosReserve");
  const ethosReserve = await EthosReserve.deploy();
  await ethosReserve.waitForDeployment();

  const ethosReserveAddress = await ethosReserve.getAddress();
  console.log("✅ Ethos Reserve deployed to:", ethosReserveAddress);

  // Get token info
  const name = await ethosReserve.name();
  const symbol = await ethosReserve.symbol();
  const totalSupply = await ethosReserve.totalSupply();
  console.log(`Token: ${name} (${symbol})`);
  console.log(`Total Supply: ${ethers.formatEther(totalSupply)} ERSV`);

  // Deploy Flash Loan Attacker
  console.log("\n⚔️ Deploying Flash Loan Attacker...");
  const FlashLoanAttacker = await ethers.getContractFactory(
    "FlashLoanAttacker"
  );

  // Mock addresses for demo (in real scenario, these would be actual addresses)
  const mockAddresses = {
    usdc: "0x1234567890123456789012345678901234567890",
    weth: "0x2345678901234567890123456789012345678901",
    uniswapV2Factory: "0x3456789012345678901234567890123456789012",
    uniswapV2Router: "0x4567890123456789012345678901234567890123",
    aaveLendingPool: "0x5678901234567890123456789012345678901234",
    aaveDataProvider: "0x6789012345678901234567890123456789012345",
  };

  const attacker = await FlashLoanAttacker.deploy(
    ethosReserveAddress,
    mockAddresses.usdc,
    mockAddresses.weth,
    mockAddresses.uniswapV2Factory,
    mockAddresses.uniswapV2Router,
    mockAddresses.aaveLendingPool,
    mockAddresses.aaveDataProvider
  );
  await attacker.waitForDeployment();

  const attackerAddress = await attacker.getAddress();
  console.log("✅ Flash Loan Attacker deployed to:", attackerAddress);

  // Transfer some tokens to attacker for testing
  const transferAmount = ethers.parseEther("1000000"); // 1M ERSV
  await ethosReserve.transfer(attackerAddress, transferAmount);
  console.log(
    `💰 Transferred ${ethers.formatEther(transferAmount)} ERSV to attacker`
  );

  // Print deployment summary
  console.log("\n📋 Deployment Summary:");
  console.log("========================");
  console.log(`Ethos Reserve Token: ${ethosReserveAddress}`);
  console.log(`Flash Loan Attacker: ${attackerAddress}`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Network: ${network.name}`);

  // Save deployment info
  const deploymentInfo = {
    network: network.name,
    deployer: deployer.address,
    contracts: {
      ethosReserve: ethosReserveAddress,
      flashLoanAttacker: attackerAddress,
    },
    mockAddresses: mockAddresses,
    timestamp: new Date().toISOString(),
  };

  // Write to file
  const fs = require("fs");
  fs.writeFileSync("deployment.json", JSON.stringify(deploymentInfo, null, 2));
  console.log("\n💾 Deployment info saved to deployment.json");

  console.log("\n🎯 Next Steps:");
  console.log("1. Add liquidity to Uniswap V2 (ERSV/USDC pair)");
  console.log("2. Configure Aave integration (if testing on mainnet fork)");
  console.log("3. Run attack simulation with: npm run attack");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
