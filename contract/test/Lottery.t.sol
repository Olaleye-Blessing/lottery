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
    address BLESSING = makeAddr("blessing");
    address BOB = makeAddr("bob");
    address ALICE = makeAddr("alice");
    address DEPLOYER = makeAddr("DEPLOYER");

    function setUp() external {
        vm.deal(BLESSING, 100 ether);
        vm.deal(BOB, 100 ether);
        vm.deal(ALICE, 100 ether);
        vm.deal(DEPLOYER, 100 ether);
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

        assertEq(uint256(currentRound.status), uint256(Lottery.RoundStatus.Completed));
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

    function _buyTicket(address owner, uint8[6] memory ticketNumbers, uint256 round) internal {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true, address(lottery));
        emit Lottery.TicketPurchased(owner, round, ticketNumbers);
        lottery.buyTicket{value: initialTicketPrice}(ticketNumbers);
    }

    function _buyTicket(address owner, uint8[6] memory ticketNumbers) internal {
        _buyTicket(owner, ticketNumbers, 0);
    }
}
