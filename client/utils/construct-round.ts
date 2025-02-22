import { formatEther } from 'viem';

export type TLotteryNumbers = readonly [
	number,
	number,
	number,
	number,
	number,
	number
];

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

export type IContractRound = {
	id: bigint;
	startTime: bigint;
	endTime: bigint;
	prize: bigint;
	totalTickets: bigint;
	winningNumbers: TLotteryNumbers;
	registerWinningTicketTime: bigint;
	totalWinningTickets: bigint;
	status: RoundStatus;
};

export interface IRound {
	id: number;
	startTime: number;
	endTime: number;
	prize: number;
	totalTickets: number;
	winningNumbers: TLotteryNumbers;
	registerWinningTicketTime: number;
	totalWinningTickets: number;
	status: RoundStatus;
}

export const constructRound = (_round: IContractRound): IRound => {
	return {
		id: +_round.id.toString(),
		startTime: Number(_round.startTime) * 1000,
		endTime: Number(_round.endTime) * 1000,
		prize: +formatEther(_round.prize),
		totalTickets: Number(_round.totalTickets),
		winningNumbers: _round.winningNumbers,
		registerWinningTicketTime:
			Number(_round.registerWinningTicketTime) * 1000,
		totalWinningTickets: Number(_round.totalWinningTickets),
		status: _round.status as RoundStatus,
	};
};
