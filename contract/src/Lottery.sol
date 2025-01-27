// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {console} from "forge-std/console.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";

contract Lottery is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /// @title RoundStatus Enum
    /// @notice This enum represents the various statuses a lottery round can have.
    enum RoundStatus {
        /// @notice The round is currently open for ticket purchases.
        /// @dev Players can buy tickets during this status.
        Active,
        /// @notice The round has eneded and the contract is generating the lucky numbers
        Drawing,
        /// @notice Winning tickets need to register their ticket for payout within the timefrme.
        /// @dev Calculate the amount each ticket is entitled to.
        RegisterWinningTickets,
        /// @notice Winning tickets can claim their prices
        Claimable
    }

    error Lottery__RoundNotActive();
    error Lottery__InvalidTicketPaymentAmount();
    error Lottery__InvalidTicketNumbers(string reason);
    error Lottery__InvalidRound();
    error Lottery__RoundStillActive();
    error Lottery__NotEnoughTicketToPickAWinner();
    error Lottery__IncorrectRoundStatus(RoundStatus current, RoundStatus expected, string message);
    error Lottery__TicketHasBeenClaimed();
    error Lottery__TicketHasBeenRegistered();
    error Lottery__TicketNotRegistered();
    error Lottery__TicketNotOwner();
    error Lottery__FundTransferFailed();
    error Lottery__TooEarlyForWinningTicketTime();
    error Lottery__TicketNumberNotTheSameAsRoundNumber();

    event TicketPurchased(address indexed player, uint256 indexed roundId, uint8[6] numbers);
    event RoundExtended(uint256 indexed round);
    event NewRoundStarted(uint256 indexed round);
    event RoundClaimable(uint256 indexed round);
    event PrizeClaimed(uint256 indexed roundId, address indexed player, uint256 indexed ticketId, uint256 amount);

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 registerWinningTicketTime;
        uint256 prize;
        uint256 totalTickets;
        uint256 totalWinningTickets;
        uint8[6] winningNumbers;
        RoundStatus status;
    }

    struct Ticket {
        uint8[6] numbers;
        bool claimed;
        bool resgistered;
        address player;
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
    uint256 private constant ZEROS_PRECISION = 1e18;
    uint256 private constant PERFORM_UPKEEP_ROUND_DRAWING = 1;
    uint256 private constant PERFORM_UPKEEP_ROUND_EXTEND = 2;
    uint256 private constant PERFORM_UPKEEP_ROUND_CLAIMABLE = 3;
    uint256 public currentRound = 0;
    uint256 public lotteryFee = 1e16; // 1%;
    uint256 public ticketPrice = 0.002 ether;
    uint256 public roundDuration = 7 days;
    uint256 public extendRoundBy = 3 days;
    uint256 public registerWinningTicketTimeframe = 3 hours;
    uint256 public minimumRoundTicket;
    uint256 private immutable i_vrfSubId;
    bytes32 private immutable i_keyHash;

    mapping(uint256 roundId => Round) public rounds;
    mapping(uint256 roundId => mapping(uint256 ticketId => Ticket ticket)) private roundTickets;
    mapping(uint256 roundId => mapping(address player => uint256[] ticketIds)) private playerTickets;
    mapping(address player => uint256[] roundIds) public playerRounds;
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
        _processTicketCreation(numbers, msg.sender);

        _updatePlayerRounds(msg.sender);
    }

    function buyTickets(uint8[6][] calldata ticketsNumbers) external payable {
        uint256 totalTickets = ticketsNumbers.length;

        _validateRoundData(totalTickets, msg.value);

        uint8 ticketIndex = 0;
        for (ticketIndex; ticketIndex < totalTickets; ticketIndex++) {
            uint8[6] calldata numbers = ticketsNumbers[ticketIndex];
            _validateTicketNumbers(numbers);
            _processTicketCreation(numbers, msg.sender);
        }

        _updatePlayerRounds(msg.sender);
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        Round memory _currentRound = rounds[currentRound];

        if (_currentRound.status == RoundStatus.Drawing) return (false, "");

        // now = 7:30
        // end time = 8:30
        // register winning ticket = 15:30
        bool drawRound = _currentRound.status == RoundStatus.Active && block.timestamp > _currentRound.endTime;
        if (drawRound) {
            if (_currentRound.totalTickets < minimumRoundTicket) {
                return (true, abi.encode(PERFORM_UPKEEP_ROUND_EXTEND));
            }

            return (true, abi.encode(PERFORM_UPKEEP_ROUND_DRAWING));
        }

        bool makeRoundPrizeClaimable = _currentRound.status == RoundStatus.RegisterWinningTickets
            && block.timestamp > _currentRound.registerWinningTicketTime;

        if (makeRoundPrizeClaimable) {
            return (true, abi.encode(PERFORM_UPKEEP_ROUND_CLAIMABLE));
        }

        return (false, "");
    }

    function performUpkeep(bytes calldata performData) external {
        (bool performAction,) = checkUpkeep("");

        if (!performAction) return;

        uint256 action = abi.decode(performData, (uint256));

        if (action == PERFORM_UPKEEP_ROUND_EXTEND) {
            _extendRound();
        } else if (action == PERFORM_UPKEEP_ROUND_DRAWING) {
            _getLotteryNumbers();
        } else if (action == PERFORM_UPKEEP_ROUND_CLAIMABLE) {
            _makeRoundPrizeClaimable();
        }
    }

    function registerWinningTicket(uint256 roundId, uint256 ticketId) external {
        Round memory _round = rounds[roundId];

        if (_round.status != RoundStatus.RegisterWinningTickets) {
            revert Lottery__IncorrectRoundStatus(_round.status, RoundStatus.RegisterWinningTickets, "");
        }

        Ticket memory ticket = roundTickets[roundId][ticketId];

        if (ticket.resgistered) revert Lottery__TicketHasBeenRegistered();
        if (ticket.claimed) revert Lottery__TicketHasBeenClaimed();

        if (ticket.player != msg.sender) revert Lottery__TicketNotOwner();

        uint8[6] memory roundNumbers = _round.winningNumbers; // [1, 2, 3, 4, 5, 6]
        uint8[6] memory ticketNumbers = ticket.numbers; // [6, 5, 4, 3, 2, 1]

        _validateWinningTicket(roundNumbers, ticketNumbers);

        ticket.resgistered = true;
        roundTickets[roundId][ticketId] = ticket;
        _round.totalWinningTickets += 1;

        rounds[roundId] = _round;
    }

    function _makeRoundPrizeClaimable() private {
        Round memory _round = rounds[currentRound];

        uint256 fee = (_round.prize * lotteryFee) / ZEROS_PRECISION;
        (bool success,) = payable(owner()).call{value: fee}("");

        if (!success) revert Lottery__FundTransferFailed();

        _round.prize = _round.prize - fee;
        _round.status = RoundStatus.Claimable;

        rounds[currentRound] = _round;

        emit RoundClaimable(currentRound);

        currentRound += 1;
        rounds[currentRound] = _initRound(currentRound);
        emit NewRoundStarted(currentRound);
    }

    function claimPrize(uint256 roundId, uint256 ticketId) external {
        Round memory _round = rounds[roundId];

        if (_round.status != RoundStatus.Claimable) {
            revert Lottery__IncorrectRoundStatus(_round.status, RoundStatus.Claimable, "");
        }

        Ticket memory ticket = roundTickets[roundId][ticketId];

        if (!ticket.resgistered) revert Lottery__TicketNotRegistered();
        if (ticket.claimed) revert Lottery__TicketHasBeenClaimed();
        if (ticket.player != msg.sender) revert Lottery__TicketNotOwner();

        roundTickets[roundId][ticketId].claimed = true;

        uint256 prizeAmount = _round.prize / _round.totalWinningTickets;

        (bool paid,) = payable(msg.sender).call{value: prizeAmount}("");

        if (!paid) revert Lottery__FundTransferFailed();

        emit PrizeClaimed(roundId, msg.sender, ticketId, prizeAmount);
    }

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    ) internal override {
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
        _currentRound.status = RoundStatus.RegisterWinningTickets;
        _currentRound.registerWinningTicketTime = block.timestamp + registerWinningTicketTimeframe;
        rounds[currentRound] = _currentRound;
    }

    function getPlayerTickets(address player, uint256 roundId)
        external
        view
        returns (uint256[] memory, Ticket[] memory)
    {
        return _getPlayerTickets(player, roundId);
    }

    function getPlayerTickets(uint256 roundId) external view returns (uint256[] memory, Ticket[] memory) {
        return _getPlayerTickets(msg.sender, roundId);
    }

    function _getPlayerTickets(address player, uint256 roundId)
        private
        view
        returns (uint256[] memory, Ticket[] memory)
    {
        uint256[] memory ticketIds = playerTickets[roundId][player];
        uint256 totalTickets = ticketIds.length;
        Ticket[] memory tickets = new Ticket[](totalTickets);

        for (uint256 index = 0; index < totalTickets;) {
            uint256 ticketId = ticketIds[index];
            tickets[index] = roundTickets[roundId][ticketId];

            unchecked {
                index++;
            }
        }

        return (ticketIds, tickets);
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

    function getPlayerRounds(address player) external view returns (uint256[] memory) {
        return playerRounds[player];
    }

    function _getRoundData(uint256 round) private view returns (Round memory) {
        return rounds[round];
    }

    function _validateRoundData(uint256 totalTickets, uint256 amountPaid) private view {
        if (totalTickets * ticketPrice != amountPaid) {
            revert Lottery__InvalidTicketPaymentAmount();
        }

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

    function _processTicketCreation(uint8[6] calldata numbers, address player) private {
        uint256 ticketId = rounds[currentRound].totalTickets;
        Ticket memory newTicket = Ticket({numbers: numbers, claimed: false, resgistered: false, player: player});
        roundTickets[currentRound][ticketId] = newTicket;
        playerTickets[currentRound][player].push(ticketId);

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
            registerWinningTicketTime: 0,
            prize: 0,
            totalTickets: 0,
            totalWinningTickets: 0,
            winningNumbers: winningNumbers,
            status: RoundStatus.Active
        });
    }

    function _getLotteryNumbers() internal returns (uint256 requestId) {
        rounds[currentRound].status = RoundStatus.Drawing;

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

    function _updatePlayerRounds(address player) private {
        uint256[] memory roundIds = playerRounds[player];

        if (roundIds.length != 0 && roundIds[roundIds.length - 1] != currentRound) {
            playerRounds[player].push(currentRound);
        }
    }

    function _validateWinningTicket(uint8[6] memory roundNumbers, uint8[6] memory ticketNumbers) private pure {
        for (uint256 i = 0; i < TOTAL_TICKET_NUMBERS;) {
            uint256 found = 0;

            for (uint256 j = 0; j < TOTAL_TICKET_NUMBERS;) {
                if (ticketNumbers[i] == roundNumbers[j]) {
                    found = 1;
                    break;
                }

                unchecked {
                    j++;
                }
            }

            if (found == 0) {
                revert Lottery__TicketNumberNotTheSameAsRoundNumber();
            }

            unchecked {
                i++;
            }
        }
    }

    function _extendRound() private {
        rounds[currentRound].endTime += extendRoundBy;
        emit RoundExtended(currentRound);
    }
}
