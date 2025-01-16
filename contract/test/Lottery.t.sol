// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "./../src/Lottery.sol";
import {DeployLottery} from "./../script/DeployLottery.s.sol";

contract LotteryTest is Test {
    Lottery public lottery;
    uint256 initialTicketPrice;
    address BLESSING = makeAddr("blessing");

    function setUp() external {
        vm.deal(BLESSING, 100 ether);
        lottery = new DeployLottery().run();
        initialTicketPrice = lottery.ticketPrice();
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
}
