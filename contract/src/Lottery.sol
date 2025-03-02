// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/v0.8/automation/AutomationCompatible.sol";

/// @title Lottery Contract
/// @notice This contract implements a decentralized lottery system using Chainlink VRF for random number generation
/// @dev Inherits from VRFConsumerBaseV2Plus for random number generation and AutomationCompatibleInterface for automated operations
contract Lottery is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    /// @title RoundStatus Enum
    /// @notice This enum represents the various statuses a lottery round can have
    enum RoundStatus {
        /// @notice The round is currently open for ticket purchases
        /// @dev Players can buy tickets during this status
        Active,
        /// @notice The round has ended and the contract is generating the lucky numbers
        /// @dev VRF request is pending during this status
        Drawing,
        /// @notice Period where winning tickets need to register for payout
        /// @dev Winners must register within the specified timeframe
        RegisterWinningTickets,
        /// @notice Winning tickets can claim their prizes
        /// @dev Final state of a round where prizes can be distributed
        Claimable
    }

    /// @notice Thrown when attempting to interact with an inactive round
    error Lottery__RoundNotActive();
    /// @notice Thrown when the payment amount doesn't match the ticket price
    error Lottery__InvalidTicketPaymentAmount();
    /// @notice Thrown when ticket numbers are invalid
    /// @param reason Detailed explanation of why the numbers are invalid
    error Lottery__InvalidTicketNumbers(string reason);
    /// @notice Thrown when attempting to access an invalid round
    error Lottery__InvalidRound();
    /// @notice Thrown when operation is attempted in wrong round status
    error Lottery__IncorrectRoundStatus(RoundStatus current, RoundStatus expected, string message);
    /// @notice Thrown when attempting to claim an already claimed ticket
    error Lottery__TicketHasBeenClaimed();
    /// @notice Thrown when attempting to register an already registered ticket
    error Lottery__TicketHasBeenRegistered();
    /// @notice Thrown when attempting to claim an unregistered ticket
    error Lottery__TicketNotRegistered();
    /// @notice Thrown when non-owner attempts to interact with a ticket
    error Lottery__TicketNotOwner();
    /// @notice Thrown when prize transfer fails
    error Lottery__FundTransferFailed();
    /// @notice Thrown when ticket numbers don't match winning numbers
    error Lottery__TicketNumberNotTheSameAsRoundNumber();
    error Lottery__InvalidPagination();
    /// @dev Thrown when another contract/account calls chainlink upkeep
    error Lottery__UnknownForwarder();

    /// @notice Emitted when a ticket is purchased
    /// @param player Address of the ticket buyer
    /// @param roundId ID of the current lottery round
    /// @param numbers Array of chosen numbers
    event TicketPurchased(address indexed player, uint256 indexed roundId, uint8[6] numbers);
    /// @notice Emitted when a round is extended
    /// @param round ID of the extended round
    event RoundExtended(uint256 indexed round);
    /// @notice Emitted when a round's winning numbers have been requested from VRF
    /// @dev This event is triggered during performUpkeep when transitioning to Drawing status
    /// @param round The ID of the round for which numbers are being drawn
    event RoundDrawn(uint256 indexed round);
    /// @notice Emitted when a new round starts
    /// @param round ID of the new round
    event NewRoundStarted(uint256 indexed round);
    /// @notice Emitted when a round becomes claimable
    /// @param round ID of the claimable round
    event RoundClaimable(uint256 indexed round);
    /// @notice Emitted when a prize is claimed
    /// @param roundId ID of the round
    /// @param player Address of the winner
    /// @param ticketId ID of the winning ticket
    /// @param amount Prize amount claimed
    event PrizeClaimed(uint256 indexed roundId, address indexed player, uint256 indexed ticketId, uint256 amount);

    /// @notice Struct containing all information about a lottery round
    /// @dev Used to track the state and progress of each lottery round
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

    /// @notice Struct containing information about a lottery ticket
    /// @dev Tracks the state and ownership of individual tickets
    struct Ticket {
        uint8[6] numbers;
        bool claimed;
        bool resgistered;
        address player;
    }

    // === Constants and State Variables ===
    uint256 public constant TOTAL_TICKET_NUMBERS = 6;
    uint8 public constant MAX_NUMBER = 99;
    uint256 private constant ZEROS_PRECISION = 1e18;
    uint256 private constant EXTEND_ROUND_BY = 3 days;
    uint256 private constant PERFORM_UPKEEP_ROUND_DRAWING = 1;
    uint256 private constant PERFORM_UPKEEP_ROUND_EXTEND = 2;
    uint256 private constant PERFORM_UPKEEP_ROUND_CLAIMABLE = 3;
    uint256[] private s_roundHistory;
    uint256 public currentRound = 0;
    uint256 public lotteryFee = 1e16; // 1%
    uint256 public ticketPrice = 0.002 ether;
    uint256 public roundDuration = 7 days;
    uint256 private s_registerWinningTicketTimeframe = 3 hours;
    uint256 private immutable i_minimumRoundTicket;

    // === Chainlink VRF Configuration ===
    /// @dev Depends on the number of requested values that you want sent to the fulfillRandomWords() function.
    /// @dev Storing each word costs about 20,000 gas, so 100,000 is a safe default for this example contract.
    uint32 private constant CALLBACK_GAS_LIMIT = 2_000_000;
    uint16 private constant VRF_RANDOM_REQUEST_CONFIRMATIONS = 3;
    uint256 private immutable i_vrfSubId;
    bytes32 private immutable i_keyHash;

    // === Chainlink automation ===
    address private s_automationForwarder;

    mapping(uint256 roundId => Round) public rounds;
    mapping(uint256 roundId => mapping(uint256 ticketId => Ticket ticket)) private s_roundTickets;
    mapping(uint256 roundId => mapping(address player => uint256[] ticketIds)) private s_playerTickets;
    mapping(address player => uint256[] roundIds) public playerRounds;
    mapping(uint256 roundId => uint256 vrfRequestId) private s_roundRequests;

    /// @notice Constructor initializes the lottery contract
    /// @param _minimumRoundTicket Minimum number of tickets required to draw a round
    /// @param _vrfCoordinator Address of the Chainlink VRF coordinator
    /// @param _vrfSubId Subscription ID for Chainlink VRF
    /// @param _keyHash Key hash for VRF request
    constructor(uint256 _minimumRoundTicket, address _vrfCoordinator, uint256 _vrfSubId, bytes32 _keyHash)
        VRFConsumerBaseV2Plus(_vrfCoordinator)
    {
        i_minimumRoundTicket = _minimumRoundTicket;
        i_vrfSubId = _vrfSubId;
        i_keyHash = _keyHash;
        rounds[0] = _initRound(0);
        emit NewRoundStarted(0);
    }

    /// @notice Modifier to validate round ID
    /// @param round Round ID to validate
    modifier validRound(uint256 round) {
        if (round > currentRound) revert Lottery__InvalidRound();
        _;
    }

    /// @notice Validates pagination parameters
    /// @param page The page number
    /// @param perPage The number of items per page
    modifier validPagination(uint256 page, uint256 perPage) {
        if (page >= 0 && perPage > 0) {
            _;
        } else {
            revert Lottery__InvalidPagination();
        }
    }

    /// @notice Purchase a single lottery ticket
    /// @param numbers Array of 6 numbers chosen for the ticket
    function buyTicket(uint8[6] calldata numbers) external payable {
        _validateRoundData(1, msg.value);
        _validateTicketNumbers(numbers);
        _processTicketCreation(numbers, msg.sender);
        _updatePlayerRounds(msg.sender);
    }

    /// @notice Purchase multiple lottery tickets in one transaction
    /// @param ticketsNumbers Array of number arrays for multiple tickets
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

    /// @notice Check if the contract needs maintenance
    /// @dev Called by Chainlink Automation to determine if performUpkeep should be called
    /// @param checkData Additional data for upkeep check (unused)
    /// @return upkeepNeeded Boolean indicating if upkeep is needed
    /// @return performData Encoded data indicating which action to perform
    function checkUpkeep(bytes memory checkData)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        Round memory _currentRound = rounds[currentRound];

        if (_currentRound.status == RoundStatus.Drawing) return (false, "");

        bool drawRound = _currentRound.status == RoundStatus.Active && block.timestamp > _currentRound.endTime;
        if (drawRound) {
            if (_currentRound.totalTickets < i_minimumRoundTicket) {
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

    /// @notice Perform contract maintenance
    /// @dev Called by Chainlink Automation when checkUpkeep returns true
    /// @param performData Encoded data indicating which action to perform
    function performUpkeep(bytes calldata performData) external override {
        if (msg.sender != s_automationForwarder) revert Lottery__UnknownForwarder();

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

    /// @notice Register a winning ticket for prize claim
    /// @param roundId ID of the lottery round
    /// @param ticketId ID of the winning ticket
    function registerWinningTicket(uint256 roundId, uint256 ticketId) external {
        Round memory _round = rounds[roundId];

        if (_round.status != RoundStatus.RegisterWinningTickets) {
            revert Lottery__IncorrectRoundStatus(_round.status, RoundStatus.RegisterWinningTickets, "");
        }

        Ticket memory ticket = s_roundTickets[roundId][ticketId];

        if (ticket.resgistered) revert Lottery__TicketHasBeenRegistered();
        if (ticket.claimed) revert Lottery__TicketHasBeenClaimed();
        if (ticket.player != msg.sender) revert Lottery__TicketNotOwner();

        uint8[6] memory roundNumbers = _round.winningNumbers;
        uint8[6] memory ticketNumbers = ticket.numbers;

        _validateWinningTicket(roundNumbers, ticketNumbers);

        ticket.resgistered = true;
        s_roundTickets[roundId][ticketId] = ticket;
        _round.totalWinningTickets += 1;

        rounds[roundId] = _round;
    }

    /// @notice Claim prize for a winning ticket
    /// @param roundId ID of the lottery round
    /// @param ticketId ID of the winning ticket
    function claimPrize(uint256 roundId, uint256 ticketId) external {
        Round memory _round = rounds[roundId];

        if (_round.status != RoundStatus.Claimable) {
            revert Lottery__IncorrectRoundStatus(_round.status, RoundStatus.Claimable, "");
        }

        Ticket memory ticket = s_roundTickets[roundId][ticketId];

        if (!ticket.resgistered) revert Lottery__TicketNotRegistered();
        if (ticket.claimed) revert Lottery__TicketHasBeenClaimed();
        if (ticket.player != msg.sender) revert Lottery__TicketNotOwner();

        s_roundTickets[roundId][ticketId].claimed = true;

        uint256 prizeAmount = _round.prize / _round.totalWinningTickets;

        (bool paid,) = payable(msg.sender).call{value: prizeAmount}("");
        if (!paid) revert Lottery__FundTransferFailed();

        emit PrizeClaimed(roundId, msg.sender, ticketId, prizeAmount);
    }

    /// @notice Callback function for VRF to provide random numbers
    /// @dev Implements VRFConsumerBaseV2Plus
    /// @param requestId ID of the VRF request
    /// @param randomWords Array of random numbers provided by VRF
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        if (s_roundRequests[currentRound] != requestId) return; // You can't revert per chainlink doc

        uint8[6] memory winningNumbers;
        for (uint8 index = 0; index < TOTAL_TICKET_NUMBERS;) {
            winningNumbers[index] = uint8(randomWords[index] % 99) + 1;
            unchecked {
                index++;
            }
        }

        Round memory _currentRound = rounds[currentRound];
        _currentRound.winningNumbers = winningNumbers;
        _currentRound.status = RoundStatus.RegisterWinningTickets;
        _currentRound.registerWinningTicketTime = block.timestamp + s_registerWinningTicketTimeframe;
        rounds[currentRound] = _currentRound;

        emit RoundDrawn(currentRound);
    }

    /// @notice Set the address that `performUpkeep` is called from
    /// @dev Only callable by the owner
    /// @param forwarder the address to set
    function setForwarderAddress(address forwarder) external onlyOwner {
        s_automationForwarder = forwarder;
    }

    /// @notice Make round prizes claimable and start new round
    /// @dev Calculates final prize pool after fees and transitions round status
    function _makeRoundPrizeClaimable() private {
        Round memory _round = rounds[currentRound];

        if (_round.totalWinningTickets > 0) {
            uint256 fee = (_round.prize * lotteryFee) / ZEROS_PRECISION;
            (bool success,) = payable(owner()).call{value: fee}("");

            if (!success) revert Lottery__FundTransferFailed();

            _round.prize = _round.prize - fee;
        }

        _round.status = RoundStatus.Claimable;

        rounds[currentRound] = _round;
        s_roundHistory.push(currentRound);

        emit RoundClaimable(currentRound);

        currentRound += 1;
        rounds[currentRound] = _initRound(currentRound);
        emit NewRoundStarted(currentRound);

        // Move prize pool of previous round to current round
        if (_round.totalWinningTickets == 0) {
            rounds[currentRound].prize = rounds[currentRound - 1].prize;
        }
    }

    /// @notice Get tickets owned by a specific player in the current round
    /// @return Array of ticket IDs and array of ticket details
    function getPlayerTickets() external view returns (uint256[] memory, Ticket[] memory) {
        return _getPlayerTickets(msg.sender, currentRound);
    }

    /// @notice Get tickets owned by a specific player in a round
    /// @param player Address of the player
    /// @param roundId ID of the round
    /// @return Array of ticket IDs and array of ticket details
    function getPlayerTickets(address player, uint256 roundId)
        external
        view
        returns (uint256[] memory, Ticket[] memory)
    {
        return _getPlayerTickets(player, roundId);
    }

    /// @notice Get tickets owned by the caller in a round
    /// @param roundId ID of the round
    /// @return Array of ticket IDs and array of ticket details
    function getPlayerTickets(uint256 roundId) external view returns (uint256[] memory, Ticket[] memory) {
        return _getPlayerTickets(msg.sender, roundId);
    }

    /// @notice Internal function to get player tickets
    /// @param player Address of the player
    /// @param roundId ID of the round
    /// @return Array of ticket IDs and array of ticket details
    function _getPlayerTickets(address player, uint256 roundId)
        private
        view
        returns (uint256[] memory, Ticket[] memory)
    {
        uint256[] memory ticketIds = s_playerTickets[roundId][player];
        uint256 totalTickets = ticketIds.length;
        Ticket[] memory tickets = new Ticket[](totalTickets);

        for (uint256 index = 0; index < totalTickets;) {
            uint256 ticketId = ticketIds[index];
            tickets[index] = s_roundTickets[roundId][ticketId];

            unchecked {
                index++;
            }
        }

        return (ticketIds, tickets);
    }

    /// @notice Retrieves a paginated list of all previous rounds
    /// @param page The page number to retrieve
    /// @param perPage The number of rounds per page
    /// @return An array of Round structs and the total number of rounds
    function getRoundHistoryData(uint256 page, uint256 perPage)
        external
        view
        validPagination(page, perPage)
        returns (Round[] memory, uint256 totalRounds)
    {
        uint256 start = page * perPage;
        uint256 end = start + perPage;
        totalRounds = s_roundHistory.length;

        if (end > totalRounds) end = totalRounds;

        uint256 totalRoundsToReturn = end - start;

        Round[] memory _rounds = new Round[](totalRoundsToReturn);

        for (uint256 index = 0; index < totalRoundsToReturn;) {
            _rounds[index] = rounds[s_roundHistory[start + index]];

            unchecked {
                index++;
            }
        }

        return (_rounds, totalRounds);
    }

    /// @notice Get data for a specific round
    /// @param round ID of the round
    /// @return Round data struct
    function getRoundData(uint256 round) external view validRound(round) returns (Round memory) {
        return _getRoundData(round);
    }

    /// @notice Get data for the current round
    /// @return Round data struct
    function getRoundData() external view returns (Round memory) {
        return _getRoundData(currentRound);
    }

    /// @notice Get VRF request ID for the current round
    /// @return Request ID
    function getRoundRequestId() external view onlyOwner returns (uint256) {
        return getRoundRequestId(currentRound);
    }

    /// @notice Get VRF request ID for a specific round
    /// @param round ID of the round
    /// @return Request ID
    function getRoundRequestId(uint256 round) public view onlyOwner returns (uint256) {
        return s_roundRequests[round];
    }

    /// @notice Get all rounds a player has participated in
    /// @param player Address of the player
    /// @return Array of round IDs
    function getPlayerRounds(address player) external view returns (uint256[] memory) {
        return playerRounds[player];
    }

    /// @notice Internal function to get round data
    /// @param round ID of the round
    /// @return Round data struct
    function _getRoundData(uint256 round) private view returns (Round memory) {
        return rounds[round];
    }

    /// @notice Validate round data and payment
    /// @param totalTickets Number of tickets being purchased
    /// @param amountPaid Amount of ETH sent with transaction
    function _validateRoundData(uint256 totalTickets, uint256 amountPaid) private view {
        if (totalTickets * ticketPrice != amountPaid) {
            revert Lottery__InvalidTicketPaymentAmount();
        }

        Round memory _currentRound = rounds[currentRound];
        if (
            !(
                _currentRound.startTime <= block.timestamp && _currentRound.endTime >= block.timestamp
                    && _currentRound.status == RoundStatus.Active
            )
        ) {
            revert Lottery__RoundNotActive();
        }
    }

    /// @notice Process ticket creation
    /// @param numbers Array of chosen numbers
    /// @param player Address of the ticket buyer
    function _processTicketCreation(uint8[6] calldata numbers, address player) private {
        uint256 ticketId = rounds[currentRound].totalTickets;
        Ticket memory newTicket = Ticket({numbers: numbers, claimed: false, resgistered: false, player: player});
        s_roundTickets[currentRound][ticketId] = newTicket;
        s_playerTickets[currentRound][player].push(ticketId);

        rounds[currentRound].prize += ticketPrice;
        rounds[currentRound].totalTickets += 1;

        emit TicketPurchased(msg.sender, currentRound, numbers);
    }

    /// @notice Validate ticket numbers
    /// @param numbers Array of chosen numbers
    /// @dev Checks for duplicates and valid range
    function _validateTicketNumbers(uint8[6] calldata numbers) private pure {
        if (numbers.length != TOTAL_TICKET_NUMBERS) {
            revert Lottery__InvalidTicketNumbers("Provide a total of 6 numbers");
        }

        uint8 startIndex = 0;
        for (startIndex; startIndex < TOTAL_TICKET_NUMBERS;) {
            if (numbers[startIndex] < 1 || numbers[startIndex] > MAX_NUMBER) {
                revert Lottery__InvalidTicketNumbers("Provide number between 1 and 99, inclusive");
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

    /// @notice Initialize a new round
    /// @param round ID of the new round
    /// @return Round struct for the new round
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

    /// @notice Request random numbers from Chainlink VRF
    /// @return requestId VRF request ID
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

        s_roundRequests[currentRound] = requestId;
    }

    /// @notice Update player's round participation history
    /// @param player Address of the player
    function _updatePlayerRounds(address player) private {
        uint256[] memory roundIds = playerRounds[player];

        if (roundIds.length != 0 && roundIds[roundIds.length - 1] != currentRound) {
            playerRounds[player].push(currentRound);
        }
    }

    /// @notice Validate if a ticket matches the winning numbers
    /// @param roundNumbers Winning numbers for the round
    /// @param ticketNumbers Numbers on the ticket
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

    /// @notice Extend the current round's duration
    /// @dev Called when minimum ticket threshold isn't met
    function _extendRound() private {
        rounds[currentRound].endTime += EXTEND_ROUND_BY;
        emit RoundExtended(currentRound);
    }
}
