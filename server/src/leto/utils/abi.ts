import { parseAbi } from 'viem';

export const roundClaimableEvent =
  'event RoundClaimable(uint256 indexed round)';

export const letoAbi = parseAbi([
  // ============ structs ============
  'struct Round { uint256 id; uint256 startTime; uint256 endTime; uint256 registerWinningTicketTime; uint256 prize; uint256 totalTickets; uint256 totalWinningTickets; uint8[6] winningNumbers; uint8 status; }',

  // ============ functions ============
  'function ticketPrice() external view returns (uint256)',
  'function getRoundData(uint256 round) external view returns (Round memory)',
  'function getRoundData() external view returns (Round memory)',

  // ============ events ============
  roundClaimableEvent,

  // ============ errors ============
]);
