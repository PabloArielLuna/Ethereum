// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ScrollSepoliaAuction
 * @author Pablo Luna 
 * @notice Optimized auction contract where losing bidders are refunded minus a 2% commission.
 * The highest bidder wins the auctioned product and pays the full amount.
 */
contract ScrollSepoliaAuction {
    address public immutable owner; // Contract owner, immutable to save gas
    address public seller; // Seller's address
    address public highestBidder; // Current highest bidder
    uint256 public highestBid; // Current highest bid amount
    uint256 public auctionEndTime; // Auction end timestamp
    uint256 public constant MINIMUM_INCREASE = 105; // 5% minimum bid increment
    uint256 public constant COMMISSION_RATE = 2; // 2% commission rate
    bool public ended; // Tracks if the auction has ended

    mapping(address => uint256) private deposits; // Tracks deposits by bidders (private for gas efficiency)

    // Events for logging auction actions
    event NewBid(address indexed bidder, uint256 amount);
    event AuctionEnded(address indexed winner, uint256 amount);

    // Restricts access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the auction owner");
        _;
    }

    // Ensures the auction has not ended
    modifier beforeEnd() {
        require(block.timestamp < auctionEndTime, "Auction has ended");
        _;
    }

    // Ensures the auction has ended
    modifier afterEnd() {
        require(block.timestamp >= auctionEndTime, "Auction has not ended");
        _;
    }

    /**
     * @dev Constructor to initialize the auction contract.
     * @param _seller The address of the seller.
     * @param _biddingTime Auction duration in seconds.
     */
    constructor(address _seller, uint256 _biddingTime) {
        owner = msg.sender; // Set deployer as owner
        seller = _seller; // Set seller's address
        auctionEndTime = block.timestamp + _biddingTime; // Calculate auction end time
    }

    /**
     * @dev Allows participants to place bids.
     * Refunds the previous highest bidder if a higher bid is made.
     */
    function bid() external payable beforeEnd {
        // Ensure the new bid exceeds the current highest bid by at least 5%
        require(
            msg.value > (highestBid * MINIMUM_INCREASE) / 100, 
            "Bid must exceed minimum increase"
        );

        // Cache the current highest bidder and bid
        address previousBidder = highestBidder;
        uint256 previousBid = highestBid;

        // Update the highest bidder and highest bid
        highestBidder = msg.sender;
        highestBid = msg.value;

        // Refund the previous highest bidder, adding their bid to their deposit balance
        if (previousBidder != address(0)) {
            deposits[previousBidder] += previousBid;
        }

        // Extend auction time if it is close to ending
        if (block.timestamp >= auctionEndTime - 10 minutes) {
            auctionEndTime += 10 minutes;
        }

        // Emit an event for the new bid
        emit NewBid(msg.sender, msg.value);
    }

    /**
     * @dev Allows losing bidders to withdraw their funds after the auction ends.
     * Deducts a 2% commission from the refund for all bidders except the winner.
     */
    function withdrawExcess() external afterEnd {
        // The winner cannot withdraw funds using this function
        require(msg.sender != highestBidder, "Winner cannot withdraw funds");

        // Check the deposit balance for the sender
        uint256 refund = deposits[msg.sender];
        require(refund > 0, "No funds to withdraw");

        // Reset the sender's deposit balance to prevent reentrancy
        deposits[msg.sender] = 0;

        // Calculate the commission and the final refund amount
        uint256 commission = (refund * COMMISSION_RATE) / 100;
        uint256 finalRefund = refund - commission;

        // Transfer the commission to the owner
        (bool commissionTransfer, ) = owner.call{value: commission}("");
        require(commissionTransfer, "Commission transfer failed");

        // Refund the remaining amount to the sender
        (bool refundTransfer, ) = msg.sender.call{value: finalRefund}("");
        require(refundTransfer, "Refund transfer failed");
    }

    /**
     * @dev Ends the auction and transfers the highest bid amount to the seller.
     * The highest bidder wins the auctioned product (handled off-chain).
     */
    function endAuction() external onlyOwner afterEnd {
        // Ensure the auction has not already ended
        require(!ended, "Auction already ended");
        ended = true;

        // Cache the highest bid
        uint256 payout = highestBid;

        // Emit the auction ended event
        emit AuctionEnded(highestBidder, payout);

        // Transfer the highest bid amount to the seller
        if (payout > 0) {
            (bool success, ) = seller.call{value: payout}("");
            require(success, "Transfer to seller failed");
        }
    }

    /**
     * @dev Emergency function for the owner to withdraw all contract funds.
     */
    function emergencyWithdraw() external onlyOwner {
        // Transfer the entire contract balance to the owner
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Emergency withdraw failed");
    }

    /**
     * @dev Returns the auction details for external queries.
     * @return The highest bidder, highest bid, auction end time, and if it has ended.
     */
    function getAuctionDetails()
        external
        view
        returns (address, uint256, uint256, bool)
    {
        return (highestBidder, highestBid, auctionEndTime, ended);
    }

    /**
     * @dev Returns the deposit balance for a specific bidder.
     * @param user The address of the bidder.
     * @return The deposit balance of the bidder.
     */
    function getDeposit(address user) external view returns (uint256) {
        return deposits[user];
    }
}
