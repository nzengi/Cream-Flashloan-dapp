const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying to Ethereum Mainnet...");

  // Get signer
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Check balance
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log(`Account balance: ${ethers.formatEther(balance)} ETH`);

  if (balance < ethers.parseEther("0.1")) {
    console.error("❌ Insufficient balance for deployment");
    return;
  }

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

  // Deploy Flash Loan Attacker with real mainnet addresses
  console.log("\n⚔️ Deploying Flash Loan Attacker...");
  const FlashLoanAttacker = await ethers.getContractFactory(
    "FlashLoanAttacker"
  );

  // Real mainnet addresses
  const mainnetAddresses = {
    usdc: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC - PLACEHOLDER
    weth: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // WETH
    uniswapV2Factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f", // Uniswap V2 Factory
    uniswapV2Router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap V2 Router
    aaveLendingPool: "0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9", // Aave V2 LendingPool
    aaveDataProvider: "0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d", // Aave DataProvider
  };

  const attacker = await FlashLoanAttacker.deploy(
    ethosReserveAddress,
    mainnetAddresses.usdc,
    mainnetAddresses.weth,
    mainnetAddresses.uniswapV2Factory,
    mainnetAddresses.uniswapV2Router,
    mainnetAddresses.aaveLendingPool,
    mainnetAddresses.aaveDataProvider
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
  console.log("\n📋 Mainnet Deployment Summary:");
  console.log("================================");
  console.log(`Ethos Reserve Token: ${ethosReserveAddress}`);
  console.log(`Flash Loan Attacker: ${attackerAddress}`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Network: mainnet`);

  // Save deployment info
  const deploymentInfo = {
    network: "mainnet",
    deployer: deployer.address,
    contracts: {
      ethosReserve: ethosReserveAddress,
      flashLoanAttacker: attackerAddress,
    },
    mainnetAddresses: mainnetAddresses,
    timestamp: new Date().toISOString(),
  };

  // Write to file
  const fs = require("fs");
  fs.writeFileSync(
    "mainnet-deployment.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("\n💾 Mainnet deployment info saved to mainnet-deployment.json");

  console.log("\n⚠️  IMPORTANT NOTES:");
  console.log("====================");
  console.log("• This is a RESEARCH project - use responsibly");
  console.log("• Real mainnet deployment requires significant ETH for gas");
  console.log("• Flash loan attacks may be illegal in some jurisdictions");
  console.log("• Always test on testnets first");
  console.log("• Consider legal implications before mainnet deployment");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Mainnet deployment failed:", error);
    process.exit(1);
  });
