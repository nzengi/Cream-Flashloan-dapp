const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying to Cream Finance Network...");

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

  // Deploy Cream Flash Loan Attacker
  console.log("\n⚔️ Deploying Cream Flash Loan Attacker...");
  const CreamFlashLoanAttacker = await ethers.getContractFactory(
    "CreamFlashLoanAttacker"
  );

  // Cream Finance mainnet addresses
  const creamAddresses = {
    usdc: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", // USDC
    weth: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // WETH
    uniswapV2Factory: "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f", // Uniswap V2 Factory
    uniswapV2Router: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", // Uniswap V2 Router
    creamComptroller: "0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258", // Cream Comptroller
    creamFlashLoan: "0x1b14E8D5113019e04993DdFd2e50560c52d3d3A4", // Cream Flash Loan
    cUSDC: "0x44fbeBd2F576670a6e33E2a5D8f38C5A2A7712B8", // cUSDC
    cERSV: "0x0000000000000000000000000000000000000000", // cERSV (will be created)
  };

  const attacker = await CreamFlashLoanAttacker.deploy(
    ethosReserveAddress,
    creamAddresses.usdc,
    creamAddresses.weth,
    creamAddresses.uniswapV2Factory,
    creamAddresses.uniswapV2Router,
    creamAddresses.creamComptroller,
    creamAddresses.creamFlashLoan,
    creamAddresses.cUSDC,
    creamAddresses.cERSV
  );
  await attacker.waitForDeployment();

  const attackerAddress = await attacker.getAddress();
  console.log("✅ Cream Flash Loan Attacker deployed to:", attackerAddress);

  // Transfer some tokens to attacker for testing
  const transferAmount = ethers.parseEther("1000000"); // 1M ERSV
  await ethosReserve.transfer(attackerAddress, transferAmount);
  console.log(
    `💰 Transferred ${ethers.formatEther(transferAmount)} ERSV to attacker`
  );

  // Print deployment summary
  console.log("\n📋 Cream Finance Deployment Summary:");
  console.log("=====================================");
  console.log(`Ethos Reserve Token: ${ethosReserveAddress}`);
  console.log(`Cream Flash Loan Attacker: ${attackerAddress}`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Network: mainnet (Cream Finance)`);

  // Save deployment info
  const deploymentInfo = {
    network: "mainnet-cream",
    deployer: deployer.address,
    contracts: {
      ethosReserve: ethosReserveAddress,
      creamFlashLoanAttacker: attackerAddress,
    },
    creamAddresses: creamAddresses,
    timestamp: new Date().toISOString(),
  };

  // Write to file
  const fs = require("fs");
  fs.writeFileSync(
    "cream-deployment.json",
    JSON.stringify(deploymentInfo, null, 2)
  );
  console.log("\n💾 Cream deployment info saved to cream-deployment.json");

  console.log("\n🎯 Next Steps for Cream Finance:");
  console.log("=================================");
  console.log("1. Add ERSV/USDC liquidity to Uniswap V2");
  console.log("2. Request ERSV listing on Cream Finance");
  console.log("3. Wait for cERSV token creation");
  console.log("4. Update cERSV address in contract");
  console.log("5. Run attack simulation");

  console.log("\n⚠️  IMPORTANT NOTES:");
  console.log("====================");
  console.log("• Cream Finance has been hacked multiple times");
  console.log(
    "• Token listing is easier than Aave but still requires approval"
  );
  console.log("• Consider using testnet first");
  console.log("• Flash loan attacks may be illegal");
  console.log("• Use responsibly and ethically");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Cream deployment failed:", error);
    process.exit(1);
  });
