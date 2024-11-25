// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

/**
 * @title TokenB
 * @author Pablo Luna
 * @notice Standard ERC20 token contract with minting functionality. 
 * The owner can mint new tokens and the initial supply is assigned to the deployer.
 */

// Importing the ERC20 and Ownable contracts from the OpenZeppelin library using a structured import.
// ERC20 is used to create a standard token contract, and Ownable is for access control, giving special permissions to the contract owner.
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Defining the TokenB contract, which inherits from ERC20 (for token functionality) and Ownable (for ownership management).
contract TokenB is ERC20, Ownable {
    // Constructor initializes the token's name, symbol, and initial supply.
    // It also assigns the contract deployer as the owner through Ownable(msg.sender).
    constructor()
        ERC20("TokenB", "TKB") // Setting the token's name as "TokenB" and symbol as "TKB".
        Ownable(msg.sender) // Designating the deployer as the owner of the contract.
    {
        // Minting an initial supply of tokens to the deployer's address.
        // The total minted is 1000 multiplied by 10 to the power of the token's decimals (commonly 18 decimals).
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    // A public function to mint new tokens.
    // This function is restricted to the contract owner by the onlyOwner modifier.
    // 'to' specifies the recipient address, and 'amount' indicates the number of tokens to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount); // Minting the specified amount of tokens to the provided address.
    }
}
