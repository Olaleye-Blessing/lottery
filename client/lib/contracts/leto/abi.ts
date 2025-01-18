import { parseAbi } from 'viem';

export const letoAbi = parseAbi([
	// ============ structs ============
	'struct Round { uint256 id; uint256 startTime; uint256 endTime; uint256 prize; uint256 totalTickets; uint8[6] winningNumbers; uint8 status }',

	// ============ functions ============
	'function ticketPrice() external view returns (uint256)',
	'function getRoundData() external view returns (Round memory)',
	'function buyTicket(uint8[6] calldata numbers) external payable',
	'function buyTickets(uint8[6][] calldata ticketsNumbers) external payable',

	// ============ events ============
	'event TicketPurchased(address indexed player, uint256 indexed roundId, uint8[6] numbers)',

	// ============ errors ============
	'error Lottery__RoundNotActive()',
	'error Lottery__InvalidTicketPaymentAmount()',
	'error Lottery__InvalidTicketNumbers(string reason)',
]);
