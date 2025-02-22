export type ILotteryNumber = readonly [
	number,
	number,
	number,
	number,
	number,
	number
];

export interface ITicket {
	numbers: ILotteryNumber;
	claimed: boolean;
	resgistered: boolean;
	player: `0x${string}`;
}
