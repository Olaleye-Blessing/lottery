import { formatEther } from 'viem';

export type TLotteryNumbers = readonly [
	number,
	number,
	number,
	number,
	number,
	number
];

export type IContractRound = {
	id: bigint;
	startTime: bigint;
	endTime: bigint;
	prize: bigint;
	totalTickets: bigint;
	winningNumbers: TLotteryNumbers;
};

export interface IRound {
	id: number;
	startTime: number;
	endTime: number;
	prize: number;
	totalTickets: number;
	winningNumbers: TLotteryNumbers;
}

export const constructRound = (_round: IContractRound): IRound => {
	return {
		id: +_round.id.toString(),
		startTime: Number(_round.startTime) * 1000,
		endTime: Number(_round.endTime) * 1000,
		prize: +formatEther(_round.prize),
		totalTickets: Number(_round.totalTickets),
		winningNumbers: _round.winningNumbers,
	};
};
