// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleDEX
 * @author Pablo Luna
 * @notice A decentralized exchange (DEX) for swapping two ERC20 tokens. 
 * Allows liquidity addition, removal, and token swaps using a constant product formula.
 */

// Importing the IERC20 interface from the OpenZeppelin library for token interaction.
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Defining the SimpleDEX contract, a decentralized exchange (DEX) for swapping two ERC20 tokens.
contract SimpleDEX {
    // Declaring public variables for the two tokens, the owner, and the reserves of each token.
    IERC20 public tokenA; // The first token supported by the DEX.
    IERC20 public tokenB; // The second token supported by the DEX.
    address public owner; // The address of the contract owner.
    uint256 public reserveA; // Reserve amount of token A in the pool.
    uint256 public reserveB; // Reserve amount of token B in the pool.

    // Defining events for logging significant actions within the contract.
    event LiquidityAdded(uint256 amountA, uint256 amountB); // Emitted when liquidity is added to the pool.
    event LiquidityRemoved(uint256 amountA, uint256 amountB); // Emitted when liquidity is removed from the pool.
    event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut, string direction); // Emitted when a token swap occurs.

    // Constructor function to initialize the contract with the addresses of the two tokens and set the contract owner.
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA); // Assigning tokenA address.
        tokenB = IERC20(_tokenB); // Assigning tokenB address.
        owner = msg.sender; // Setting the contract deployer as the owner.
    }

    // Modifier to restrict certain functions to only the owner of the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner"); // Ensuring the caller is the owner.
        _;
    }

    // Function to add liquidity to the pool by depositing token A and token B in specified amounts.
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Invalid amounts"); // Ensuring valid amounts.

        // If the pool already has reserves, the added amounts must maintain the same ratio.
        if (reserveA > 0 && reserveB > 0) {
            require(amountA * reserveB == amountB * reserveA, "Invalid ratio");
        }

        // Transferring tokens from the owner's address to the contract.
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // Updating reserves.
        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(amountA, amountB); // Emitting the liquidity added event.
    }

    // Function to swap token A for token B.
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Invalid amount"); // Ensuring a valid input amount.
        require(reserveA > 0 && reserveB > 0, "Pool is empty"); // Ensuring the pool is not empty.

        // Calculating the amount of token B to be given out using a simple constant product formula.
        uint256 amountBOut = (reserveB * amountAIn) / (reserveA + amountAIn);
        require(amountBOut > 0, "Insufficient output amount"); // Ensuring the output amount is valid.

        // Transferring token A from the user to the contract and token B from the contract to the user.
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        // Updating reserves.
        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, amountAIn, amountBOut, "A to B"); // Emitting the swap event.
    }

    // Function to swap token B for token A.
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Invalid amount"); // Ensuring a valid input amount.
        require(reserveA > 0 && reserveB > 0, "Pool is empty"); // Ensuring the pool is not empty.

        // Calculating the amount of token A to be given out using a simple constant product formula.
        uint256 amountAOut = (reserveA * amountBIn) / (reserveB + amountBIn);
        require(amountAOut > 0, "Insufficient output amount"); // Ensuring the output amount is valid.

        // Transferring token B from the user to the contract and token A from the contract to the user.
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        // Updating reserves.
        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, amountBIn, amountAOut, "B to A"); // Emitting the swap event.
    }

    // Function to remove liquidity from the pool, transferring the specified amounts back to the owner.
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Invalid amounts"); // Ensuring valid amounts.
        require(reserveA >= amountA && reserveB >= amountB, "Not enough liquidity"); // Ensuring sufficient reserves.

        // Updating reserves.
        reserveA -= amountA;
        reserveB -= amountB;

        // Transferring tokens back to the owner.
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(amountA, amountB); // Emitting the liquidity removed event.
    }

    // Function to get the price of one token in terms of the other, based on the reserves.
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token"); // Ensuring a valid token.

        // Calculating the price of token A in terms of token B, or vice versa.
        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA; // Price of 1 token A in terms of token B.
        } else {
            return (reserveA * 1e18) / reserveB; // Price of 1 token B in terms of token A.
        }
    }
}
