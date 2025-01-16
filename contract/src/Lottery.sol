// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract Lottery {
    error Lottery__RoundNotActive();
    error Lottery__InvalidTicketPaymentAmount();
    error Lottery__InvalidTicketNumbers(string reason);
    error Lottery__InvalidRound();

    event TicketPurchased(address indexed player, uint256 indexed roundId, uint8[6] numbers);

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 prize;
        uint256 totalTickets;
    }

    struct Ticket {
        uint8[6] numbers;
        bool claimed;
    }

    struct PlayerRoundInfo {
        Ticket[] tickets;
    }

    uint256 public constant TOTAL_TICKET_NUMBERS = 6;
    uint8 public constant MAX_NUMBER = 99;
    uint256 public currentRound = 0;
    uint256 public ticketPrice = 0.002 ether;
    uint256 public roundDuration = 7 days;
    uint256 public minimumRoundTicket;

    mapping(uint256 roundId => Round) public rounds;
    mapping(uint256 roundId => mapping(address player => PlayerRoundInfo)) playerRoundData;
    mapping(address player => uint256[]) public playerParticipatedRound;

    constructor(uint256 _minimumRoundTicket) {
        minimumRoundTicket = _minimumRoundTicket;
        rounds[0] = Round({
            id: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + roundDuration,
            prize: 0,
            totalTickets: 0
        });
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
        if (!(_currentRound.startTime <= block.timestamp && _currentRound.endTime >= block.timestamp)) {
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
}
