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
    uint8[6] private MOCK_CORRECT_RANDOM_NUMBERS = [32, 78, 61, 97, 0, 46];
    uint8[6] private MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2 = [78, 32, 61, 0, 46, 97];
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
        vm.prank(DEPLOYER);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).addConsumer(config.vrfSubId, address(lottery));
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
                Lottery.Lottery__InvalidTicketNumbers.selector, "Provide number between 0 and 99, inclusive"
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

    function test_requestWinner() external {
        uint8[6] memory blessingTicketNumbers = [1, 2, 3, 4, 5, 6];
        _buyTicket(BLESSING, blessingTicketNumbers);
        uint8[6] memory bobTicketNumbers = [7, 8, 9, 10, 11, 12];
        _buyTicket(BOB, bobTicketNumbers);
        uint8[6] memory aliceTicketNumbers = [30, 31, 32, 44, 67, 34];
        _buyTicket(ALICE, aliceTicketNumbers);

        vm.warp(lottery.roundDuration() + 1 days);

        vm.startPrank(DEPLOYER);

        lottery.requestWinner();
        uint256 requestId = lottery.getRoundRequestId(0);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(requestId, address(lottery));

        vm.stopPrank();

        Lottery.Round memory currentRound = lottery.getRoundData(0);

        assertEq(uint256(currentRound.status), uint256(Lottery.RoundStatus.RegisterWinningTickets));
    }

    function test_onlyContractOwnerCanRequestWinner() external {
        uint8[6] memory blessingTicketNumbers = [1, 2, 3, 4, 5, 6];
        _buyTicket(BLESSING, blessingTicketNumbers);
        uint8[6] memory bobTicketNumbers = [7, 8, 9, 10, 11, 12];
        _buyTicket(BOB, bobTicketNumbers);
        uint8[6] memory aliceTicketNumbers = [30, 31, 32, 44, 67, 34];
        _buyTicket(ALICE, aliceTicketNumbers);

        vm.warp(lottery.roundDuration() + 1 days);

        vm.startPrank(BLESSING);
        vm.expectRevert("Only callable by owner");
        lottery.requestWinner();
    }

    function test_registerWinningTickets() external {
        uint256 roundId = 0;

        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = [7, 8, 9, 10, 11, 12];
        uint8[6] memory ticket2 = MOCK_CORRECT_RANDOM_NUMBERS;

        uint256 tickeidWithCorrectNumbers = 2;

        uint8[6][] memory ticketsNumbers = new uint8[6][](3);
        ticketsNumbers[0] = ticket0;
        ticketsNumbers[1] = ticket1;
        ticketsNumbers[2] = ticket2;
        _buyAndRequestRandomNumber(roundId, BLESSING, ticketsNumbers);

        vm.prank(BLESSING);
        lottery.registerWinningTicket(roundId, tickeidWithCorrectNumbers);
    }

    function test_registerWinningTicketRevertsIfNotTicketOwner() external {
        uint256 roundId = 0;

        _buyAndRequestRandomNumber(roundId, BLESSING);

        vm.prank(BOB);
        vm.expectRevert(Lottery.Lottery__TicketNotOwner.selector);
        lottery.registerWinningTicket(roundId, 2);
    }

    function test_registerWinningTicketRevertsIfNotInCorrectStatus() external {
        uint8[6] memory blessingTicketNumbers = [1, 2, 3, 4, 5, 6];
        _buyTicket(BLESSING, blessingTicketNumbers);

        uint256 roundId = 0;
        uint256 ticketId = 0;

        Lottery.Round memory currentRound = lottery.getRoundData(roundId);

        vm.prank(BLESSING);
        vm.expectRevert(
            abi.encodeWithSelector(
                Lottery.Lottery__IncorrectRoundStatus.selector,
                currentRound.status,
                Lottery.RoundStatus.RegisterWinningTickets,
                ""
            )
        );
        lottery.registerWinningTicket(roundId, ticketId);
    }

    function test_claimPrize() external {
        uint256 roundId = 0;
        uint8[6] memory blessingTicketNumbers = [1, 2, 3, 4, 5, 6];
        _buyTicket(BLESSING, blessingTicketNumbers);
        uint8[6] memory bobTicketNumbers = MOCK_CORRECT_RANDOM_NUMBERS;
        _buyTicket(BOB, bobTicketNumbers);
        uint8[6] memory aliceTicketNumbers = [30, 31, 32, 44, 67, 34];
        _buyTicket(ALICE, aliceTicketNumbers);
        uint8[6] memory adamTicketNumbers = MOCK_CORRECT_RANDOM_NUMBERS_ORDER_2;
        _buyTicket(ADAM, adamTicketNumbers);

        uint256 BOB_TICKET_ID = 1;
        uint256 ADAM_TICKET_ID = 3;

        vm.warp(lottery.roundDuration() + 1 days);

        vm.startPrank(DEPLOYER);

        lottery.requestWinner();
        uint256 requestId = lottery.getRoundRequestId(roundId);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(requestId, address(lottery));

        vm.stopPrank();

        vm.prank(BOB);
        lottery.registerWinningTicket(roundId, BOB_TICKET_ID);
        vm.prank(ADAM);
        lottery.registerWinningTicket(roundId, ADAM_TICKET_ID);

        vm.warp(block.timestamp + lottery.registerWinningTicketTimeframe() + 2 seconds);

        vm.prank(DEPLOYER);
        lottery.makeRoundPrizeClaimable(roundId);

        uint256 bobBalance = BOB.balance;

        uint256 expectedRoundPrize = lottery.ticketPrice() * 4;
        // fee% * 0.002 * 4 participants
        // 1% * 0.008 ether
        // fee * 0.008 ether => 1% * 0.004 ether = 4e13
        uint256 expectedFee = 8e13;
        uint256 prizePerWinner = (expectedRoundPrize - expectedFee) / 2;

        // claim prize
        vm.prank(BOB);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.PrizeClaimed(roundId, BOB, BOB_TICKET_ID, prizePerWinner);
        lottery.claimPrize(roundId, BOB_TICKET_ID);

        uint256 bobNewBalance = BOB.balance;

        assertEq(bobNewBalance, bobBalance + prizePerWinner);
    }

    function test_claimPrizeRevertIfClaimTwice() external {
        uint256 roundId = 0;
        _buyRequestAndMakeRoundClaimable(BOB);
        uint256 winningTicketId = 2;

        uint256 bobBalance = BOB.balance;

        uint256 expectedRoundPrize = lottery.ticketPrice() * 3;
        uint256 expectedFee = 6e13;
        uint256 prizePerWinner = (expectedRoundPrize - expectedFee) / 1;

        // claim prize
        vm.prank(BOB);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.PrizeClaimed(roundId, BOB, winningTicketId, prizePerWinner);
        lottery.claimPrize(roundId, winningTicketId);

        uint256 bobNewBalance = BOB.balance;
        assertEq(bobNewBalance, bobBalance + prizePerWinner);

        vm.prank(BOB);
        vm.expectRevert(Lottery.Lottery__TicketHasBeenClaimed.selector);
        lottery.claimPrize(roundId, winningTicketId);
    }

    function test_claimPrizeRevertIfNotOwner() external {
        uint256 roundId = 0;
        _buyRequestAndMakeRoundClaimable(BOB);
        uint256 winningTicketId = 2;
        
        vm.prank(BLESSING);
        vm.expectRevert(Lottery.Lottery__TicketNotOwner.selector);
        lottery.claimPrize(roundId, winningTicketId);
    }

    function test_claimPrizeRevertIfNotRegistered() external {
        uint256 roundId = 0;
        uint256 winningTicketId = 2;

        _buyAndRequestRandomNumber(roundId, BLESSING);

        vm.warp(block.timestamp + lottery.registerWinningTicketTimeframe() + 2 seconds);

        vm.prank(DEPLOYER);
        lottery.makeRoundPrizeClaimable(roundId);

        vm.prank(BLESSING);
        vm.expectRevert(Lottery.Lottery__TicketNotRegistered.selector);
        lottery.claimPrize(roundId, winningTicketId);
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

    function _buyAndRequestRandomNumber(uint256 roundId, address owner) private {
        uint8[6] memory ticket0 = [1, 2, 3, 4, 5, 6];
        uint8[6] memory ticket1 = [7, 8, 9, 10, 11, 12];
        uint8[6] memory ticket2 = MOCK_CORRECT_RANDOM_NUMBERS;

        uint8[6][] memory ticketsNumbers = new uint8[6][](3);
        ticketsNumbers[0] = ticket0;
        ticketsNumbers[1] = ticket1;
        ticketsNumbers[2] = ticket2;

        _buyAndRequestRandomNumber(roundId, owner, ticketsNumbers);
    }

    function _buyAndRequestRandomNumber(uint256 roundId, address owner, uint8[6][] memory ticketsNumbers) private {
        _buyTickets(owner, ticketsNumbers, roundId);

        vm.warp(lottery.roundDuration() + 1 days);

        vm.startPrank(DEPLOYER);

        lottery.requestWinner();
        uint256 requestId = lottery.getRoundRequestId(roundId);
        VRFCoordinatorV2_5Mock(config.vrfCoordinator).fulfillRandomWords(requestId, address(lottery));

        vm.stopPrank();
    }

    function _buyRequestAndMakeRoundClaimable(address owner) private {
        uint256 roundId = 0;
        _buyAndRequestRandomNumber(roundId, owner);

        uint256 winningTicketId = 2;

        vm.prank(owner);
        lottery.registerWinningTicket(roundId, winningTicketId);

        vm.warp(block.timestamp + lottery.registerWinningTicketTimeframe() + 2 seconds);

        vm.prank(DEPLOYER);
        lottery.makeRoundPrizeClaimable(roundId);
    }
}
