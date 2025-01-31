/* eslint-disable no-unused-vars */
export enum RoundStatus {
  Active,
  Drawing,
  RegisterWinningTickets,
  Claimable,
}

export const statuses = {
  [RoundStatus.Active]: 'Active',
  [RoundStatus.Drawing]: 'Drawing',
  [RoundStatus.RegisterWinningTickets]: 'RegisterWinningTickets',
  [RoundStatus.Claimable]: 'Claimable',
};

export interface IRound {
  id: number;
  startTime: number;
  endTime: number;
  registerWinningTicketTime: number;
  prize: number;
  totalTickets: number;
  totalWinningTickets: number;
  winningNumbers: [number, number, number, number, number, number];
  status: (typeof statuses)[RoundStatus];
}
