// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title Raffle contract
 * @author Vk1033
 * @notice This contract is for creating a sample raffle.
 * @dev Implements Chainlink VRF for randomness.
 */
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEth(uint256 sent, uint256 required);
    error Raffle__NotEnoughTimeElapsed(uint256 elapsed, uint256 required);
    error Raffle__TransferFailed(address winner, uint256 amount);
    error Raffle__RaffleNotOpen();

    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    RaffleState private s_raffleState;

    event RafflEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        require(entranceFee > 0, "Entrance fee must be greater than zero");
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth(msg.value, i_entranceFee);
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RafflEntered(msg.sender);
    }

    function pickWinner() external returns (uint256) {
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert Raffle__NotEnoughTimeElapsed(block.timestamp - s_lastTimestamp, i_interval);
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        return requestId;
    }

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] calldata randomWords) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_players = new address payable[](0); // Reset players for the next raffle
        s_lastTimestamp = block.timestamp;
        s_raffleState = RaffleState.OPEN; // Reset raffle state to OPEN
        emit WinnerPicked(winner); // Emit event for the winner

        (bool success,) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed(winner, address(this).balance);
        }
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
}
