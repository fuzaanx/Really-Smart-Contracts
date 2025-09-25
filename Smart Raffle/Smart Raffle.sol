// Smart Contract #1

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Decentralized Raffle Contract
 * @author FuzaanX
 * @notice This contract implements a fair, decentralized raffle system using Chainlink VRF for randomness and Automation for timed execution.
 * @dev Extends Chainlink's VRF and Automation interfaces for verifiable randomness and upkeep. This is useful for everybody as it provides a transparent lottery system where anyone can participate in fair draws without trusting a central authority. It can be used for community giveaways, charity lotteries, or prize distributions.
 * 
 * Best Practices:
 * - Uses custom errors for gas efficiency instead of require statements.
 * - Implements Chainlink VRF v2.5 for secure randomness to prevent manipulation.
 * - Leverages Chainlink Automation for automatic winner selection after intervals.
 * - Handles edge cases like no players, insufficient funds, and state transitions.
 * - Includes events for traceability and frontend integration.
 * - View functions for transparency.
 * 
 * Potential Improvements:
 * - Add multi-winner support or prize tiers.
 * - Integrate with ERC20 tokens for entrance fees in custom currencies.
 * - Use upgradeable proxies for future-proofing (e.g., via OpenZeppelin).
 * 
 * Error Handling:
 * - Reverts with specific errors for invalid states, insufficient payments, etc.
 * - Ensures contract balance is transferred only on success.
 */
contract DecentralizedRaffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /* Custom Errors */
    error Raffle__NotEnoughEntranceFee();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersCount, uint256 raffleState);
    error Raffle__TransferFailed();
    error Raffle__NoPlayers();

    /* Type Declarations */
    enum RaffleState {
        OPEN,      // Accepting entries
        CALCULATING // Processing winner
    }

    /* Immutable Variables (set once in constructor for gas savings) */
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;

    /* Constants */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    /* State Variables */
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerRequested(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /**
     * @dev Constructor initializes the raffle parameters and Chainlink configurations.
     * @param entranceFee Minimum ETH required to enter (in wei).
     * @param interval Time between raffles in seconds.
     * @param subscriptionId Chainlink VRF subscription ID.
     * @param gasLane Chainlink VRF gas lane key hash.
     * @param callbackGasLimit Gas limit for VRF callback.
     * @param vrfCoordinator Address of the Chainlink VRF Coordinator.
     */
    constructor(
        uint256 entranceFee,
        uint256 interval,
        uint256 subscriptionId,
        bytes32 gasLane,
        uint32 callbackGasLimit,
        address vrfCoordinator
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        i_gasLane = gasLane;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimestamp = block.timestamp;
    }

    /**
     * @notice Allows users to enter the raffle by paying the entrance fee.
     * @dev Adds sender to players array if conditions are met. Emits event for tracking.
     */
    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEntranceFee();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Chainlink Automation check: Determines if upkeep (winner selection) is needed.
     * @notice Called by Chainlink nodes to check conditions.
     * @return upkeepNeeded True if raffle is ready for winner selection.
     * @return performData Arbitrary data (unused here).
     */
    function checkUpkeep(bytes memory /* checkData */) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "");
    }

    /**
     * @dev Chainlink Automation perform: Requests random number if upkeep is needed.
     * @notice Transitions state to CALCULATING and requests VRF.
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_gasLane,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        emit WinnerRequested(requestId);
    }

    /**
     * @dev VRF callback: Selects and pays winner using random words.
     * @notice Resets raffle state, clears players, updates timestamp, and transfers prize.
     * @param randomWords Array of random numbers from VRF.
     */
    function fulfillRandomWords(uint256 /* requestId */, uint256[] calldata randomWords) internal override {
        if (s_players.length == 0) {
            revert Raffle__NoPlayers();
        }
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(winner);
    }

    /* View & Pure Functions for Transparency */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getNumberOfPlayers() external view returns (uint256) {
        return s_players.length;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimestamp;
    }

    function getInterval() external view returns (uint256) {
        return i_interval;
    }
}
