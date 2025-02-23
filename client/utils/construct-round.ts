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
	[RoundStatus.Active]: {
		label: 'Active',
		info: 'Tickets are currently on sale. Buy your tickets for a chance to win the prize pool.',
		color: 'text-green-700 bg-green-50 border-green-200',
	},
	[RoundStatus.Drawing]: {
		label: 'Drawing',
		info: 'Ticket sales are closed. The smart contract is generating verifiably random winning numbers using Chainlink VRF.',
		color: 'text-yellow-700 bg-yellow-50 border-yellow-200',
	},
	[RoundStatus.RegisterWinningTickets]: {
		label: 'Register winning tickets',
		info: 'Winning numbers have been drawn. If you have a winning ticket, you must register it within the timeframe to be eligible for claiming prizes.',
		color: 'text-blue-700 bg-blue-50 border-blue-200',
	},
	[RoundStatus.Claimable]: {
		label: 'Claimable',
		info: 'The round is complete. Registered winners can now claim their prizes from the smart contract.',
		color: 'text-purple-700 bg-purple-50 border-purple-200',
	},
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
