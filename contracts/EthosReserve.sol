// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Ethos Reserve Token
 * @dev A reserve-backed stable asset for DeFi liquidity
 * @notice This token is designed for research purposes
 */
contract EthosReserve is ERC20, Ownable {
    
    // Token metadata
    string public constant VERSION = "1.0.0";
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18; // 100M ERSV
    
    // Reserve backing (simulated)
    mapping(address => uint256) public reserveBacking;
    
    // Events
    event ReserveAdded(address indexed token, uint256 amount);
    event ReserveRemoved(address indexed token, uint256 amount);
    
    constructor() ERC20("Ethos Reserve", "ERSV") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
    
    /**
     * @dev Mint additional tokens (owner only)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    /**
     * @dev Burn tokens
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    /**
     * @dev Add reserve backing (simulated)
     */
    function addReserveBacking(address token, uint256 amount) external onlyOwner {
        reserveBacking[token] += amount;
        emit ReserveAdded(token, amount);
    }
    
    /**
     * @dev Remove reserve backing (simulated)
     */
    function removeReserveBacking(address token, uint256 amount) external onlyOwner {
        require(reserveBacking[token] >= amount, "Insufficient reserve");
        reserveBacking[token] -= amount;
        emit ReserveRemoved(token, amount);
    }
    

} 