import { parseAbi } from 'viem';

export const letoAbi = parseAbi([
  // ============ structs ============

  // ============ functions ============
  'function ticketPrice() external view returns (uint256)',

  // ============ events ============

  // ============ errors ============
]);
