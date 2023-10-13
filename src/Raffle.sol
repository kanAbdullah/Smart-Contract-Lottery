// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


// SPDX-License-Identifier: MIT

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

pragma solidity ^0.8.18;
/**
 * @title A sample raffle contract
 * @author Abdullah Kan
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 * CEI: Checks-Effects-Interactions(with other contracts)
 */

contract Raffle is VRFConsumerBaseV2 {

    error Raffle__NotEnoughETHSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 RaffleState
    );
    /* Type Declarations */

    enum RaffleState {
        OPEN,
        CALCULATING_WINNER
    }

    /* State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3; 
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;

    //@dev duration of the lottery
    uint256 private immutable i_interval;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callBackGasLimit;

    address payable[] private s_players; //payable keyword allows us to pay to players

    uint256 deneme_kontrol = 0;

    address private s_recentWinner;
    uint256 private s_lastTimeStamp;
    RaffleState private s_raffleState;

    /* Events */
    event enteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callBackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator){
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_interval = interval;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callBackGasLimit = callBackGasLimit;
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }
    
    function enterRaffle() public payable {
    /**
     * The bottom code is more gas efficient 
     */
        //require(msg.value >= i_entranceFee, "not enough ETH");
        if(s_raffleState != RaffleState.OPEN)
            revert Raffle__RaffleNotOpen();
        if(msg.value < i_entranceFee)
            revert Raffle__NotEnoughETHSent();
        
        s_players.push(payable(msg.sender));

        emit enteredRaffle(msg.sender);
    }

    //1.get a random number
    //2.pick the winner
    //3.Be automatically called

    function checkUpkeep(
        bytes memory /*checkData */
    )public /*view**/ returns (bool upkeepNeeded, bytes memory /*performData */){
        
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > i_interval;
        bool isRaffleOpen = RaffleState.OPEN == s_raffleState;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
    
        upkeepNeeded = (timeHasPassed && isRaffleOpen && hasBalance && hasPlayers);

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external{

        (bool upkeepNeeded,) = checkUpkeep("");
    
        if(!upkeepNeeded){
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING_WINNER;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callBackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }
/**
 * in VRFConsumerBaseV2.sol in constructor we have to pass 
 * the address of vrfCoordinator, because raffle is inherited
 * from VRFConsumerBaseV2 we have to pass the constructor arguments
 * in Raffle constructor.
 * 
 * vrfCoordinator calls rawFulfillRandomWords function
 * which calls fulfillRandomWords function 
 */
    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;

        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(winner);

        (bool success,) = winner.call{value: address(this).balance}("");
        if(!success)
            revert Raffle__TransferFailed();
    }

    /* Getter Functions*/

    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
    
    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns(address){
        return s_players[indexOfPlayer];
    }

    function getRecentWinner() external view returns(address){
        return s_recentWinner;
    }

    function getLengthOfPlayers() external view returns(uint256){
        return s_players.length;
    }

    function getLastTimeStamp() public view returns(uint256){
        return s_lastTimeStamp;
    }

    function getDenemeKontrol() public view returns(uint256){
        return deneme_kontrol;
    }
}