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
    /// @notice ERC20 token contract instances for the tokens in the DEX pool.
    IERC20 public tokenA; 
    IERC20 public tokenB; 

    /// @notice Owner of the contract, allowed to add/remove liquidity.
    address public owner; 

    /// @notice Reserve balances for each token in the liquidity pool.
    uint256 public reserveA; 
    uint256 public reserveB; 

    /// @notice Emitted when liquidity is added to the pool.
    event LiquidityAdded(uint256 amountA, uint256 amountB);

    /// @notice Emitted when liquidity is removed from the pool.
    event LiquidityRemoved(uint256 amountA, uint256 amountB);

    /// @notice Emitted when tokens are swapped in the pool.
    event TokensSwapped(
        address indexed user,
        uint256 amountIn,
        uint256 amountOut,
        string direction
    );

    /**
     * @dev Initializes the contract with the two token addresses and sets the contract deployer as the owner.
     * @param _tokenA Address of the first token.
     * @param _tokenB Address of the second token.
     */
    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Tokens must be different");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }

    /// @dev Modifier to restrict access to only the owner of the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    /**
     * @notice Adds liquidity to the pool.
     * @dev Requires the sender to be the owner and maintains reserve ratios.
     * @param amountA Amount of token A to add.
     * @param amountB Amount of token B to add.
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        if (reserveA > 0 && reserveB > 0) {
            require(amountA * reserveB == amountB * reserveA, "Invalid ratio");
        }

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(amountA, amountB);
    }

    /**
     * @notice Swaps token A for token B.
     * @dev Uses a constant product formula for calculating the output amount.
     * @param amountAIn Amount of token A to swap.
     */
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Invalid amount");
        require(reserveA > 0 && reserveB > 0, "Pool is empty");

        uint256 amountBOut = (reserveB * amountAIn) / (reserveA + amountAIn);
        require(amountBOut > 0, "Insufficient output amount");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        reserveA += amountAIn;
        reserveB -= amountBOut;

        emit TokensSwapped(msg.sender, amountAIn, amountBOut, "A to B");
    }

    /**
     * @notice Swaps token B for token A.
     * @dev Uses a constant product formula for calculating the output amount.
     * @param amountBIn Amount of token B to swap.
     */
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Invalid amount");
        require(reserveA > 0 && reserveB > 0, "Pool is empty");

        uint256 amountAOut = (reserveA * amountBIn) / (reserveB + amountBIn);
        require(amountAOut > 0, "Insufficient output amount");

        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        tokenA.transfer(msg.sender, amountAOut);

        reserveB += amountBIn;
        reserveA -= amountAOut;

        emit TokensSwapped(msg.sender, amountBIn, amountAOut, "B to A");
    }

    /**
     * @notice Removes liquidity from the pool.
     * @dev Only the owner can remove liquidity.
     * @param amountA Amount of token A to withdraw.
     * @param amountB Amount of token B to withdraw.
     */
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Invalid amounts");
        require(reserveA >= amountA && reserveB >= amountB, "Not enough liquidity");

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(amountA, amountB);
    }

    /**
     * @notice Gets the price of a token in terms of the other token.
     * @param _token Address of the token to price.
     * @return Price of 1 unit of the specified token in terms of the other token.
     */
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token");

        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA; // Token A price in terms of token B
        } 
        return (reserveA * 1e18) / reserveB; // Token B price in terms of token A
    }
}
