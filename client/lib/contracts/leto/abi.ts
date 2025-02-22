import { parseAbi } from 'viem';

export const letoAbi = parseAbi([
	// ============ structs ============
	'struct Round { uint256 id; uint256 startTime; uint256 endTime; uint256 registerWinningTicketTime; uint256 prize; uint256 totalTickets; uint256 totalWinningTickets; uint8[6] winningNumbers; uint8 status; }',
	'struct Ticket { uint8[6] numbers; bool claimed; bool resgistered; address player; }',

	// ============ functions ============
	'function ticketPrice() external view returns (uint256)',
	'function currentRound() external view returns (uint256)',
	'function getRoundData(uint256 round) external view returns (Round memory)',
	'function getRoundData() external view returns (Round memory)',
	'function buyTicket(uint8[6] calldata numbers) external payable',
	'function buyTickets(uint8[6][] calldata ticketsNumbers) external payable',
	'function getPlayerTickets() external view returns (uint256[] memory, Ticket[] memory)',
	'function getPlayerTickets(uint256 roundId) external view returns (uint256[] memory, Ticket[] memory)',
	'function registerWinningTicket(uint256 ticketId) external',
	'function registerWinningTicket(uint256 roundId, uint256 ticketId) public',
	'function claimPrize(uint256 roundId, uint256 ticketId) external',

	// ============ events ============
	'event TicketPurchased(address indexed player, uint256 indexed roundId, uint8[6] numbers)',

	// ============ errors ============
	'error Lottery__RoundNotActive()',
	'error Lottery__InvalidTicketPaymentAmount()',
	'error Lottery__InvalidTicketNumbers(string reason)',
	'error Lottery__InvalidRound()',
	'error Lottery__IncorrectRoundStatus(uint8 current, uint8 expected, string message)',
	'error Lottery__TicketHasBeenRegistered()',
	'error Lottery__TicketHasBeenClaimed()',
	'error Lottery__TicketNotOwner()',
	'error Lottery__TicketNumberNotTheSameAsRoundNumber()',
	'error Lottery__TicketNotRegistered()',
	'error Lottery__FundTransferFailed()',
]);
