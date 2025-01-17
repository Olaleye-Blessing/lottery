// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
// import {Owned} from "./Owned.sol";

contract Lottery is VRFConsumerBaseV2Plus {
    /// @title RoundStatus Enum
    /// @notice This enum represents the various statuses a lottery round can have.
    enum RoundStatus {
        /// @notice The round is currently open for ticket purchases.
        /// @dev Players can buy tickets during this status.
        Active,
        /// @notice The round has ended, and the contract is checking the results.
        /// @dev No new tickets can be purchased during this status.
        Checking,
        /// @notice The round has been completed, and all results have been finalized.
        /// @dev Winners have been determined, and prizes have been distributed.
        Completed
    }

    error Lottery__RoundNotActive();
    error Lottery__InvalidTicketPaymentAmount();
    error Lottery__InvalidTicketNumbers(string reason);
    error Lottery__InvalidRound();
    error Lottery__RoundStillActive();
    error Lottery__NotEnoughTicketToPickAWinner();

    event TicketPurchased(address indexed player, uint256 indexed roundId, uint8[6] numbers);
    event RoundExtended(uint256 indexed round);
    event NewRoundStarted(uint256 indexed round);

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 prize;
        uint256 totalTickets;
        uint8[6] winningNumbers;
        RoundStatus status;
    }

    struct Ticket {
        uint8[6] numbers;
        bool claimed;
    }

    struct PlayerRoundInfo {
        Ticket[] tickets;
    }

    /// @dev Depends on the number of requested values that you want sent to the fulfillRandomWords() function.
    /// @dev Storing each word costs about 20,000 gas, so 100,000 is a safe default for this example contract.
    uint32 public constant CALLBACK_GAS_LIMIT = 2_000_000;
    uint256 public constant TOTAL_TICKET_NUMBERS = 6;
    uint8 public constant MAX_NUMBER = 99;
    uint16 private constant VRF_RANDOM_REQUEST_CONFIRMATIONS = 3;
    uint256 public currentRound = 0;
    uint256 public ticketPrice = 0.002 ether;
    uint256 public roundDuration = 7 days;
    uint256 public extendRoundBy = 3 days;
    uint256 public minimumRoundTicket;
    uint256 private immutable i_vrfSubId;
    bytes32 private immutable i_keyHash;

    mapping(uint256 roundId => Round) public rounds;
    mapping(uint256 roundId => mapping(address player => PlayerRoundInfo)) playerRoundData;
    mapping(address player => uint256[]) public playerParticipatedRound;
    mapping(uint256 roundId => uint256 vrfRequestId) private roundRequests;

    constructor(uint256 _minimumRoundTicket, address _vrfCoordinator, uint256 _vrfSubId, bytes32 _keyHash)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        minimumRoundTicket = _minimumRoundTicket;
        i_vrfSubId = _vrfSubId;
        i_keyHash = _keyHash;
        rounds[0] = _initRound(0);
        emit NewRoundStarted(0);
    }

    modifier validRound(uint256 round) {
        if (round > currentRound) revert Lottery__InvalidRound();

        _;
    }

    function buyTicket(uint8[6] calldata numbers) external payable {
        _validateRoundData(1, msg.value);
        _validateTicketNumbers(numbers);
        _processTicketCreation(numbers);

        if (playerParticipatedRound[msg.sender].length == 0) {
            playerParticipatedRound[msg.sender].push(currentRound);
        }
    }

    function buyTickets(uint8[6][] calldata ticketsNumbers) external payable {
        uint256 totalTickets = ticketsNumbers.length;

        _validateRoundData(totalTickets, msg.value);

        uint8 ticketIndex = 0;
        for (ticketIndex; ticketIndex < totalTickets; ticketIndex++) {
            uint8[6] calldata numbers = ticketsNumbers[ticketIndex];
            _validateTicketNumbers(numbers);
            _processTicketCreation(numbers);
        }

        if (playerParticipatedRound[msg.sender].length == 0) {
            playerParticipatedRound[msg.sender].push(currentRound);
        }
    }

    // TODO: Use chainlink automation for this
    function requestWinner() external onlyOwner {
        Round memory _currentRound = rounds[currentRound];

        if (block.timestamp <= _currentRound.endTime) revert Lottery__RoundStillActive();
        if (_currentRound.status != RoundStatus.Active) revert Lottery__RoundNotActive();

        if (_currentRound.totalTickets < minimumRoundTicket) {
            _currentRound.endTime += extendRoundBy;
            emit RoundExtended(currentRound);
            return;
        }

        rounds[currentRound].status = RoundStatus.Checking;
        _getLotteryNumbers();
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        uint8[6] memory winningNumbers;
        uint8 index = 0;
        for (index; index < TOTAL_TICKET_NUMBERS;) {
            winningNumbers[index] = uint8(randomWords[index] % 99);
            unchecked {
                index++;
            }
        }

        Round memory _currentRound = rounds[currentRound];
        _currentRound.winningNumbers = winningNumbers;
        _currentRound.status = RoundStatus.Completed;
        rounds[currentRound] = _currentRound;

        currentRound += 1;
        rounds[currentRound] = _initRound(currentRound);
        emit NewRoundStarted(0);
    }

    function getRoundPlayerTickets(address player) external view returns (Ticket[] memory) {
        return _getRoundPlayerTickets(player, currentRound);
    }

    function getRoundPlayerTickets(address player, uint256 round) external view returns (Ticket[] memory) {
        return _getRoundPlayerTickets(player, round);
    }

    function getRoundData(uint256 round) external view validRound(round) returns (Round memory) {
        return _getRoundData(round);
    }

    function getRoundData() external view returns (Round memory) {
        return _getRoundData(currentRound);
    }

    function getRoundRequestId() external view onlyOwner returns (uint256) {
        return getRoundRequestId(currentRound);
    }

    function getRoundRequestId(uint256 round) public view onlyOwner returns (uint256) {
        return roundRequests[round];
    }

    function _getRoundData(uint256 round) private view returns (Round memory) {
        return rounds[round];
    }

    function _getRoundPlayerTickets(address player, uint256 round) private view returns (Ticket[] memory) {
        return playerRoundData[round][player].tickets;
    }

    function _validateRoundData(uint256 totalTickets, uint256 amountPaid) private view {
        if (totalTickets * ticketPrice != amountPaid) revert Lottery__InvalidTicketPaymentAmount();

        Round memory _currentRound = rounds[currentRound];
        // start -> 1:30 ;;; now -> 2:30 ;;; end -> 4:30
        if (
            !(
                _currentRound.startTime <= block.timestamp && _currentRound.endTime >= block.timestamp
                    && _currentRound.status == RoundStatus.Active
            )
        ) {
            revert Lottery__RoundNotActive();
        }
    }

    function _processTicketCreation(uint8[6] calldata numbers) private {
        Ticket memory newTicket = Ticket({numbers: numbers, claimed: false});
        playerRoundData[currentRound][msg.sender].tickets.push(newTicket);
        rounds[currentRound].prize += ticketPrice;
        rounds[currentRound].totalTickets += 1;

        emit TicketPurchased(msg.sender, currentRound, numbers);
    }

    function _validateTicketNumbers(uint8[6] calldata numbers) private pure {
        if (numbers.length != TOTAL_TICKET_NUMBERS) {
            revert Lottery__InvalidTicketNumbers("Provide a total of 6 numbers");
        }

        uint8 startIndex = 0;
        for (startIndex; startIndex < TOTAL_TICKET_NUMBERS;) {
            if (numbers[startIndex] > MAX_NUMBER) {
                revert Lottery__InvalidTicketNumbers("Provide number between 0 and 99, inclusive");
            }

            for (uint8 j = startIndex + 1; j < TOTAL_TICKET_NUMBERS;) {
                if (numbers[j] == numbers[startIndex]) {
                    revert Lottery__InvalidTicketNumbers("Duplicate numbers detected");
                }

                unchecked {
                    j++;
                }
            }

            unchecked {
                startIndex++;
            }
        }
    }

    function _initRound(uint256 round) private view returns (Round memory) {
        uint8[6] memory winningNumbers;
        return Round({
            id: round,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDuration,
            prize: 0,
            totalTickets: 0,
            winningNumbers: winningNumbers,
            status: RoundStatus.Active
        });
    }

    function _getLotteryNumbers() internal returns (uint256 requestId) {
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_vrfSubId,
                requestConfirmations: VRF_RANDOM_REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: uint32(TOTAL_TICKET_NUMBERS),
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );

        roundRequests[currentRound] = requestId;
    }
}
