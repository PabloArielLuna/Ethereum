// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

/**
 * @title TokenA
 * @author Pablo Luna
 * @notice Standard ERC20 token contract with minting functionality. 
 * The owner can mint new tokens and the initial supply is assigned to the deployer.
 */

// Importing the ERC20 and Ownable contracts from the OpenZeppelin library.
// ERC20 is used for creating a standard token, and Ownable provides access control mechanisms.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Defining the TokenA contract, which inherits from both ERC20 and Ownable.
contract TokenA is ERC20, Ownable {
    // The constructor initializes the token with its name, symbol, and initial supply.
    // It also sets the contract deployer as the owner using Ownable(msg.sender).
    constructor()
        ERC20("TokenA", "TKA") // Setting the token's name as "TokenA" and symbol as "TKA".
        Ownable(msg.sender) // Assigning the deployer as the owner of the contract.
    {
        // Minting an initial supply of tokens to the deployer's address.
        // The amount minted is 1000 multiplied by 10 to the power of the token's decimals (usually 18).
        _mint(msg.sender, 1000 * 10**decimals());
    }

    // A public function to mint new tokens.
    // Only the owner of the contract can call this function, as it is restricted by the onlyOwner modifier.
    // 'to' is the recipient address, and 'amount' is the number of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount); // Minting the specified amount of tokens to the recipient address.
    }
}
