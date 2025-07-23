# Ethos Reserve (ERSV) - DeFi Manipulation Research

🔬 **Research Project**: Demonstrating flash loan attacks and price manipulation in DeFi lending protocols.

## 📋 Project Overview

This project demonstrates how a malicious actor could:

1. Create a custom token (Ethos Reserve - ERSV)
2. Use flash loans to manipulate token prices
3. Exploit lending protocols by depositing inflated collateral
4. Profit from the price manipulation

⚠️ **DISCLAIMER**: This is for educational and research purposes only. Do not use for malicious purposes.

## 🏗️ Architecture

### Contracts

- **`EthosReserve.sol`**: Custom ERC20 token with reserve backing simulation
- **`FlashLoanAttacker.sol`**: Demonstrates flash loan attack vectors
- **Test Files**: Comprehensive test coverage for all functionality

### Key Features

- ✅ ERC20 compliant token with 100M total supply
- ✅ Reserve backing simulation
- ✅ Pausable functionality
- ✅ Flash loan attack simulation
- ✅ Price manipulation demonstration

## 🚀 Quick Start

### Prerequisites

- Node.js (v16+)
- npm or yarn
- Hardhat

### Installation

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm test

# Deploy contracts
npm run deploy

# Run attack simulation
npm run attack
```

## 📊 Attack Scenario

### Step-by-Step Process

1. **Token Creation**: Deploy Ethos Reserve (ERSV) token
2. **Flash Loan**: Borrow large amount of USDC
3. **Price Pump**: Buy ERSV tokens to inflate price
4. **Collateral Deposit**: Deposit inflated ERSV as collateral
5. **Asset Borrowing**: Borrow stablecoins against inflated collateral
6. **Price Dump**: Sell ERSV to crash price
7. **Flash Loan Repayment**: Repay the flash loan
8. **Profit**: Keep the borrowed assets

### Attack Flow Diagram

```
Flash Loan (USDC) → Price Pump (ERSV) → Collateral Deposit →
Asset Borrowing → Price Dump → Flash Loan Repayment → Profit
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file:

```env
PRIVATE_KEY=your_private_key_here
MAINNET_RPC_URL=your_mainnet_rpc_url
SEPOLIA_RPC_URL=your_sepolia_rpc_url
```

### Network Configuration

- **Hardhat Network**: For local testing and simulation
- **Sepolia Testnet**: For testnet deployment
- **Mainnet Fork**: For realistic attack simulation

## 📈 Token Economics

### Ethos Reserve (ERSV)

- **Name**: Ethos Reserve
- **Symbol**: ERSV
- **Decimals**: 18
- **Total Supply**: 100,000,000 ERSV
- **Initial Distribution**: 100% to deployer

### Reserve Backing

The token simulates reserve backing with:

- Configurable reserve assets
- Reserve addition/removal functions
- Event tracking for transparency

## 🛡️ Security Considerations

### Attack Vectors Demonstrated

1. **Oracle Manipulation**: Using flash loans to manipulate DEX prices
2. **Collateral Inflation**: Depositing artificially inflated tokens
3. **Protocol Exploitation**: Borrowing against worthless collateral

### Mitigation Strategies

- **Chainlink Oracles**: Use decentralized price feeds
- **LTV Ratios**: Implement conservative loan-to-value ratios
- **Borrow Caps**: Limit maximum borrowing amounts
- **Isolation Mode**: Restrict new token integrations
- **TWAP Delays**: Use time-weighted average prices

## 🧪 Testing

### Test Coverage

```bash
# Run all tests
npm test

# Run specific test file
npx hardhat test test/EthosReserve.test.js

# Run with coverage
npx hardhat coverage
```

### Test Scenarios

- ✅ Token deployment and metadata
- ✅ Transfer functionality
- ✅ Minting and burning
- ✅ Reserve backing operations
- ✅ Pausable functionality
- ✅ Event emissions
- ✅ Attack simulation

## 📝 Scripts

### Available Commands

```bash
npm run compile    # Compile contracts
npm run test       # Run tests
npm run deploy     # Deploy contracts
npm run attack     # Run attack simulation
```

### Deployment Output

After running `npm run deploy`, you'll get:

- Contract addresses
- Deployment summary
- `deployment.json` file with all details

## 🔍 Analysis

### Attack Profit Calculation

```
Profit = Borrowed Assets - Flash Loan Amount - Gas Costs
```

### Risk Factors

- **Oracle Security**: Dependence on price feeds
- **Liquidity Depth**: Market depth affects manipulation cost
- **Protocol Safeguards**: LTV ratios and caps
- **Gas Costs**: Transaction costs can eat into profits

## 📚 Documentation

### Contract Interfaces

All contracts include comprehensive NatSpec documentation:

- Function descriptions
- Parameter explanations
- Return value details
- Event documentation

### Code Comments

- Inline comments for complex logic
- Security considerations noted
- Attack vector explanations

## 🤝 Contributing

This is a research project. Contributions should focus on:

- Improving attack detection methods
- Enhancing security analysis
- Adding new attack vectors for study
- Improving documentation

## ⚖️ Legal Notice

This project is for educational purposes only. The authors are not responsible for any misuse of this code. Always comply with applicable laws and regulations.

## 📞 Support

For questions or issues:

- Open an issue on GitHub
- Review the documentation
- Check the test files for examples

---

**Remember**: This is research code. Use responsibly and ethically.
