// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Lottery} from "./../src/Lottery.sol";
import {DeployLottery} from "./../script/DeployLottery.s.sol";
import {HelperConfig} from "./../script/HelperConfig.s.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    HelperConfig.Config public config;
    uint256 initialTicketPrice;
    uint8[6] private MOCK_CORRECT_RANDOM_NUMBERS = [1, 25, 36, 47, 58, 99];
    uint8[6] private MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2 = [99, 36, 58, 25, 1, 47];
    uint256 private constant EXTEND_ROUND_BY = 3 days;
    uint256 private constant PERFORM_UPKEEP_ROUND_DRAWING = 1;
    uint256 private constant PERFORM_UPKEEP_ROUND_EXTEND = 2;
    uint256 private constant PERFORM_UPKEEP_ROUND_CLAIMABLE = 3;
    uint256 private constant REGISTRATION_WINNING_TICKET_TIMEFRAME = 3 hours;
    address chainlinkAutomationForwarder = makeAddr("CHAINLINK_AUTOMATION_FORWARDER");

    address BLESSING = makeAddr("blessing");
    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address ADAM = makeAddr("adam");
    address DEPLOYER = makeAddr("DEPLOYER");

    function setUp() external {
        vm.deal(BLESSING, 100 ether);
        vm.deal(BOB, 100 ether);
        vm.deal(ALICE, 100 ether);
        vm.deal(DEPLOYER, 100 ether);
        vm.deal(ADAM, 100 ether);

        vm.prank(DEPLOYER);
        (lottery, config) = new DeployLottery().run();
        initialTicketPrice = lottery.ticketPrice();

        vm.startPrank(DEPLOYER);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).addConsumer(config.vrfSubId, address(lottery));

        lottery.setForwarderAddress(chainlinkAutomationForwarder);
        vm.stopPrank();
    }

    function test_roundStartAtZero() external view {
        uint256 currentRound = 0;
        assertEq(lottery.currentRound(), currentRound);
    }

    function test_buyTicketSuccessfully() external {
        uint8[6] memory ticketNumbers = [1, 2, 3, 4, 5, 6];

        vm.startPrank(BLESSING);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.TicketPurchased(BLESSING, 0, ticketNumbers);
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);
    }

    function test_buyTicketsSuccessfully() external {
        uint8[6][] memory ticketsNumbers = new uint8[6][](2);
        ticketsNumbers[0] = [1, 2, 3, 4, 5, 6];
        ticketsNumbers[1] = [8, 2, 3, 4, 5, 6];

        vm.startPrank(BLESSING);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.TicketPurchased(BLESSING, 0, ticketsNumbers[0]);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.TicketPurchased(BLESSING, 0, ticketsNumbers[1]);
        lottery.buyTickets{value: initialTicketPrice * 2}(ticketsNumbers);
    }

    function test_buyTicketRevertIfPlayerDoesNotPay() external {
        uint8[6] memory ticketNumbers = [1, 2, 3, 4, 5, 6];

        vm.startPrank(BLESSING);
        vm.expectRevert(Lottery.Lottery__InvalidTicketPaymentAmount.selector);
        lottery.buyTicket(ticketNumbers);

        uint8[6][] memory ticketsNumbers = new uint8[6][](2);
        ticketsNumbers[0] = [1, 2, 3, 4, 5, 6];
        ticketsNumbers[1] = [8, 2, 3, 4, 5, 6];
        vm.expectRevert(Lottery.Lottery__InvalidTicketPaymentAmount.selector);
        lottery.buyTickets(ticketsNumbers);
    }

    function test_buyTicketRevertIfRoundIsNotActive() external {
        uint8[6] memory ticketNumbers = [1, 2, 3, 4, 5, 6];

        uint8[6][] memory ticketsNumbers = new uint8[6][](2);
        ticketsNumbers[0] = [1, 2, 3, 4, 5, 6];
        ticketsNumbers[1] = [8, 2, 3, 4, 5, 6];

        vm.warp(10 days);

        vm.startPrank(BLESSING);
        vm.expectRevert(Lottery.Lottery__RoundNotActive.selector);
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);

        vm.expectRevert(Lottery.Lottery__RoundNotActive.selector);
        lottery.buyTickets{value: initialTicketPrice * 2}(ticketsNumbers);
    }

    function test_buyTicketRevertIfNumberIfOutOfRange() external {
        uint8[6] memory ticketNumbers = [1, 2, 3, 4, 5, 100];

        vm.startPrank(BLESSING);
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery__InvalidTicketNumbers.selector, "Provide number between 1 and 99, inclusive"
            )
        );
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);
    }

    function test_buyTicketRevertIfThereAreDuplicateNumbers() external {
        uint8[6] memory ticketNumbers = [1, 2, 3, 4, 5, 1];

        vm.startPrank(BLESSING);
        vm.expectRevert(
            abi.encodeWithSelector(Lottery.Lottery__InvalidTicketNumbers.selector, "Duplicate numbers detected")
        );
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);
    }

    function test_getRoundData() external {
        uint256 roundDuration = lottery.roundDuration();
        uint256 defaultAnvilBlocktime = 1;
        Lottery.Round memory round = lottery.getRoundData(0);

        assertEq(round.id, 0);
        assertEq(round.startTime, defaultAnvilBlocktime);
        assertEq(round.endTime, defaultAnvilBlocktime + roundDuration);
        assertEq(round.prize, 0);
        assertEq(round.totalTickets, 0);

        uint8[6] memory ticketNumbers = [1, 2, 3, 4, 5, 6];

        vm.prank(BLESSING);
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);

        Lottery.Round memory updatedRound = lottery.getRoundData(0);

        assertEq(updatedRound.id, 0);
        assertEq(updatedRound.startTime, defaultAnvilBlocktime);
        assertEq(updatedRound.endTime, defaultAnvilBlocktime + roundDuration);
        assertEq(updatedRound.prize, initialTicketPrice);
        assertEq(updatedRound.totalTickets, 1);
    }

    function test_extendRoundDurationWhenFewerTicketsAreBought() external {
        uint256 currentRound = 0;

        Lottery.Round memory round = lottery.getRoundData(0);

        uint256 initialEndTime = round.endTime;

        assertEq(round.totalTickets, 0);

        vm.warp(block.timestamp + lottery.roundDuration() + 1 days);

        (bool upkeepNeeded, bytes memory performData) = lottery.checkUpkeep("");

        assertEq(upkeepNeeded, true);

        vm.prank(chainlinkAutomationForwarder);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.RoundExtended(currentRound);
        lottery.performUpkeep(performData);

        round = lottery.getRoundData(0);

        assertEq(round.endTime, initialEndTime + EXTEND_ROUND_BY);
    }

    function test_drawRound() external {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = [7, 8, 9, 10, 11, 12];
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];

        uint8[6][] memory ticketsNumbers = new uint8[6][](3);
        ticketsNumbers[0] = ticket0;
        ticketsNumbers[1] = ticket1;
        ticketsNumbers[2] = ticket2;

        _buyTickets(BLESSING, ticketsNumbers, currentRound);

        vm.warp(block.timestamp + lottery.roundDuration() + 1 days);

        (, bytes memory performData) = lottery.checkUpkeep("");

        vm.prank(chainlinkAutomationForwarder);
        lottery.performUpkeep(performData);

        Lottery.Round memory round = lottery.getRoundData(currentRound);

        assertEq(uint8(round.status), uint8(Lottery.RoundStatus.Drawing));

        vm.prank(DEPLOYER);
        uint256 requestId = lottery.getRoundRequestId(currentRound);

        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.RoundDrawn(currentRound);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWordsWithOverride(
            requestId, address(lottery), _mockCorrectRandomNumbers()
        );

        round = lottery.getRoundData(currentRound);

        assertEq(round.winningNumbers[0], MOCK_CORRECT_RANDOM_NUMBERS[0]);
        assertEq(round.winningNumbers[1], MOCK_CORRECT_RANDOM_NUMBERS[1]);
        assertEq(round.winningNumbers[2], MOCK_CORRECT_RANDOM_NUMBERS[2]);
        assertEq(round.winningNumbers[3], MOCK_CORRECT_RANDOM_NUMBERS[3]);
        assertEq(round.winningNumbers[4], MOCK_CORRECT_RANDOM_NUMBERS[4]);
        assertEq(round.winningNumbers[5], MOCK_CORRECT_RANDOM_NUMBERS[5]);

        assertEq(uint8(round.status), uint8(Lottery.RoundStatus.RegisterWinningTickets));
    }

    function test_winningTicketsRegisteration() external {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];
        uint8[6] memory ticket3 = MOCK_CORRECT_RANDOM_NUMBERS;

        uint8[6][] memory blessingTicketsNumbers = new uint8[6][](2);
        uint8[6][] memory aliceTicketsNumbers = new uint8[6][](2);

        aliceTicketsNumbers[0] = ticket0;
        aliceTicketsNumbers[1] = ticket1;

        blessingTicketsNumbers[0] = ticket2;
        blessingTicketsNumbers[1] = ticket3;

        _buyTickets(BLESSING, blessingTicketsNumbers, currentRound);
        _buyTickets(ALICE, aliceTicketsNumbers, currentRound);

        uint256 blessingWinningTicketId = 1;
        uint256 aliceWinningTicketId = 3;

        _drawRound(currentRound);

        vm.prank(BLESSING);
        lottery.registerWinningTicket(currentRound, blessingWinningTicketId);

        vm.prank(ALICE);
        lottery.registerWinningTicket(currentRound, aliceWinningTicketId);

        vm.prank(BLESSING);
        vm.expectRevert(Lottery.Lottery__TicketNumberNotTheSameAsRoundNumber.selector);
        lottery.registerWinningTicket(currentRound, 0);

        Lottery.Round memory round = lottery.getRoundData(currentRound);
        assertEq(round.totalWinningTickets, 2);
    }

    function test_registerWinningTicketRevertsIfNotTicketOwner() external {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];

        uint8[6][] memory blessingTicketsNumbers = new uint8[6][](3);

        blessingTicketsNumbers[0] = ticket0;
        blessingTicketsNumbers[1] = ticket1;
        blessingTicketsNumbers[2] = ticket2;

        _buyTickets(BLESSING, blessingTicketsNumbers, currentRound);

        uint256 blessingWinningTicketId = 1;

        _drawRound(currentRound);

        vm.prank(ALICE);
        vm.expectRevert(Lottery.Lottery__TicketNotOwner.selector);
        lottery.registerWinningTicket(currentRound, blessingWinningTicketId);

        Lottery.Round memory round = lottery.getRoundData(currentRound);
        assertEq(round.totalWinningTickets, 0);
    }

    function test_registerWinningTicketRevertsIfDoubleRegistration() external {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];

        uint8[6][] memory blessingTicketsNumbers = new uint8[6][](3);

        blessingTicketsNumbers[0] = ticket0;
        blessingTicketsNumbers[1] = ticket1;
        blessingTicketsNumbers[2] = ticket2;

        _buyTickets(BLESSING, blessingTicketsNumbers, currentRound);

        uint256 blessingWinningTicketId = 1;

        _drawRound(currentRound);

        vm.prank(BLESSING);
        lottery.registerWinningTicket(currentRound, blessingWinningTicketId);

        vm.prank(BLESSING);
        vm.expectRevert(Lottery.Lottery__TicketHasBeenRegistered.selector);
        lottery.registerWinningTicket(currentRound, blessingWinningTicketId);

        Lottery.Round memory round = lottery.getRoundData(currentRound);
        assertEq(round.totalWinningTickets, 1);
    }

    function test_registerWinningTicketRevertsIfNotTimeForRegistration() external {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];

        uint8[6][] memory blessingTicketsNumbers = new uint8[6][](3);

        blessingTicketsNumbers[0] = ticket0;
        blessingTicketsNumbers[1] = ticket1;
        blessingTicketsNumbers[2] = ticket2;

        _buyTickets(BLESSING, blessingTicketsNumbers, currentRound);

        uint256 blessingWinningTicketId = 1;

        Lottery.Round memory round = lottery.getRoundData(currentRound);

        vm.prank(BLESSING);
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery__IncorrectRoundStatus.selector,
                uint8(round.status),
                uint8(Lottery.RoundStatus.RegisterWinningTickets),
                ""
            )
        );
        lottery.registerWinningTicket(currentRound, blessingWinningTicketId);
    }

    function test_ClaimWinningTicket() external {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];
        uint8[6] memory ticket3 = MOCK_CORRECT_RANDOM_NUMBERS;

        uint8[6][] memory blessingTicketsNumbers = new uint8[6][](2);
        uint8[6][] memory aliceTicketsNumbers = new uint8[6][](2);

        aliceTicketsNumbers[0] = ticket0;
        aliceTicketsNumbers[1] = ticket1;

        blessingTicketsNumbers[0] = ticket2;
        blessingTicketsNumbers[1] = ticket3;

        _buyTickets(BLESSING, blessingTicketsNumbers, currentRound);
        _buyTickets(ALICE, aliceTicketsNumbers, currentRound);

        uint256 blessingWinningTicketId = 1;
        uint256 aliceWinningTicketId = 3;

        _drawRound(currentRound);

        vm.prank(BLESSING);
        lottery.registerWinningTicket(currentRound, blessingWinningTicketId);

        vm.prank(ALICE);
        lottery.registerWinningTicket(currentRound, aliceWinningTicketId);

        _makeRoundClaimable();

        uint256 blessingBalance = BLESSING.balance;

        uint256 expectedRoundPrize = lottery.ticketPrice() * 4;
        // fee% * 0.002 * 4 participants
        // 1% * 0.008 ether
        // fee * 0.008 ether => 1% * 0.004 ether = 4e13
        uint256 expectedFee = 8e13;
        uint256 prizePerWinner = (expectedRoundPrize - expectedFee) / 2;

        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.PrizeClaimed(0, BLESSING, blessingWinningTicketId, prizePerWinner);
        vm.prank(BLESSING);
        lottery.claimPrize(0, blessingWinningTicketId);

        assertEq(BLESSING.balance, blessingBalance + prizePerWinner);
    }

    function test_claimPrizeRevertIfClaimTwice() external {
        uint256 currentRound = 0;

        uint256 blessingWinningTicketId = 1;

        _buyTicketsAndMakeClaimable(BLESSING);

        uint256 expectedRoundPrize = lottery.ticketPrice() * 4;
        // fee% * 0.002 * 4 participants
        // 1% * 0.008 ether
        // fee * 0.008 ether => 1% * 0.004 ether = 4e13
        uint256 expectedFee = 8e13;
        uint256 prizePerWinner = (expectedRoundPrize - expectedFee) / 2;

        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.PrizeClaimed(currentRound, BLESSING, blessingWinningTicketId, prizePerWinner);
        vm.prank(BLESSING);
        lottery.claimPrize(currentRound, blessingWinningTicketId);

        vm.prank(BLESSING);
        vm.expectRevert(Lottery.Lottery__TicketHasBeenClaimed.selector);
        lottery.claimPrize(currentRound, blessingWinningTicketId);
    }

    function test_claimPrizeRevertIfNotOwner() external {
        uint256 currentRound = 0;

        uint256 blessingWinningTicketId = 1;

        _buyTicketsAndMakeClaimable(BLESSING);

        vm.prank(ALICE);
        vm.expectRevert(Lottery.Lottery__TicketNotOwner.selector);
        lottery.claimPrize(currentRound, blessingWinningTicketId);
    }

    function test_movePrizeToNextRoundIfThereIsNoRegisteredWinner() external {
        uint256 currentRoundID = 0;

        _buytTicketsAndMakeClaimableWithoutRegistration(BLESSING); // this function buys 4 tickets
        uint256 ticketsBought = 4;
        uint256 roundPoolPrize = ticketsBought * initialTicketPrice;

        uint256 newRoundID = 1;

        Lottery.Round memory prevRound = lottery.getRoundData(currentRoundID);
        Lottery.Round memory newRound = lottery.getRoundData(newRoundID);

        assertEq(uint8(prevRound.status), uint8(Lottery.RoundStatus.Claimable));
        assertEq(newRound.id, newRoundID);
        assertEq(newRound.prize, roundPoolPrize);
        assertEq(newRound.totalTickets, 0);
        assertEq(uint8(newRound.status), uint8(Lottery.RoundStatus.Active));
    }

    function _buyTicket(address owner, uint8[6] memory ticketNumbers, uint256 round) internal {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.TicketPurchased(owner, round, ticketNumbers);
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);
    }

    function _buyTicket(address owner, uint8[6] memory ticketNumbers) internal {
        _buyTicket(owner, ticketNumbers, 0);
    }

    function _buyTickets(address owner, uint8[6][] memory ticketsNumbers, uint256 round) private {
        uint256 totalTickets = ticketsNumbers.length;
        vm.prank(owner);

        for (uint256 index = 0; index < totalTickets; index++) {
            vm.expectEmit(true, true, true, true, address(lottery));
            emit Lottery.TicketPurchased(owner, round, ticketsNumbers[index]);
        }

        lottery.buyTickets{value: initialTicketPrice * totalTickets}(ticketsNumbers);
    }

    function _drawRound(uint256 round) private returns (bool upkeepNeeded, bytes memory performData) {
        vm.warp(block.timestamp + lottery.roundDuration() + 1 days);

        (upkeepNeeded, performData) = lottery.checkUpkeep("");

        vm.prank(chainlinkAutomationForwarder);
        lottery.performUpkeep(performData);

        vm.prank(DEPLOYER);
        uint256 requestId = lottery.getRoundRequestId(round);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWordsWithOverride(
            requestId, address(lottery), _mockCorrectRandomNumbers()
        );

        return (upkeepNeeded, performData);
    }

    function _makeRoundClaimable() private returns (bool upkeepNeeded, bytes memory performData) {
        vm.warp(block.timestamp + REGISTRATION_WINNING_TICKET_TIMEFRAME + 1 seconds);

        (upkeepNeeded, performData) = lottery.checkUpkeep("");
        vm.prank(chainlinkAutomationForwarder);
        lottery.performUpkeep(performData);

        return (upkeepNeeded, performData);
    }

    function _buyTicketsAndMakeClaimable(address owner) private {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];
        uint8[6] memory ticket3 = MOCK_CORRECT_RANDOM_NUMBERS;

        uint8[6][] memory ownerTicketsNumbers = new uint8[6][](4);

        ownerTicketsNumbers[0] = ticket0;
        ownerTicketsNumbers[1] = ticket1;
        ownerTicketsNumbers[2] = ticket2;
        ownerTicketsNumbers[3] = ticket3;

        _buyTickets(owner, ownerTicketsNumbers, currentRound);

        uint256 ownerWinningTicketId = 1;
        uint256 ownerSecondWinningTicketId = 3;

        _drawRound(currentRound);

        vm.prank(owner);
        lottery.registerWinningTicket(currentRound, ownerWinningTicketId);

        vm.prank(owner);
        lottery.registerWinningTicket(currentRound, ownerSecondWinningTicketId);

        _makeRoundClaimable();
    }

    function _buytTicketsAndMakeClaimableWithoutRegistration(address owner) private {
        uint256 currentRound = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        uint8[6] memory ticket2 = [2, 3, 45, 67, 88, 99];
        uint8[6] memory ticket3 = MOCK_CORRECT_RANDOM_NUMBERS;

        uint8[6][] memory ownerTicketsNumbers = new uint8[6][](4);

        ownerTicketsNumbers[0] = ticket0;
        ownerTicketsNumbers[1] = ticket1;
        ownerTicketsNumbers[2] = ticket2;
        ownerTicketsNumbers[3] = ticket3;

        _buyTickets(owner, ownerTicketsNumbers, currentRound);

        _drawRound(currentRound);

        _makeRoundClaimable();
    }

    function _mockCorrectRandomNumbers() private view returns (uint256[] memory) {
        uint256[] memory randomWords = new uint256[](6);

        // uint8[6] private MOCK_CORRECT_RANDOM_NUMBERS = [1, 25, 36, 47, 58, 99];
        // MOCK_CORRECT_RANDOM_NUMBERS[0] = 1
        // 98 + 1 = 99
        // 99 will be provided by chainlink
        // lottery will do this: uint8(randomWords[index] % 99) + 1; (check fulfillRandomWords function)
        // this in turn gives the MOCK_CORRECT_RANDOM_NUMBERS
        for (uint256 index = 0; index < 6; index++) {
            randomWords[index] = 98 + uint256(MOCK_CORRECT_RANDOM_NUMBERS[index]);
        }

        return randomWords;
    }
}
