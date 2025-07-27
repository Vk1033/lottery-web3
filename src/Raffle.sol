// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title Raffle contract
 * @author Vk1033
 * @notice This contract is for creating a sample raffle.
 * @dev Implements Chainlink VRF for randomness.
 */
contract Raffle {
    error Raffle__NotEnoughEth(uint256 sent, uint256 required);

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;

    address payable[] private s_players;
    uint256 private s_lastTimestamp;

    event RafflEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        require(entranceFee > 0, "Entrance fee must be greater than zero");
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth(msg.value, i_entranceFee);
        }
        s_players.push(payable(msg.sender));
        emit RafflEntered(msg.sender);
    }

    function pickWinner() external {
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert();
        }
        // Logic to pick a winner
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
